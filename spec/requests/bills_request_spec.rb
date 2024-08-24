# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BillsController', type: :request do
  before do
    15.times do |i|
      create(:bill, status_last_updated: i.days.ago)
    end
  end

  it 'returns the first page of bills ordered by status_last_updated descending' do
    get '/bills', params: { page: 1 }

    expect(response).to have_http_status(:ok)
    json_response = JSON.parse(response.body)
    expected_json_response_bills = JSON.parse(Bill.order(status_last_updated: :desc)
                                     .limit(10).map(&:formatted_bill).to_json)

    expect(json_response['bills'].size).to eq(10)
    expect(json_response['bills']).to eq(expected_json_response_bills)
  end

  it 'returns the second page of bills ordered by status_last_updated descending' do
    get '/bills', params: { page: 2 }

    expect(response).to have_http_status(:ok)
    json_response = JSON.parse(response.body)
    expected_json_response_bills = JSON.parse(Bill.order(status_last_updated: :desc)
                                     .map(&:formatted_bill)[10..14].to_json)

    expect(json_response['bills'].size).to eq(5)
    expect(json_response['bills']).to eq(expected_json_response_bills)
  end
end
