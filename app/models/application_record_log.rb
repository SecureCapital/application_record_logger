class ApplicationRecordLog < ApplicationRecord
  # self.table_name = 'application_record_logs'
  # Skip callbacks on application_record_log itself - we will not add a log to a log
  skip_callback :after_create
  skip_callback :after_update
  skip_callback :after_destroy

  def self.log_create
    false
  end

  def self.log_update
    false
  end

  def self.log_destroy
    false
  end

  belongs_to :record, polymorphic: true
  belongs_to :user, optional: true
  serialize :data
  enum :action => {
    :db_create  => 0,
    :db_update  => 1,
    :db_destroy => 2,
    :rollback   => 3,
  }

  validates :record_id, presence: true
  validates :record_type, presence: true
  validates :action, inclusion: {in: actions.keys}

  def action=(value)
    super case value
    when /create/i  then 'db_create'
    when /update/i  then 'db_update'
    when /destroy/i then 'db_destroy'
    when /rollback/i then 'rollback'
    else
      value
    end
  end

  class << self
    def log(**kwargs, &block)
      ApplicationRecordLogger::LogService.call(**kwargs, &block)
    end

    def rollback(**kwargs, &block)
      ApplicationRecordLogger::RollbackService.call(**kwargs, &block)
    end

    def rollback!(**kwargs)
      ApplicationRecordLogger::RollbackService.call!(**kwargs, &block)
    end
  end
end
