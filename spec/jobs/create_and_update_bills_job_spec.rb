require 'rails_helper'

RSpec.describe CreateAndUpdateBillsJob, type: :job do
  let(:job) { described_class.new }
  let(:legiscan_api) { LegiscanApi.new }

  describe '#check_for_new_sessions' do
    let(:session_cutoff_year) { CreateAndUpdateBillsJob::SESSION_CUTOFF_YEAR}
    let(:mock_session_response) do 
      [
        { 'session_id' => 12345, 'year_start' => session_cutoff_year - 2, 'year_end' => session_cutoff_year - 1},
        { 'session_id' => 67890, 'year_start' => session_cutoff_year, 'year_end' => session_cutoff_year + 1}
      ]
    end

    before do
      allow(legiscan_api).to receive(:get_session_list).and_return(mock_session_response)
    end

    it 'creates new sessions if they are after the cutoff year' do
      expect(Rails.logger).to receive(:info).with("Created session with legiscan_session_id: #{mock_session_response[1]['session_id']}")

      job.check_for_new_sessions(legiscan_api)

      expect(Session.count).to eq(1)

      session = Session.first
      expect(session.legiscan_session_id).to eq(67890)
      expect(session.start_date).to eq(DateTime.new(session_cutoff_year, 1, 1, 0, 0, 0))
      expect(session.end_date).to eq(DateTime.new(session_cutoff_year + 1, 12, 31, 23, 59, 59))
    end

    it 'catches and logs the error message if an error is raised' do
      error_message = 'An error has occurred'
      allow(Session).to receive(:create!).and_raise(StandardError.new(error_message))

      expected_log_message = "Error creating session with legiscan_session_id: #{mock_session_response[1]['session_id']}, Error: #{error_message}"
      expect(Rails.logger).to receive(:error).with(expected_log_message)

      job.check_for_new_sessions(legiscan_api)
    end
  end

  describe '#create_and_update_bills' do
    let(:session_1) { create(:session) }
    let(:session_2) { create(:session) }

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
        { 'bill_id' => 246, 'title' => 'Bill 5', 'status' => 1, 'status_date' => '2024-07-31' }
      ]
    end

    let(:mock_bill_456_detail_response) do
      {
        'bill_id' => 456,
        'session_id' => session_1.legiscan_session_id,
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

    let(:mock_bill_789_detail_response) do
      {
        'bill_id' => 789,
        'session_id' => session_2.legiscan_session_id,
        'texts' => [
          {
            'doc_id' => 4567,
            'type' => 'Introduced'
          }
        ]
      }
    end

    let(:mock_bill_135_detail_response) do
      {
        'bill_id' => 135,
        'session_id' => session_2.legiscan_session_id,
        'texts' => []
      }
    end

    let(:mock_bill_456_text_response) { "This is the full text for Bill 2." }
    let(:mock_bill_789_text_response) { "This is the full text for Bill 3." }
    let(:mock_bill_456_summary_response) { "This is the summary for Bill 2." }
    let(:mock_bill_789_summary_response) { "This is the summary for Bill 3." }

    before do
      allow(legiscan_api).to receive(:get_bill_list).with(session_1.legiscan_session_id).and_return(mock_bill_list_response1) 
      allow(legiscan_api).to receive(:get_bill_list).with(session_2.legiscan_session_id).and_return(mock_bill_list_response2)
      allow(legiscan_api).to receive(:get_bill).with(456).and_return(mock_bill_456_detail_response)
      allow(legiscan_api).to receive(:get_bill).with(789).and_return(mock_bill_789_detail_response)
      allow(legiscan_api).to receive(:get_bill).with(135).and_return(mock_bill_135_detail_response)
      allow(legiscan_api).to receive(:get_bill_text).with(3456).and_return(mock_bill_456_text_response)
      allow(legiscan_api).to receive(:get_bill_text).with(4567).and_return(mock_bill_789_text_response)
      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary).with(mock_bill_456_text_response).and_return(mock_bill_456_summary_response)
      allow_any_instance_of(OpenaiApi).to receive(:legal_text_summary).with(mock_bill_789_text_response).and_return(mock_bill_789_summary_response)
    end

    it 'creates and updates the bills' do
      # This bill does not need to be updated because it has a summary and 
      # the status_last_updated matches the status_date from LegiScan
      bill_1 = create(:bill, legiscan_bill_id: 123, title: 'Bill 1', summary: "This is the summary for bill 1",
                      status: 1, status_last_updated: DateTime.new(2024, 7, 31), session_id: session_1.id)
      bill_1_updated_at = bill_1.updated_at

      # This bill needs to be updated because the status does not match
      # the new status from LegiScan
      bill_2 = create(:bill, legiscan_bill_id: 456, title: 'Bill 2', summary: "This is the old summary for bill 2",
                      status: 2, status_last_updated: DateTime.new(2024, 7, 1), session_id: session_1.id)
      
      # This bill needs to be updated because it has no summary
      bill_3 = create(:bill, legiscan_bill_id: 789, title: 'Bill 3', summary: nil,
                      status: 1, status_last_updated: DateTime.new(2024, 8, 2), session_id: session_2.id)
      
      job.create_and_update_bills(legiscan_api)
      
      expect(Bill.count).to eq(4)

      expect(bill_1.reload.updated_at).to eq(bill_1_updated_at)

      expect(bill_2.reload.status).to eq('enrolled')
      expect(bill_2.status_last_updated).to eq(DateTime.new(2024, 8, 1))
      expect(bill_2.summary).to eq(mock_bill_456_summary_response)

      expect(bill_3.reload.summary).to eq(mock_bill_789_summary_response)
      expect(bill_3.status).to eq('introduced')
      expect(bill_3.status_last_updated).to eq(DateTime.new(2024, 8, 2))

      bill_4 = Bill.where(legiscan_bill_id: 135).first
      expect(bill_4).to be_present
      expect(bill_4.summary).to be_nil
      expect(bill_4.title).to eq('Bill 4')
      expect(bill_4.status).to eq('enrolled')
      expect(bill_4.status_last_updated).to eq(DateTime.new(2024, 8, 3))
      expect(bill_4.session_id).to eq(session_2.id)

      # Bill 5 should not exist because the status date is before
      # the bill cutoff date
      bill_5 = Bill.where(legiscan_bill_id: 246).first
      expect(bill_5).to be_nil
    end
  end

  # TODO: Test bill_needs_updated?
  # TODO: Test logging and error handling for update_existing_bill_status_and_summary
  # TODO: Test logging and error handling for create_new_bill
end