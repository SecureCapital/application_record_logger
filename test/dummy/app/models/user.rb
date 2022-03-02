class User < ApplicationRecord
  include ApplicationRecordLogger
  configure_logging_options do |opts|
    opts[:log_user_activity_only] = false
    opts[:log_create_data] = true
  end
  set_logging_callbacks!
end
