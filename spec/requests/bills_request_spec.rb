require 'rails_helper'

RSpec.describe 'BillsController', type: :request do
  before do
    15.times do |i|
      create(:bill, updated_at: i.days.ago)
    end
  end

  it "returns the first page of bills ordered by updated_at descending" do
    get '/bills', params: { page: 1 }

    expect(response).to have_http_status(:ok)
    json_response = JSON.parse(response.body)

    expect(json_response['bills'].size).to eq(10)

    first_bill = json_response['bills'].first
    last_bill = json_response['bills'].last

    expect(first_bill['updated_at']).to be > last_bill['updated_at']
  end

  it "returns the second page of bills ordered by updated_at descending" do
    get '/bills', params: { page: 2 }

    expect(response).to have_http_status(:ok)
    json_response = JSON.parse(response.body)

    expect(json_response['bills'].size).to eq(5)

    first_bill_page_2 = json_response['bills'].first
    last_bill_page_2 = json_response['bills'].last

    get '/bills', params: { page: 1 }
    json_response_page_1 = JSON.parse(response.body)

    last_bill_page_1 = json_response_page_1['bills'].last

    expect(first_bill_page_2['updated_at']).to be < last_bill_page_1['updated_at']
    expect(first_bill_page_2['updated_at']).to be > last_bill_page_2['updated_at']
  end
end