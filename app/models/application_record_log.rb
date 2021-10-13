class ApplicationRecordLog < ApplicationRecord
  # self.table_name = 'application_record_logs'
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

  belongs_to :record, polymorphic: true, optional: false
  belongs_to :user, optional: true
  serialize :data
  enum :action => {
    :db_create  => 0,
    :db_update  => 1,
    :db_destroy => 2,
  }

  class << self
    def rollback(record:, record_type:, record_id:, timepoint:, step:)
      klass       = record_type.constantize
      given_record = record
      given_record ||= klass.find_by(id: record_id)
      given_record ||= klass.new(id: record_id)
      logs = if step
        where(
          record: record,
        ).order(:updated_at => :desc).limit(step)
      else
        where(
          record: record,
          updated_at: timepoint..(DateTime::Infinity.new)
        ).order(:updated_at => :desc)
      end
      if timepoint && (timepoint < where(record: record).minimum(:updated_at))
        return klass.new(id: record_id)
      else
        logs.each do |log|
          (log.data||{}).each do |key, arr|
            given_record.send("#{key}=", arr[0])
          end
        end
        given_record
      end
    end

    def rollback!(**kwargs)
      rollback(**kwargs).save
    end
  end
end
