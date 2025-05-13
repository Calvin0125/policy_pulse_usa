# frozen_string_literal: true

class LegiscanApi
  API_MONTHLY_CREDIT_LIMIT = 30_000

  def initialize
    @api_key = Rails.application.credentials.legiscan_api_key
  end

  def get_session_list
    # Returns an array of sessions
    # Sample session in array
    # {
    #   "session_id" => 2041,
    #   "state_id" => 52,
    #   "year_start" => 2023,
    #   "year_end" => 2024,
    #   "prefile" => 0,
    #   "sine_die" => 0,
    #   "prior" => 0,
    #   "special" => 0,
    #   "session_tag" => "Regular Session",
    #   "session_title" => "2023-2024 Regular Session",
    #   "session_name" => "118th Congress",
    #   "dataset_hash" => "6a282aa75396db5e79686190ffabda6d",
    #   "session_hash" => "6a282aa75396db5e79686190ffabda6d",
    #   "name" => "118th Congress"
    # }
    return if LegiscanCredit.limit_reached?

    response = HTTP.get("https://api.legiscan.com/?key=#{@api_key}&op=getSessionList&state=US")
    LegiscanCredit.increment_credits
    JSON.parse(response.body)['sessions']
  end

  def get_bill_list(session_id)
    # returns an array of bills
    # sample bill from array
    # {
    #   "bill_id" => 1741372,
    #   "number" => "HB1",
    #   "change_hash" => "8253048d2353bc25d532d4be340ddd0a",
    #   "url" => "https://legiscan.com/US/bill/HB1/2023",
    #   "status_date" => "2023-03-14",
    #   "status" => 1,
    #   "last_action_date" => "2023-03-30",
    #   "last_action" => "The Clerk was authorized to correct section numbers..."
    #   "title" => "Water Quality Certification and Energy Project Improvement Act..."
    #   "description" => "To lower energy costs by increasing American energy production..."
    # }
    return if LegiscanCredit.limit_reached?

    response = HTTP.get("https://api.legiscan.com/?key=#{@api_key}&op=getMasterList&id=#{session_id}")
    LegiscanCredit.increment_credits
    master_list = JSON.parse(response.body)['masterlist']
    # First key/value pair in the response is the session, all after that are bills
    master_list.values[1..]
  end

  def get_bill(bill_id)
    # returns a bill hash
    # has many keys, but we are interested in 'status' and 'status_date'
    return if LegiscanCredit.limit_reached?

    response = HTTP.get("https://api.legiscan.com/?key=#{@api_key}&op=getBill&id=#{bill_id}")
    LegiscanCredit.increment_credits
    JSON.parse(response.body)['bill']
  end

  def get_bill_text(doc_id)
    return if LegiscanCredit.limit_reached?

    response = HTTP.get("https://api.legiscan.com/?key=#{@api_key}&op=getBillText&id=#{doc_id}")
    LegiscanCredit.increment_credits
    base_64_encoded_text = JSON.parse(response.body)['text']['doc']
    decoded_text = Base64.decode64(base_64_encoded_text)
    pdf_io = StringIO.new(decoded_text)
    pdf_reader = PDF::Reader.new(pdf_io)

    text = ''
    pdf_reader.pages.each do |page|
      text += page.text
    end

    text.gsub(/\s+/, ' ').strip
  end
end
