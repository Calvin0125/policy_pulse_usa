# == Schema Information
#
# Table name: sessions
#
#  id                  :integer          not null, primary key
#  end_date            :datetime
#  start_date          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  legiscan_session_id :integer
#
class Session < ApplicationRecord
  has_many :bills
end
