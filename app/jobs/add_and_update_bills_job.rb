class AddAndUpdateBills
  include Sidekiq::Worker

  def perform
    legiscan_api = LegiscanApi.new

    legiscan_api.get_session_list.each do |session|
      if session['year_start'] < 2023
        break
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
        end
      end
    end
  end
end