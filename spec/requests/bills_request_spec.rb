# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BillsController', type: :request do
  before do
    13.times do |i|
      if i.even?
        create(:bill, status_last_updated: i.days.ago, summary: 'This is a summary')
      else
        create(:bill, status_last_updated: i.days.ago, summary: nil)
      end
    end
  end

  let(:headers) { { 'Accept' => 'application/json' } }

  context "onlyWithSummary = 'false'" do
    it 'returns the first page of bills ordered by status_last_updated descending' do
      get('/bills', params: { page: 1, onlyWithSummary: 'false' }, headers:)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expected_json_response_bills = JSON.parse(Bill.order(status_last_updated: :desc)
                                      .limit(5).map(&:formatted_bill).to_json)

      expect(json_response['bills'].size).to eq(5)
      expect(json_response['bills']).to eq(expected_json_response_bills)
    end

    it 'returns the third page of bills ordered by status_last_updated descending' do
      get('/bills', params: { page: 3, onlyWithSummary: 'false' }, headers:)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expected_json_response_bills = JSON.parse(Bill.order(status_last_updated: :desc)
                                      .map(&:formatted_bill)[10..12].to_json)

      expect(json_response['bills'].size).to eq(3)
      expect(json_response['bills']).to eq(expected_json_response_bills)
    end
  end

  context "onlyWithSummary = 'true'" do
    it 'returns the first page of bills with summaries ordered by status_last_updated descending' do
      get('/bills', params: { page: 1, onlyWithSummary: 'true' }, headers:)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expected_json_response_bills = JSON.parse(Bill.where.not(summary: nil).order(status_last_updated: :desc)
                                      .limit(5).map(&:formatted_bill).to_json)

      expect(json_response['bills'].size).to eq(5)
      expect(json_response['bills']).to eq(expected_json_response_bills)
    end

    it 'returns the second page of bills ordered by status_last_updated descending' do
      get('/bills', params: { page: 2, onlyWithSummary: 'true' }, headers:)

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expected_json_response_bills = JSON.parse(Bill.where.not(summary: nil).order(status_last_updated: :desc)
                                      .map(&:formatted_bill)[5..6].to_json)

      expect(json_response['bills'].size).to eq(2)
      expect(json_response['bills']).to eq(expected_json_response_bills)
    end
  end
end
