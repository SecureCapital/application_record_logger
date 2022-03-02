require "./test/test_helper"

class LogServiceCreateTest < ActiveSupport::TestCase
  setup do
    @klass   = ApplicationRecordLogger::LogService
    @invoice = Invoice.new(
      title: "New Incoice",
      body: "A long text that might be logged",
      price: 6,
      data: {hash: 'data', on: 'invoice'},
      date: '1970-01-01',
    )
    @user = User.create(
      name: 'Vodoo',
      email: 'not@a_mail.this',
    )
    @servant = @klass.new(
      record: @invoice,
      action: 'create',
    )
    @servant.config[:log_create_data] = false
  end

  test "it has config equal to invoice" do
    assert_equal @servant.config, Invoice.logging_options
  end

  test "it has produce_log? false when no user given" do
    assert_not @servant.produce_log?
  end

  test "it has produce_log? true when user given" do
    @servant.user = @user
    assert @servant.produce_log?
  end

  test "it has nil log_data" do
    assert_not @servant.log_data
  end

  test "it has create_log_data after config change" do
    @invoice.save
    @servant.config[:log_create_data] = true
    expected = {
      'title' => [nil,@invoice.title],
      'price' => [nil,@invoice.price],
      'date' => [nil,@invoice.date],
    }
    assert_equal @servant.log_data, expected
  end

  test "it can return data" do
    @servant.user = @user
    expected = {
      record: @invoice,
      user_id: @user.id,
      action: :db_create,
      data: nil
    }
    assert_equal @servant.data, expected
  end

  test "data reflects a valid ApplicationRecordLog" do
    @invoice.save
    rec = ApplicationRecordLog.create!(@servant.data)
    assert rec.valid?
  end

  test "data reflects a valid ApplicationRecordLog with user" do
    @invoice.save
    @servant.user = @user
    rec = ApplicationRecordLog.create!(@servant.data)
    assert rec.valid?
  end

  test "data reflects a valid ApplicationRecordLog with create-data" do
    @invoice.save
    @servant.config[:log_create_data] = true
    rec = ApplicationRecordLog.create!(@servant.data)
    assert rec.valid?
  end

  test "service can be called" do
    @invoice.save
    res = @klass.call(
      record: @invoice,
      user: @user,
      action: 'create',
    )
    assert res.valid?&&res.id&&res.persisted?
  end

  test "data is enhanced on multiple creations" do
    @invoice.save
    rec1 = @klass.call(record: @invoice, user: @user, action: 'create')
    @invoice.destroy
    new_invoice = Invoice.create(**@invoice.attributes.except('updated_at','created_at'))
    @servant.record = new_invoice
    assert @servant.db_create_record_exists?
    expected = {
      'title' => [nil,new_invoice.title],
      'price' => [nil,new_invoice.price],
      'date' => [nil,new_invoice.date],
    }
    assert_equal @servant.log_data, expected
  end
end
