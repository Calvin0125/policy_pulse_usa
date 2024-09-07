# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateAndUpdateBillsJob, type: :job do
  let(:job) { described_class.new }
  let(:legiscan_api) { LegiscanApi.new }

  describe '#perform' do
    let(:legiscan_api) { instance_double('LegiscanApi') }
    let(:described_class_instance) { described_class.new }

    before do
      allow(described_class_instance).to receive(:check_for_new_sessions)
      allow(described_class_instance).to receive(:create_and_update_bills)
      allow(LegiscanApi).to receive(:new).and_return(legiscan_api)
    end

    it 'calls check_for_new_sessions with legiscan_api' do
      described_class_instance.perform_now

      expect(described_class_instance).to have_received(:check_for_new_sessions).with(legiscan_api)
      expect(described_class_instance).to have_received(:create_and_update_bills).with(legiscan_api)
    end
  end

  describe '#check_for_new_sessions' do
    let(:session_cutoff_year) { CreateAndUpdateBillsJob::SESSION_CUTOFF_YEAR }
    let(:mock_session_response) do
      [
        { 'session_id' => 12_345, 'year_start' => session_cutoff_year - 2, 'year_end' => session_cutoff_year - 1 },
        { 'session_id' => 67_890, 'year_start' => session_cutoff_year, 'year_end' => session_cutoff_year + 1 }
      ]
    end

    before do
      allow(legiscan_api).to receive(:get_session_list).and_return(mock_session_response)
    end

    it 'creates new sessions if they are after the cutoff year' do
      expected_log_message = 'Created session with legiscan_session_id: ' \
                             "#{mock_session_response[1]['session_id']}"
      expect(Rails.logger).to receive(:info).with(expected_log_message)

      job.check_for_new_sessions(legiscan_api)

      expect(Session.count).to eq(1)

      session = Session.first
      expect(session.legiscan_session_id).to eq(67_890)
      expect(session.start_date).to eq(DateTime.new(session_cutoff_year, 1, 1, 0, 0, 0))
      expect(session.end_date).to eq(DateTime.new(session_cutoff_year + 1, 12, 31, 23, 59, 59))
    end

    it 'catches and logs the error message if an error is raised' do
      error_message = 'An error has occurred'
      allow(Session).to receive(:create!).and_raise(StandardError.new(error_message))

      expected_log_message = 'Error creating session with legiscan_session_id: ' \
                             "#{mock_session_response[1]['session_id']}, Error: #{error_message}"
      expect(Rails.logger).to receive(:error).with(expected_log_message)
      expect(Sentry).to receive(:capture_message).with(expected_log_message)

      job.check_for_new_sessions(legiscan_api)
    end
  end

  describe '#create_and_update_bills' do
    let(:session1) { create(:session) }
    let(:session2) { create(:session) }

    let(:mock_bill_list_response1) do
      [
        { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 1, 'status_date' => '2024-08-01' },
        { 'bill_id' => 456, 'title' => 'Bill 2', 'status' => 3, 'status_date' => '2024-08-01' }
      ]
    end

    let(:mock_bill_list_response2) do
      [
        { 'bill_id' => 789, 'title' => 'Bill 3', 'status' => 1, 'status_date' => '2024-08-02' },
        { 'bill_id' => 135, 'title' => 'Bill 4', 'status' => 3, 'status_date' => '2024-08-03' },
        { 'bill_id' => 246, 'title' => 'Bill 5', 'status' => 1, 'status_date' => '2024-08-04' },
        { 'bill_id' => 357, 'title' => 'Bill 6', 'status' => 1, 'status_date' => '2024-07-31' }
      ]
    end

    let(:mock_bill_2_detail_response) do
      {
        'bill_id' => 456,
        'session_id' => session1.legiscan_session_id,
        'texts' => [
          {
            'doc_id' => 1234,
            'type' => 'Introduced'
          },
          {
            'doc_id' => 2345,
            'type' => 'Engrossed'
          },
          {
            'doc_id' => 3456,
            'type' => 'Enrolled'
          }
        ]
      }
    end

    let(:mock_bill_3_detail_response) do
      {
        'bill_id' => 789,
        'session_id' => session2.legiscan_session_id,
        'texts' => [
          {
            'doc_id' => 4567,
            'type' => 'Introduced'
          }
        ]
      }
    end

    let(:mock_bill_4_detail_response) do
      {
        'bill_id' => 135,
        'session_id' => session2.legiscan_session_id,
        'texts' => []
      }
    end

    let(:mock_bill_5_detail_response) do
      {
        'bill_id' => 246,
        'session_id' => session2.legiscan_session_id,
        'texts' => [
          {
            'doc_id' => 5678,
            'type' => 'Introduced'
          }
        ]
      }
    end

    let(:mock_bill_2_text_response) { 'This is the full text for Bill 2.' }
    let(:mock_bill_3_text_response) { 'This is the full text for Bill 3.' }
    let(:mock_bill_5_text_response) { 'This is the full text for Bill 5' }
    let(:mock_bill_2_summary_response) { 'This is the summary for Bill 2.' }
    let(:mock_bill_3_summary_response) { 'This is the summary for Bill 3.' }
    let(:mock_bill_5_summary_response) { 'This is the summary for Bill 5' }

    before do
      allow(legiscan_api).to receive(:get_bill_list)
        .with(session1.legiscan_session_id)
        .and_return(mock_bill_list_response1)
      allow(legiscan_api).to receive(:get_bill_list)
        .with(session2.legiscan_session_id)
        .and_return(mock_bill_list_response2)
      allow(legiscan_api).to receive(:get_bill).with(456).and_return(mock_bill_2_detail_response)
      allow(legiscan_api).to receive(:get_bill).with(789).and_return(mock_bill_3_detail_response)
      allow(legiscan_api).to receive(:get_bill).with(135).and_return(mock_bill_4_detail_response)
      allow(legiscan_api).to receive(:get_bill).with(246).and_return(mock_bill_5_detail_response)
      allow(legiscan_api).to receive(:get_bill_text).with(3456).and_return(mock_bill_2_text_response)
      allow(legiscan_api).to receive(:get_bill_text).with(4567).and_return(mock_bill_3_text_response)
      allow(legiscan_api).to receive(:get_bill_text).with(5678).and_return(mock_bill_5_text_response)

      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary)
        .with(mock_bill_2_text_response)
        .and_return(mock_bill_2_summary_response)
      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary)
        .with(mock_bill_3_text_response)
        .and_return(mock_bill_3_summary_response)
      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary)
        .with(mock_bill_5_text_response)
        .and_return(mock_bill_5_summary_response)
    end

    it 'creates and updates the bills' do
      # This bill does not need to be updated because it has a summary and
      # the status_last_updated matches the status_date from LegiScan
      bill1 = create(:bill, legiscan_bill_id: 123, title: 'Bill 1', summary: 'This is the summary for bill 1',
                            status: 1, status_last_updated: DateTime.new(2024, 7, 31), session_id: session1.id)
      bill1_updated_at = bill1.updated_at

      # This bill needs to be updated because the status does not match
      # the new status from LegiScan
      bill2 = create(:bill, legiscan_bill_id: 456, title: 'Bill 2', summary: 'This is the old summary for bill 2',
                            status: 2, status_last_updated: DateTime.new(2024, 7, 1), session_id: session1.id)

      # This bill needs to be updated because it has no summary
      bill3 = create(:bill, legiscan_bill_id: 789, title: 'Bill 3', summary: nil,
                            status: 1, status_last_updated: DateTime.new(2024, 8, 2), session_id: session2.id)

      job.create_and_update_bills(legiscan_api)

      expect(Bill.count).to eq(5)

      expect(bill1.reload.updated_at).to eq(bill1_updated_at)

      expect(bill2.reload.status).to eq('enrolled')
      expect(bill2.status_last_updated).to eq(DateTime.new(2024, 8, 1))
      expect(bill2.summary).to eq(mock_bill_2_summary_response)

      expect(bill3.reload.summary).to eq(mock_bill_3_summary_response)
      expect(bill3.status).to eq('introduced')
      expect(bill3.status_last_updated).to eq(DateTime.new(2024, 8, 2))

      bill4 = Bill.where(legiscan_bill_id: 135).first
      expect(bill4).to be_present
      expect(bill4.summary).to be_nil
      expect(bill4.title).to eq('Bill 4')
      expect(bill4.status).to eq('enrolled')
      expect(bill4.status_last_updated).to eq(DateTime.new(2024, 8, 3))
      expect(bill4.session_id).to eq(session2.id)

      bill5 = Bill.where(legiscan_bill_id: 246).first
      expect(bill5).to be_present
      expect(bill5.summary).to eq(mock_bill_5_summary_response)
      expect(bill5.title).to eq('Bill 5')
      expect(bill5.status).to eq('introduced')
      expect(bill5.status_last_updated).to eq(DateTime.new(2024, 8, 4))
      expect(bill5.session_id).to eq(session2.id)

      # Bill 6 should not exist because the status date is before
      # the bill cutoff date
      bill6 = Bill.where(legiscan_bill_id: 357).first
      expect(bill6).to be_nil
    end
  end

  describe '#bill_needs_updated?' do
    it 'returns true if the statuses dont match' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 1, 'status_date' => '2024-08-01' }
      database_bill = create(:bill, status: 2, summary: 'This is a summary')

      expect(job.bill_needs_updated?(legiscan_response_bill, database_bill)).to eq(true)
    end

    it 'returns true if the database bill does not have a summary' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 1, 'status_date' => '2024-08-01' }
      database_bill = create(:bill, status: 1, summary: nil)

      expect(job.bill_needs_updated?(legiscan_response_bill, database_bill)).to eq(true)
    end

    it 'returns false if the statuses match and the bill has a summary' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 1, 'status_date' => '2024-08-01' }
      database_bill = create(:bill, status: 1, summary: 'This is a summary')

      expect(job.bill_needs_updated?(legiscan_response_bill, database_bill)).to eq(false)
    end
  end

  describe '#update_existing_bill_status_and_summary' do
    # Other functionality is tested in #create_and_update_bills spec

    let(:session) { create(:session) }

    let(:mock_bill123_detail_response) do
      {
        'bill_id' => 123,
        'session_id' => session.legiscan_session_id,
        'texts' => [
          {
            'doc_id' => 1234,
            'type' => 'Engrossed'
          }
        ]
      }
    end

    let(:mock_bill123_text_response) { 'This is the full text for Bill 1.' }
    let(:mock_bill123_summary_response) { 'This is the summary for Bill 1.' }

    before do
      allow(legiscan_api).to receive(:get_bill).with(123).and_return(mock_bill123_detail_response)
      allow(legiscan_api).to receive(:get_bill_text).with(1234).and_return(mock_bill123_text_response)
      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary)
        .with(mock_bill123_text_response)
        .and_return(mock_bill123_summary_response)
    end

    it 'logs that the bill was updated' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 2, 'status_date' => '2024-08-01' }
      database_bill = create(:bill, legiscan_bill_id: 123, title: 'Bill 1', status: 1,
                                    status_last_updated: DateTime.new(2024, 8, 1))

      expected_log_message = "Updated bill with Title: #{database_bill.title}, Id: #{database_bill.id}"
      expect(Rails.logger).to receive(:info).with(expected_log_message)

      job.update_existing_bill_status_and_summary(legiscan_api, legiscan_response_bill, database_bill)
    end

    it 'catches and logs an error' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 2, 'status_date' => '2024-08-01' }
      database_bill = create(:bill, legiscan_bill_id: 123, title: 'Bill 1', status: 1,
                                    status_last_updated: DateTime.new(2024, 8, 1))

      error_message = 'This is an error message.'
      allow(Bill).to receive(:statuses).and_raise(StandardError, error_message)
      expected_log_message = "Error updating bill with Title: #{database_bill.title}, " \
                             "Id: #{database_bill.id}, Error: #{error_message}"
      expect(Rails.logger).to receive(:error).with(expected_log_message)
      expect(Sentry).to receive(:capture_message).with(expected_log_message)

      job.update_existing_bill_status_and_summary(legiscan_api, legiscan_response_bill, database_bill)
    end
  end

  describe '#create_new_bill' do
    # Other functionality is tested in #create_and_update_bills spec

    let(:session) { create(:session) }

    let(:mock_bill123_detail_response) do
      {
        'bill_id' => 123,
        'session_id' => session.legiscan_session_id,
        'texts' => []
      }
    end

    before do
      allow(legiscan_api).to receive(:get_bill).with(123).and_return(mock_bill123_detail_response)
    end

    it 'logs that the bill was created' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 2, 'status_date' => '2024-08-01' }
      allow(Rails.logger).to receive(:info)
      job.create_new_bill(legiscan_api, legiscan_response_bill, session.id)

      new_bill = Bill.first
      expect(Rails.logger).to have_received(:info)
        .with("Created bill with Title: #{new_bill.title}, id: #{new_bill.id}")
    end

    it 'catches and logs an error' do
      legiscan_response_bill = { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 2, 'status_date' => '2024-08-01' }
      allow(Rails.logger).to receive(:error)
      allow(Sentry).to receive(:capture_message)
      error_message = 'This is an error message.'
      allow(Bill).to receive(:statuses).and_raise(StandardError, error_message)
      job.create_new_bill(legiscan_api, legiscan_response_bill, session.id)

      expected_log_message = "Error creating bill with Title: Bill 1, Legiscan Bill Id: 123, Error: #{error_message}"

      expect(Rails.logger).to have_received(:error).with(expected_log_message)
      expect(Sentry).to have_received(:capture_message).with(expected_log_message)
    end
  end
end
