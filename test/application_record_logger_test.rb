require "test_helper"

class ApplicationRecordLoggerTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ApplicationRecordLogger::VERSION
  end

  test "it has config" do
    assert_instance_of Hash, ApplicationRecordLogger.config
    assert_equal ApplicationRecordLogger.config, ApplicationRecordLogger.class_variable_get("@@config")
    assert_equal ApplicationRecordLogger.config[:log_create], true
    assert_equal ApplicationRecordLogger.config[:log_update], true
    assert_equal ApplicationRecordLogger.config[:log_destroy], true
    assert_equal ApplicationRecordLogger.config[:log_create_data], false
    assert_equal ApplicationRecordLogger.config[:log_user_activity_only], true
    assert_equal ApplicationRecordLogger.config[:log_fields], []
    assert_equal ApplicationRecordLogger.config[:log_field_types], %i(string date integer decimal float datetime)
    assert_equal ApplicationRecordLogger.config[:log_exclude_field_names], %i(id updated_at created_at)
  end
end
