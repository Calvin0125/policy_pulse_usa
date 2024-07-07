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
require 'rails_helper'

RSpec.describe Bill, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:session) }
  end
end
