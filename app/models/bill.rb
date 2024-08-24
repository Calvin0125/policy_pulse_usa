# frozen_string_literal: true

# == Schema Information
#
# Table name: bills
#
#  id                  :integer          not null, primary key
#  status              :integer          not null
#  status_last_updated :datetime
#  summary             :string
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  legiscan_bill_id    :integer          not null
#  legiscan_doc_id     :integer
#  session_id          :integer          not null
#
# Indexes
#
#  index_bills_on_legiscan_bill_id  (legiscan_bill_id) UNIQUE
#  index_bills_on_legiscan_doc_id   (legiscan_doc_id) UNIQUE
#  index_bills_on_session_id        (session_id)
#  index_bills_on_title             (title) UNIQUE
#
# Foreign Keys
#
#  session_id  (session_id => sessions.id)
#
class Bill < ApplicationRecord
  belongs_to :session

  enum status: { introduced: 1, engrossed: 2, enrolled: 3, passed: 4, vetoed: 5, failed: 6 }

  def formatted_bill
    {
      title:,
      status:,
      status_last_updated: iso_8601_formatted_date(status_last_updated),
      summary:
    }
  end

  def iso_8601_formatted_date(date)
    date.strftime('%Y-%m-%d')
  end
end
