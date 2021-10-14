require "./test/test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  setup do
    @class_methods = [
      :configure_logging_options,
      :default_log_fields,
      :logging_options,
      :set_logging_callbacks!,
    ]
    @log_create = "PLEASE DO!"
    ApplicationRecord.configure_logging_options do |opts|
      opts[:log_create] = @log_create
    end
  end

  test "has logger class methods" do
    assert @class_methods.all?{|meth| ApplicationRecord.respond_to?(meth)}
  end

  test "has appropriate logging options" do
    assert_equal ApplicationRecord.logging_options,
      ApplicationRecordLogger.config.merge(log_fields: [], log_create: @log_create)
  end

  test "Has set log_create" do
    assert_equal ApplicationRecord.logging_options[:log_create], @log_create
  end

  test "Change of log_create has not afflicted any other class" do
    assert_not_equal ApplicationRecord.logging_options[:log_create], Invoice.logging_options[:log_create]
    assert_not_equal ApplicationRecord.logging_options[:log_create], User.logging_options[:log_create]
  end
end
