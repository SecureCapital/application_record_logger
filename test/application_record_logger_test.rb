require "test_helper"
require_relative 'app_record_mock'

class ApplicationRecordLoggerTest < ActiveSupport::TestCase
  setup do
    @config = {
      log_exclude_field_names: %w(id updated_at created_at),
      log_create: true,
      log_update: true,
      log_destroy: true,
      log_create_data: false,
      log_user_activity_only: true,
      log_fields: [],
      log_field_types: %i(string date integer decimal float datetime time boolean),
    }
  end

  test "it has a version number" do
    assert ApplicationRecordLogger::VERSION
  end

  test "it has config" do
    assert_equal ApplicationRecordLogger.config, @config
  end

  test "mock has extended ApllicationRecordLogger class methods" do
    assert %i(default_log_fields logging_options configure_logging_options set_logging_callbacks).all? do |meth|
      AppRecordMock.respond_to? meth
    end
  end

  test "mock has respond_to create_application_record_log" do
    @mock = AppRecordMock.new
    assert_respond_to @mock, :create_application_record_log
  end

  test "mock has default_log_fields" do
    expected_default_fields = AppRecordMock.columns_hash.select do |key,struct|
      @config[:log_field_types].include?(struct.type)
    end.reject do |key,struct|
      @config[:log_exclude_field_names].include?(key)
    end.keys
    assert_equal AppRecordMock.default_log_fields.sort, expected_default_fields.sort
  end

  test "mock has default logging options" do
    conf = @config.dup
    conf[:log_fields] = AppRecordMock.default_log_fields
    assert_equal AppRecordMock.logging_options, conf
  end

  test "mock can configure logging_options" do
    instance = AppRecordMock.new
    klass = instance.singleton_class
    klass.configure_logging_options do |opts|
      opts.each do |key,value|
        if !!value == value
          opts[key]=!value
        else
          opts[key]=[]
        end
      end
    end

    new_config = {
      log_exclude_field_names: [],
      log_create: false,
      log_update: false,
      log_destroy: false,
      log_create_data: true,
      log_user_activity_only: false,
      log_fields: [],
      log_field_types: [],
    }

    assert_equal klass.logging_options, new_config
  end
end
