require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  setup do
    @log_fields = ['title','price','date']
    @new_invoice = {
      title: "Test no create log",
      body: "Message to consumer",
      price: 12.45,
      data: {a: 'cool'},
      date: '2021-01-01',
    }
    @invoice = Invoice.new
  end

  test "has appropriate default log_fields" do
    assert_equal Invoice.default_log_fields, @log_fields
  end

  test "Invoice has defualt logging_fields" do
    assert_equal Invoice.logging_options[:log_fields], @log_fields
  end

  test "it can configure logging options" do
    class ::Invoice < ApplicationRecord
      configure_logging_options do |opts|
        opts[:log_fields] = []
        opts[:log_field_types] = %i(string)
      end
    end

    assert_equal Invoice.logging_options[:log_fields], ['title']
    assert_equal Invoice.logging_options[:log_field_types], [:string]

    class ::Invoice < ApplicationRecord
      configure_logging_options do |opts|
        opts[:log_fields] = ['mockery']
      end
    end

    assert_equal Invoice.logging_options[:log_fields], ['mockery']

    # Reset!
    Invoice.configure_logging_options do |opts|
      opts[:log_field_types] = ApplicationRecordLogger.config[:log_field_types]
      opts[:log_fields] = Invoice.default_log_fields
    end

    assert_equal Invoice.logging_options, ApplicationRecordLogger.config.merge(log_fields: @log_fields)
  end

  test "invoice has many application_record_logs" do
    name = :application_record_logs
    assert_respond_to @invoice, name
    reflections = Invoice.reflect_on_all_associations
    found = reflections.find{|obj| obj.name == name}
    assert_not_equal found, nil
    assert_equal found.options, {as: :record}
  end
end
