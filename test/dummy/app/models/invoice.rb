class Invoice < ApplicationRecord
  serialize :data
  include ApplicationRecordLogger
end
