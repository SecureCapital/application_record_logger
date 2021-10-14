class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include ApplicationRecordLogger
  set_logging_callbacks!
end
