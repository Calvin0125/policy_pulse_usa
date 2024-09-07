# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://c3736e8e15d592c017546b1d16a2b612@o936036.ingest.us.sentry.io/4507913552592896'
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0
end
