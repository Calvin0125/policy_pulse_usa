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
    let(:mock_bill_list) do
      [
        { 'bill_id' => 123, 'title' => 'Bill 1', 'status' => 1, 'status_date' => '2024-07-31' },
        { 'bill_id' => 456, 'title' => 'Bill 2', 'status' => 2, 'status_date' => '2024-08-01' },
        { 'bill_id' => 789, 'title' => 'Bill 3', 'status' => 1, 'status_date' => '2024-08-02' }
        { 'bill_id' => 135, 'title' => 'Bill 4', 'status' => 3, 'status_date' => '2024-08-03' }
      ]
    end

    # Mock response for 456 and 789 and 135 bill detail
    # Mock bill text response for 456, 789, and 135
    # Make 135 have no text
    # Mock AI summary for 456, 789.
    # Test that 456 and 789 are updated, test 135 is created.
    
    # Then test each method individually, mainly for the logging
    # or could test logging in this test if you want

    it 'creates and updates the bills' do
      # This bill does not need to be updated because it has a summary and 
      # the status_last_updated matches the status_date from LegiScan
      # TODO: check that code to update this bill is never reached
      bill_1 = create(:bill, legiscan_bill_id: 123, title: 'Bill 1', summary: "This is the summary for bill 1",
                      status: 1, status_last_updated: DateTime.new(2024, 7 31))
      # This bill needs to be updated because the status does not match
      # the new status from LegiScan
      bill_2 = create(:bill, legiscan_bill_id: 456, title: 'Bill 2', summary: "This is the old summary for bill 2",
                      status: 3, status_last_updated: DateTime.new(2024, 7, 1))
      
      # This bill needs to be updated because it has no summary
      bill_3 = create(:bill, legiscan_bill_id: 789, title: 'Bill 3', summary: nil,
                      status: 1, status_last_updated: DateTime.new(2024, 8, 2))
      
      # TODO: Check that bill with id 135 is created
    end
  end
end