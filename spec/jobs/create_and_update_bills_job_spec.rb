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
end