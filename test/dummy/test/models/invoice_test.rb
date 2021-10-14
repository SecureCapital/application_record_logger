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
    @invoice = Invoice.first
    @user = User.first
  end

  test "has appropriate default log_fields" do
    assert_equal Invoice.default_log_fields, @log_fields
  end

  test "Invoice has defualt logging_fields" do
    assert_equal Invoice.logging_options[:log_fields], @log_fields
  end

  test "has not inherited logging optins from application record" do
    assert_not_equal Invoice.logging_options, ApplicationRecord.logging_options
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

  test "respons to current user " do
    assert_respond_to @invoice, :current_user
    assert_respond_to @invoice, :current_user=
  end

  # Tests below referes to log creation on update, destroy, and create.
  # These are produced by LogService, thus below tests hould be moved to
  # log_service_test, and test on invoice should just confirm wheter or not
  # a log has been created.
  test "creating without user does not create log" do
    invoice = Invoice.create(**@new_invoice)
    assert_equal invoice.application_record_logs.size, 0
    assert_equal ApplicationRecordLog.where(record: invoice).count, 0
  end

  test "creating with user do create a log" do
    invoice = Invoice.create(**@new_invoice.merge(current_user: @user))
    assert_equal invoice.application_record_logs.size, 1
    assert_equal ApplicationRecordLog.where(record: invoice).count, 1

    log = invoice.application_record_logs.first
    assert_equal log.record_type, 'Invoice'
    assert_equal log.record_id, invoice.id
    assert_equal log.user_id, @user.id
    assert_equal log.action, 'db_create'
    assert_equal log.data, nil
    assert log.created_at >= invoice.created_at
  end

  test "configure log_user_activity_only=false and create do create a log" do
    Invoice.configure_logging_options do |opts|
      opts[:log_user_activity_only] = false
      opts[:log_create_data] = true
    end
    invoice = Invoice.create(**@new_invoice)
    assert_equal invoice.application_record_logs.size, 1
    assert_equal ::ApplicationRecordLog.where(record: invoice).count, 1
    log = invoice.application_record_logs.first
    expected_data = {
      "title"=>[nil, invoice.title],
      "price"=>[nil, invoice.price],
      "date"=>[nil, invoice.date]
    }
    assert_equal log.record_type, 'Invoice'
    assert_equal log.record_id, invoice.id
    assert_equal log.user_id, nil
    assert_equal log.action, 'db_create'
    assert_equal log.data, expected_data
    assert log.created_at >= invoice.created_at

    Invoice.configure_logging_options do |opts|
      opts[:log_user_activity_only] = true
      opts[:log_create_data] = false
    end
  end

  test "configure log_create_data=true will mostly copy the recod" do
    Invoice.configure_logging_options do |opts|
      opts[:log_create_data] = true
    end
    invoice = Invoice.create(**@new_invoice.merge(current_user: @user))
    log_fields = invoice.class.logging_options[:log_fields]
    log = invoice.application_record_logs.first
    log_data = invoice.attributes.slice(*log_fields).map do |k,v|
      [k, [nil, v]]
    end.to_h
    assert_equal log.record_type, 'Invoice'
    assert_equal log.record_id, invoice.id
    assert_equal log.user_id, @user.id
    assert_equal log.action, 'db_create'
    assert_equal log.data, log_data
    assert log.created_at >= invoice.created_at

    Invoice.configure_logging_options do |opts|
      opts[:log_create_data] = false
    end
  end

  test "changing log fields will change logged data" do
    Invoice.configure_logging_options do |opts|
      opts[:log_fields] = ['title']
      opts[:log_create_data] = true
    end
    invoice = Invoice.create(**@new_invoice.merge(current_user: @user))
    log = invoice.application_record_logs.first
    log_data = {'title' => [nil, @new_invoice[:title]]}
    assert_equal log.record_type, 'Invoice'
    assert_equal log.record_id, invoice.id
    assert_equal log.user_id, @user.id
    assert_equal log.action, 'db_create'
    assert_equal log.data, log_data
    assert log.created_at >= invoice.created_at

    Invoice.configure_logging_options do |opts|
      opts[:log_fields] = []
      opts[:log_create_data] = false
    end

    assert_equal Invoice.logging_options[:log_fields], @log_fields
  end

  test "updating logged fields will produce log" do
    @invoice.current_user = @user
    title_was = @invoice.title.dup
    date_was = @invoice.date.dup
    @invoice.title = "A completely new title"
    @invoice.date = Date.new(2020,2,28)
    log_data = {
      'title' => [title_was, "A completely new title"],
      'date' => [date_was, Date.new(2020,2,28)]
    }
    assert @invoice.save
    assert_equal @invoice.application_record_logs.count, 1
    log = @invoice.application_record_logs.first
    assert_equal log.data, log_data
    assert_equal log.data, @invoice.saved_changes.slice(*@log_fields)
    assert_equal log.action, 'db_update'
  end

  test "updating non logged fields will produce no log" do
    @invoice.current_user = @user
    count = @invoice.application_record_logs.count
    @invoice.body = "New un-logged contents"
    assert @invoice.save
    assert_equal @invoice.application_record_logs.count, count
  end

  test "destroying will produce a log" do
    @invoice.current_user = @user
    id = @invoice.id
    log_data = @invoice.attributes.slice(*@log_fields).map do |k,v|
      [k, [v, nil]]
    end.to_h
    count = @invoice.application_record_logs.count
    @invoice.destroy
    log = ApplicationRecordLog.where(record_id: id, record_type: 'Invoice').last
    assert_equal count+1, ApplicationRecordLog.where(record_id: id, record_type: 'Invoice').count
    assert_equal log.data, log_data
    assert_equal log.action, 'db_destroy'
  end
end
