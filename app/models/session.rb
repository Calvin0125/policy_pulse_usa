# frozen_string_literal: true

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
class Session < ApplicationRecord
  has_many :bills
end
