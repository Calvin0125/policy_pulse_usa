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
require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:bills) }
  end
end
