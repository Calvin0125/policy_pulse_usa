# frozen_string_literal: true

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
      bill_id = 1_741_372
      bill = api.get_bill(bill_id)
      expect(bill).to be_a(Hash)
      expect(bill).to have_key('status')
      expect(bill).to have_key('status_date')
      expect(bill).to have_key('texts')
    end
  end

  describe '#get_bill_text', :vcr do
    it 'returns the text of the bill for a given doc_id' do
      doc_id = 2_746_931
      text = api.get_bill_text(doc_id)
      expect(text).to be_a(String)
      expect(text).not_to be_empty
      expect(text).not_to match(/\s{2,}/)
    end
  end

  describe 'credit tracking' do
    before do
      allow(LegiscanCredit).to receive(:limit_reached?)
      allow(LegiscanCredit).to receive(:increment_credits)
    end

    context 'when under the limit' do
      before do
        allow(LegiscanCredit).to receive(:limit_reached?).and_return(false)
      end

      it 'checks and increments credits for #get_session_list' do
        allow(HTTP).to receive(:get).and_return(double(body: { 'sessions' => [] }.to_json))

        api.get_session_list

        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).to have_received(:increment_credits)
      end

      it 'checks and increments credits for #get_bill_list' do
        fake_master = { 'session' => {}, 'b1' => {}, 'b2' => {} }
        allow(HTTP).to receive(:get).and_return(double(body: { 'masterlist' => fake_master }.to_json))

        api.get_bill_list(123)

        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).to have_received(:increment_credits)
      end

      it 'checks and increments credits for #get_bill' do
        allow(HTTP).to receive(:get).and_return(double(body: { 'bill' => { 'status' => 1 } }.to_json))

        api.get_bill(456)

        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).to have_received(:increment_credits)
      end

      it 'checks and increments credits for #get_bill_text' do
        encoded = Base64.encode64('hello')
        allow(HTTP).to receive(:get).and_return(double(body: { 'text' => { 'doc' => encoded } }.to_json))
        fake_page = double(text: 'hello')
        fake_reader = double(pages: [fake_page])
        allow(PDF::Reader).to receive(:new).and_return(fake_reader)

        api.get_bill_text(789)

        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).to have_received(:increment_credits)
      end
    end

    context 'when at or over the limit' do
      before do
        allow(LegiscanCredit).to receive(:limit_reached?).and_return(true)
        allow(HTTP).to receive(:get)
      end

      it 'does not send request and does not increment for #get_session_list' do
        expect(api.get_session_list).to be_nil
        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).not_to have_received(:increment_credits)
        expect(HTTP).not_to have_received(:get)
      end

      it 'does not send request and does not increment for #get_bill_list' do
        expect(api.get_bill_list(123)).to be_nil
        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).not_to have_received(:increment_credits)
        expect(HTTP).not_to have_received(:get)
      end

      it 'does not send request and does not increment for #get_bill' do
        expect(api.get_bill(456)).to be_nil
        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).not_to have_received(:increment_credits)
        expect(HTTP).not_to have_received(:get)
      end

      it 'does not send request and does not increment for #get_bill_text' do
        expect(api.get_bill_text(789)).to be_nil
        expect(LegiscanCredit).to have_received(:limit_reached?)
        expect(LegiscanCredit).not_to have_received(:increment_credits)
        expect(HTTP).not_to have_received(:get)
      end
    end
  end
end
