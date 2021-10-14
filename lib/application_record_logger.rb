require "application_record_logger/engine"
require "application_record_logger/version"
require "application_record_logger/log_service"

module ApplicationRecordLogger
  @@config = {
    log_create: true,
    log_update: true,
    log_destroy: true,
    log_create_data: false,
    log_user_activity_only: true,
    log_fields: [],
    log_field_types: %i(string date integer decimal float datetime),
    log_exclude_field_names: %i(id updated_at created_at),
    with_callbacks: true,
  }

  def self.config
    @@config
  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      has_many :application_record_logs, as: :record
    end
    base.set_logging_callbacks! if base.logging_options[:with_callbacks]
  end

  module ClassMethods
    def default_log_fields
      if table_name.blank?
        []
      else
        field_types = logging_options[:log_field_types]
        exclude_names = logging_options[:log_exclude_field_names]

        columns_hash.map do |key,rec|
          [key, rec.type]
        end.select do |key,type|
          (field_types == [:any])||field_types.include?(type.to_sym)
        end.reject do |key, type|
          exclude_names.include?(key.to_sym)
        end.map(&:first)
      end
    end

    def logging_options
      @logging_options ||= set_logging_options
    end

    def configure_logging_options(&block)
      set_logging_options(&block)
    end

    def set_logging_callbacks!
      class_eval do
        after_create do
          create_application_record_log(action: :db_create, user: current_user)
        end

        after_update do
          create_application_record_log(action: :db_update, user: current_user)
        end

        after_destroy do
          create_application_record_log(action: :db_destroy, user: current_user)
        end

        attr_accessor :current_user
      end
    end

    private
    def set_logging_options(&block)
      @logging_options = ApplicationRecordLogger.config.dup
      yield @logging_options if block_given?
      if @logging_options[:log_fields].empty?
        @logging_options[:log_fields] = default_log_fields
      end
      @logging_options
    end
  end

  def create_application_record_log(action:, user:, config: nil)
    res = ApplicationRecordLogger::LogService.call(
      record: self,
      user:   user,
      action: action,
      config: config
    )
    if res && application_record_logs.loaded
      application_record_logs << res
    end
  end
end
