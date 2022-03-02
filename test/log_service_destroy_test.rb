require "./test/test_helper"

class LogServiceDestroyTest < ActiveSupport::TestCase
  setup do
    @klass   = ApplicationRecordLogger::LogService
    @invoice = Invoice.create(
      title: "New Incoice",
      body: "A long text that might be logged",
      price: 6,
      data: {hash: 'data', on: 'invoice'},
      date: '1970-01-01',
    )
    @invoice.reload
    @user = User.create(
      name: 'Vodoo',
      email: 'not@a_mail.this',
    )
    @servant = @klass.new(
      record: @invoice,
      action: 'destroy',
      user: @user,
    )
    @log_data = {
      'title' => [@invoice.title, nil],
      'price' => [@invoice.price, nil],
      'date' => [@invoice.date, nil],
    }
  end

  test "it has produce_log? false when not destroyed" do
    assert_not @servant.produce_log?
  end

  test "it has produce_log? true when destroyed" do
    @invoice.destroy
    assert @servant.produce_log?
  end

  test "it has full log_data" do
    assert_equal @servant.log_data, @log_data
  end

  test "it can return data" do
    expected = {
      record: @invoice,
      user_id: @user.id,
      action: :db_destroy,
      data: @log_data
    }
    assert_equal @servant.data, expected
  end

  test "data reflects a valid ApplicationRecordLog" do
    @invoice.destroy
    rec = ApplicationRecordLog.create!(@servant.data)
    assert rec.valid?
  end

  test "service can be called" do
    @invoice.destroy
    res = ApplicationRecordLogger::LogService.call(
      record: @invoice,
      user: @user,
      action: 'destroy',
    )
    assert res.valid?&&res.id&&res.persisted?
  end
end
