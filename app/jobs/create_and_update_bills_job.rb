# frozen_string_literal: true

class CreateAndUpdateBillsJob < ApplicationJob # rubocop:disable Metrics/ClassLength
  queue_as :default

  SESSION_CUTOFF_YEAR = 2023
  BILL_CUTOFF_DATE = DateTime.new(2024, 8, 1)

  def perform
    legiscan_api = LegiscanApi.new
    check_for_new_sessions(legiscan_api)
    create_and_update_bills(legiscan_api)
  end

  def check_for_new_sessions(legiscan_api)
    # Extract session creation to method and add error handling
    legiscan_api.get_session_list.each do |session|
      next if session['year_start'] < SESSION_CUTOFF_YEAR

      create_session(session) if Session.where(legiscan_session_id: session['session_id']).empty?
    end
  end

  def create_session(legiscan_session)
    Session.create!(legiscan_session_id: legiscan_session['session_id'],
                    start_date: DateTime.new(legiscan_session['year_start'], 1, 1, 0, 0, 0),
                    end_date: DateTime.new(legiscan_session['year_end'], 12, 31, 23, 59, 59))

    Rails.logger.info "Created session with legiscan_session_id: #{legiscan_session['session_id']}"
  rescue StandardError => e
    error_log_message = 'Error creating session with legiscan_session_id: ' \
                        "#{legiscan_session['session_id']}, Error: #{e.message}"
    Rails.logger.error(error_log_message)
    Sentry.capture_message(error_log_message)
  end

  def create_and_update_bills(legiscan_api)
    Session.where('end_date > ?', Time.now).each do |session|
      legiscan_api.get_bill_list(session.legiscan_session_id).each do |legiscan_response_bill|
        next if legiscan_response_bill['status_date'] < BILL_CUTOFF_DATE

        legiscan_bill_id = legiscan_response_bill['bill_id']
        existing_database_bill = Bill.where(legiscan_bill_id:).first

        if existing_database_bill && bill_needs_updated?(legiscan_response_bill, existing_database_bill)
          update_existing_bill_status_and_summary(legiscan_api, legiscan_response_bill, existing_database_bill)
        elsif !existing_database_bill
          create_new_bill(legiscan_api, legiscan_response_bill, session.id)
        end
      end
    end
  end

  def bill_needs_updated?(legiscan_response_bill, existing_database_bill)
    existing_database_bill.status_before_type_cast != legiscan_response_bill['status'] ||
      existing_database_bill.summary.nil?
  end

  def update_existing_bill_status_and_summary(legiscan_api, legiscan_response_bill, existing_database_bill)
    legiscan_bill_id = legiscan_response_bill['bill_id']
    legiscan_bill_detail = legiscan_api.get_bill(legiscan_bill_id)
    new_status_integer = legiscan_response_bill['status'].to_i
    new_status_string = Bill.statuses.key(new_status_integer)

    legiscan_bill_detail['texts'].each do |text|
      next unless text['type'].casecmp?(new_status_string)

      doc_id = text['doc_id']
      full_text = legiscan_api.get_bill_text(doc_id)
      summary = OpenaiApi.new.legal_text_summary(full_text)
      status_last_updated = DateTime.parse(legiscan_response_bill['status_date'])
      existing_database_bill.update!(summary:, legiscan_doc_id: doc_id,
                                     status: new_status_integer, status_last_updated:)

      Rails.logger.info "Updated bill with Title: #{existing_database_bill.title}, Id: #{existing_database_bill.id}"
      break
    end
  rescue StandardError => e
    error_log_message = "Error updating bill with Title: #{existing_database_bill.title}, " \
                        "Id: #{existing_database_bill.id}, Error: #{e.message}"
    Rails.logger.error(error_log_message)
    Sentry.capture_message(error_log_message)
  end

  def create_new_bill(legiscan_api, legiscan_response_bill, session_id)
    legiscan_bill_id = legiscan_response_bill['bill_id']
    title = legiscan_response_bill['title']
    legiscan_bill_detail = legiscan_api.get_bill(legiscan_bill_id)
    bill_status_integer = legiscan_response_bill['status'].to_i
    bill_status_string = Bill.statuses.key(bill_status_integer)
    status_last_updated = DateTime.parse(legiscan_response_bill['status_date'])
    text_exists = false
    database_bill = nil

    legiscan_bill_detail['texts'].each do |text|
      next unless text['type'].casecmp?(bill_status_string)

      doc_id = text['doc_id']
      full_text = legiscan_api.get_bill_text(doc_id)
      summary = OpenaiApi.new.legal_text_summary(full_text)
      database_bill = Bill.create!(status: bill_status_integer,
                                   status_last_updated:,
                                   title:,
                                   summary:,
                                   legiscan_doc_id: doc_id,
                                   legiscan_bill_id:,
                                   session_id:)
      text_exists = true
      break
    end

    unless text_exists
      database_bill = Bill.create!(status: bill_status_integer,
                                   status_last_updated:,
                                   title:,
                                   legiscan_bill_id:,
                                   session_id:)
    end

    Rails.logger.info "Created bill with Title: #{database_bill.title}, id: #{database_bill.id}"
  rescue StandardError => e
    error_log_message = "Error creating bill with Title: #{title}, " \
                        "Legiscan Bill Id: #{legiscan_bill_id}, Error: #{e.message}"
    Rails.logger.error(error_log_message)
    Sentry.capture_message(error_log_message)
  end
end
