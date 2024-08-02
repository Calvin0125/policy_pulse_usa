class AddAndUpdateBills
  include Sidekiq::Worker

  SESSION_CUTOFF_YEAR = 2023
  BILL_CUTOFF_DATE = DateTime.new(2024, 7, 25)

  def perform
    legiscan_api = LegiscanApi.new

    legiscan_api.get_session_list.each do |session|
      if session['year_start'] < SESSION_CUTOFF_YEAR
        next
      end

      if Session.where(legiscan_session_id: session['session_id']).empty?
        Session.create(legiscan_session_id: session['session_id'],
                       start_date: DateTime.new(session['year_start'], 1, 1, 0, 0, 0),
                       end_date: DateTime.new(session['year_end'], 12, 31, 23, 59, 59))
      end

      Session.where('end_date > ?', Time.now).each do |session|
        legiscan_api.get_bill_list(session.legiscan_session_id).each do |bill|
          # stopping here for today
          # there are 6 bills from 7/26 and 7/27 so will use that as my cutoff date
          # need to figure out the logic here
          # if before cutoff date, next
          # if new bill, get text summary, create new bill
          # if existing bill but new status, get new text summary and update
          # second 2 ifs could maybe be a method on bill model
          if bill["status_date"] < BILL_CUTOFF_DATE
            next
          end

          bill_id = bill["bill_id"]
          existing_bill = Bill.where(legiscan_bill_id: bill_id).first

          if existing_bill && bill["status"] != existing_bill.status
            new_status = bill["status"]
            bill = LegiscanApi.get_bill(bill_id)
            # Make mapping of type integer to string
            # iterate through texts, it is an array of hashes like this.
            # [{"doc_id"=>2723963,
            #   "date"=>"2023-03-01",
            #   "type"=>"Introduced",
            #   "type_id"=>1,
            #   "mime"=>"application/pdf",
            #   "mime_id"=>2,
            #   "url"=>"https://legiscan.com/US/text/HB5/id/2723963",
            #   "state_link"=>"https://www.congress.gov/118/bills/hr5/BILLS-118hr5ih.pdf",
            #   "text_size"=>264937,
            #   "text_hash"=>"b6bb2065cb7ab2ad89ba59322521db49",
            #   "alt_bill_text"=>0,
            #   "alt_mime"=>"",
            #   "alt_mime_id"=>0,
            #   "alt_state_link"=>"",
            #   "alt_text_size"=>0,
            #   "alt_text_hash"=>""},

            # Get the doc_id where the type string matches the new status integer
            # Use the doc_id to get the bill text and then summarize it
            # Update status, summary, and legiscan_doc_id in the database
          elsif !existing_bill
            # same logic as above, but create a new bill.
            # so probably extract that logic to a method, need a good name
        end
      end
    end
  end
end