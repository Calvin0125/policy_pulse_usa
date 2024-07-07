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
require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:bills) }
  end
end
