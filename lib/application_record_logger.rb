require "application_record_logger/engine"
require "application_record_logger/version"

module ApplicationRecordLogger
  def self.config
    @@config ||= {
      log_field_types: %i(string date integer decimal float datetime),
      exclude_field_names: %w(id updated_at created_at)
    }
  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      has_many :application_record_logs, as: :owner

      after_create do
        create_application_record_log!(:db_create) if self.class.log_create
      end

      after_update do
        create_application_record_log!(:db_update) if self.class.log_update
      end

      after_destroy do
        create_application_record_log!(:db_destroy) if self.class.log_destroy
      end
    end
  end

  module ClassMethods
    def default_logging_fields
      @@default_logging_fields ||= columns_hash.map do |key,rec|
        [key, rec.type]
      end.select do |key,type|
        ApplicationRecordLogger.config[:log_field_types].include?(type)
      end.reject do |key, type|
        ApplicationRecordLogger.config[:exclude_field_names].include?(key)
      end.map(&:first)
    end

    def logging_options
      {
        log_create: true,
        log_update: true,
        log_destroy: true,
        log_fields: default_logging_fields,
        log_create_data: false,
        log_user_activity_only: true,
      }
    end

    %i(log_create log_update log_destroy log_fields log_create_data log_user_activity_only).each do |key|
      define_method(key) do
        logging_options[key]
      end
    end
  end

  attr_accessor :current_user

  def logging_data
    saved_changes.slice(*self.class.log_fields)
  end

  def user_and_log_user_only?
    if self.class.log_user_activity_only
      current_user && current_user.id
    else
      true
    end
  end

  def log_create?
    self.class.log_create && user_and_log_user_only?
  end

  def log_update?
    self.class.log_update && user_and_log_user_only?
  end

  def log_destroy?
    self.class.log_destroy && user_and_log_user_only?
  end

  private
  def create_application_record_log!(action)
    ApplicationRecordLog.log(
      record: self,
      user: current_user,
      action: action,
    )
  end
end
