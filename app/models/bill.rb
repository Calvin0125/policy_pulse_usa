# == Schema Information
#
# Table name: bills
#
#  id                  :integer          not null, primary key
#  status              :integer
#  status_last_updated :datetime
#  summary             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  legiscan_bill_id    :integer
#  legiscan_doc_id     :integer
#  session_id          :integer
#
# Indexes
#
#  index_bills_on_session_id  (session_id)
#
# Foreign Keys
#
#  session_id  (session_id => sessions.id)
#
class Bill < ApplicationRecord
  # TODO: Add unique constraing to legiscan_bill_id and legiscan_doc_id
  # TODO: Add a title field
  belongs_to :session

  enum status: { introduced: 1, engrossed: 2, enrolled: 3, passed: 4, vetoed: 5 }
end
