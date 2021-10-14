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
    :rollback   => 3,
  }

  class << self
    def log(**kwargs, &block)
      ApplicationRecordLogger::LogService.call(**kwargs, &block)
    end

    # Hadle rollback sets action db_rollback,
    def rollback(record: nil, record_type: nil, record_id: nil, timepoint: nil, step: nil)
      given_record   = record
      raise ArgumentError.new("No record or record_type given") unless record || record_type
      klass = record ? record.class : record_type.constantize
      given_record ||= klass.find_by(id: record_id) if record_id
      given_record ||= klass.new(id: record_id) if record_id
      raise ArgumentError.new("No record or (record_id and record_type) given!") unless given_record
      raise ArgumentError.new("No timepoint or stepe given") unless timepoint || step
      logs = if step
        ApplicationRecordLog.where(
          record: given_record,
        ).order(:created_at => :desc).limit(step)
      else
        where(
          record: given_record
        ).where(
          "created_at > ?", timepoint
        ).order(:created_at => :desc)
      end
      logs.each do |log|
        hash = log.data || klass.logging_options[:log_fields].map{|key| [key,[nil]]}.to_h
        hash.each do |key, arr|
          given_record.send("#{key}=", arr[0])
        end
      end
      given_record
    end

    def rollback!(**kwargs)
      rec = rollback(**kwargs)
      return [rec, rec.save]
    end
  end
end
