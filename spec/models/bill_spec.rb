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
require 'rails_helper'

RSpec.describe Bill, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:session) }
  end
end
