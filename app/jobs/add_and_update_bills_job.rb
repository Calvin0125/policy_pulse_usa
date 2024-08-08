class AddAndUpdateBills
  include Sidekiq::Worker

  SESSION_CUTOFF_YEAR = 2023
  BILL_CUTOFF_DATE = DateTime.new(2024, 7, 25)

  def perform
    legiscan_api = LegiscanApi.new

    legiscan_api.get_session_list.each do |session|
      if session['year_start'] < SESSION_CUTOFF_YEAR
        next
      end

      if Session.where(legiscan_session_id: session['session_id']).empty?
        Session.create(legiscan_session_id: session['session_id'],
                       start_date: DateTime.new(session['year_start'], 1, 1, 0, 0, 0),
                       end_date: DateTime.new(session['year_end'], 12, 31, 23, 59, 59))
      end

      Session.where('end_date > ?', Time.now).each do |session|
        legiscan_api.get_bill_list(session.legiscan_session_id).each do |bill|
          if bill["status_date"] < BILL_CUTOFF_DATE
            next
          end

          bill_id = bill["bill_id"]
          existing_bill = Bill.where(legiscan_bill_id: bill_id).first

          if existing_bill && bill["status"] != existing_bill.status
            # Change to logging
            puts "===============**********==============="
            puts "Updating bill #{existing_bill.title}"
            new_status_integer = bill["status"].to_i
            new_status_string = Bill.statuses.key(new_status_integer)
            bill_detail = LegiscanApi.get_bill(bill_id)
            bill_detail['texts'].each do |text|
              if text['type'] == new_status_string
                doc_id = text['doc_id']
                full_text = LegiscanApi.new.get_bill_text(doc_id)
                summary = OpenaiApi.new.legal_text_summary(full_text)
                existing_bill.update!(summary: summary, legiscan_doc_id: doc_id)
                break
              end
            end
          elsif !existing_bill
            puts "===============**********==============="
            puts "Creating bill with legiscan bill id #{bill_id}"
            bill_detail = LegiscanApi.get_bill(bill_id)
            bill_status_integer = bill['status'].to_i
            bill_status_string = Bill.statuses.key(bill_status_integer)
            bill_detail['texts'].each do |text|
              if text['type'] == current_bill_status
                doc_id = text['doc_id']
                full_text = LegiscanApi.new.get_bill_text(doc_id)
                summary = OpenaiApi.new.legal_text_summary(full_text)
                status_last_updated = bill['status_date']
                Bill.create!(status: bill_status_integer,
                             status_last_updated: status_last_updated,
                             summary: summary,
                             legiscan_bill_id: bill_id,
                             legiscan_doc_id: doc_id,
                             session_id: session.id
                            )
                break
              end
            end
        end
      end
    end
  end
end