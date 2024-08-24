# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<LEGISCAN_API_KEY>') { Rails.application.credentials.legiscan_api_key }
  config.default_cassette_options = { record: :new_episodes }
end
