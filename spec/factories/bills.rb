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

FactoryBot.define do
  factory :bill do
    status { [1, 2, 3, 4].sample }
    status_last_updated { DateTime.now }
    summary { 'This is a summary of a bill.' }
    sequence(:title) { |n| "Bill #{n}" }
    sequence(:legiscan_bill_id) { |n| "#{n}#{n + 1}#{n + 2}" }
    sequence(:legiscan_doc_id) { |n| "#{n}#{n + 1}#{n + 2}" }
    session { create(:session) }
  end
end
