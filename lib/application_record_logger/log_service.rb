# Service class to produce ApplicationRecordLog instance after create, update or
# destroy. Handles the boolean logic og wheter or not a log instance should be
# produced, and resolves the data tp be logged.
# Note:
# 1) This class will produce a log when the record return something in :saved_changes
# 2) The config determines wheter or not a log should be filed.
# 3) On create all data will be stored if configured :log_create_data => true
# 4) A unique record can be created multiple times via ApplicationRecordLog.rollback
#    if the record has been destroyed. In such create case, the log will contain
#    full rollback information
# 5) On update log will be fired if data cahnges are given on fields to be logged
# 6) On destroy log will contain all log_fields
#
# Kwargs
#  record: AppRecord instance
#  user: User object committing the action or integer representing user_id
#  action: %i(db_create db_update db_destroy)
#  config: Hash of logging_options

require "application_record_logger/service"

module ApplicationRecordLogger
  class LogService < Service
    def initialize(record:, action:, **kwargs)
      @record = record
      @action = action
      kwargs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @user = user
      @config = config
      yield self if block_given?
    end

    def call
      if produce_log?
        ::ApplicationRecordLog.create(**data)
      else
        false
      end
    end

    def produce_log?
      if record && action && user_requierd_and_user_given?
        case action
        when :db_create
          config[:log_create] && (log_create_data||user_id)
        when :db_update
          config[:log_update] && log_update_data.any?
        when :db_destroy
          config[:log_destroy]
        else
          false
        end
      else
        false
      end
    end

    def data
      {
        record: record,
        user_id: user_id,
        action: action,
        data: log_data,
      }
    end

    def log_data
      send "log_#{action.to_s.split('_')[1]}_data"
    end

    def log_create_data
      # if db_create_record_exists? we are creating second time, meaning a
      # destruction has been made, thus we desire to post the new inital
      # values
      if config[:log_create_data] || db_create_record_exists?
        log_update_data
      else
        nil
      end
    end

    def db_create_record_exists?
      logs.where(action: :db_create).any?
    end

    def log_update_data
      record.saved_changes.slice(*config[:log_fields])
    end

    def log_destroy_data
      record.attributes.map do |key, value|
        [key, [value, nil]]
      end.to_h.slice(*config[:log_fields])
    end

    def user_requierd_and_user_given?
      if config[:log_user_activity_only]
        !!user_id
      else
        true
      end
    end
  end
end
