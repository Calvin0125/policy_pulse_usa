require 'rails_helper'

RSpec.describe LegiscanApi do
  let(:api) { LegiscanApi.new }

  describe '#get_session_list', :vcr do
    it 'returns an array of sessions' do
      sessions = api.get_session_list
      expect(sessions).to be_an(Array)
      expect(sessions.first).to have_key('session_id')
      expect(sessions.first).to have_key('year_start')
      expect(sessions.first).to have_key('year_end')
      expect(sessions.first).to have_key('name')
    end
  end

  describe '#get_bill_list', :vcr do
    it 'returns an array of bills for a given session' do
      session_id = 2041
      bills = api.get_bill_list(session_id)
      expect(bills).to be_an(Array)
      expect(bills.first).to have_key('bill_id')
    end
  end

  describe '#get_bill', :vcr do
    it 'returns a bill hash for a given bill_id' do
      bill_id = 1741372
      bill = api.get_bill(bill_id)
      expect(bill).to be_a(Hash)
      expect(bill).to have_key('status')
      expect(bill).to have_key('status_date')
      expect(bill).to have_key('texts')
    end
  end

  describe '#get_bill_text', :vcr do
    it 'returns the text of the bill for a given doc_id' do
      doc_id = 2746931
      text = api.get_bill_text(doc_id)
      expect(text).to be_a(String)
      expect(text).not_to be_empty
      expect(text).not_to match(/\s{2,}/)
    end
  end
end