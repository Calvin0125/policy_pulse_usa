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
require 'rails_helper'

RSpec.describe LegiscanCredit, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_month_str) { Time.current.strftime('%Y-%m') }
  let(:limit) { LegiscanApi::API_MONTHLY_CREDIT_LIMIT }

  describe 'validations' do
    subject { described_class.new(month: '2025-05', credits_used: 0) }

    it { is_expected.to validate_presence_of(:month) }
    it { is_expected.to validate_uniqueness_of(:month).case_insensitive }
    it { is_expected.to validate_presence_of(:credits_used) }
    it { is_expected.to validate_numericality_of(:credits_used).only_integer }
  end

  describe '.increment_credits' do
    before { travel_to Time.zone.local(2025, 5, 12) }
    after  { travel_back }

    it 'creates a new record with credits_used = 1 when none exists' do
      expect do
        described_class.increment_credits
      end.to change { described_class.count }.by(1)

      record = described_class.find_by(month: current_month_str)
      expect(record.credits_used).to eq 1
    end

    it 'increments credits_used on an existing record' do
      api_credit_record = described_class.create!(month: current_month_str, credits_used: 5)

      expect do
        described_class.increment_credits
      end.to change {
        api_credit_record.reload.credits_used
      }.from(5).to(6)
    end
  end

  describe '.limit_reached?' do
    before { travel_to Time.zone.local(2025, 5, 12) }
    after  { travel_back }

    context 'when no record exists for the current month' do
      it 'returns false' do
        expect(described_class.limit_reached?).to be_falsy
      end
    end

    context 'when credits_used is below the limit' do
      before do
        described_class.create!(month: current_month_str, credits_used: limit - 1)
      end

      it 'returns false' do
        expect(described_class.limit_reached?).to eq(false)
      end
    end

    context 'when credits_used equals the limit' do
      before do
        described_class.create!(month: current_month_str, credits_used: limit)
      end

      it 'returns true' do
        expect(described_class.limit_reached?).to eq(true)
      end
    end

    context 'when credits_used exceeds the limit' do
      before do
        described_class.create!(month: current_month_str, credits_used: limit + 5)
      end

      it 'returns true' do
        expect(described_class.limit_reached?).to eq(true)
      end
    end
  end
end
