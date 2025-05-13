# frozen_string_literal: true

# == Schema Information
#
# Table name: legiscan_credits
#
#  id           :bigint           not null, primary key
#  credits_used :integer          default(0), not null
#  month        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_legiscan_credits_on_month  (month) UNIQUE
#
class LegiscanCredit < ApplicationRecord
  validates :month, presence: true, uniqueness: { case_sensitive: false }
  validates :credits_used, presence: true, numericality: { only_integer: true }

  def self.increment_credits
    current_month = Time.current.strftime('%Y-%m')
    record = find_or_create_by!(month: current_month) { |c| c.credits_used = 0 }
    record.increment!(:credits_used)
  end

  def self.limit_reached?
    record = find_by(month: Time.current.strftime('%Y-%m'))
    record && record.credits_used >= LegiscanApi::API_MONTHLY_CREDIT_LIMIT
  end
end
