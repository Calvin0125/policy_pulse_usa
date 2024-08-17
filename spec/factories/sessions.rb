# == Schema Information
#
# Table name: sessions
#
#  id                  :integer          not null, primary key
#  end_date            :datetime         not null
#  start_date          :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  legiscan_session_id :integer          not null
#
# Indexes
#
#  index_sessions_on_legiscan_session_id  (legiscan_session_id) UNIQUE
#

FactoryBot.define do
  factory :session do
    start_date { Time.current.beginning_of_year.to_datetime }
    end_date { Time.current.end_of_year.to_datetime }
    sequence(:legiscan_session_id) { |n| "#{n}#{n + 1}#{n + 2}"}
  end
end
