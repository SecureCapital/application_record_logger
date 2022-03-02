require "./test/test_helper"

class LogServiceUpdateTest < ActiveSupport::TestCase
  setup do
    @klass   = ApplicationRecordLogger::LogService
    @invoice = Invoice.create(
      title: "New Invoice",
      body: "A long text that might be logged",
      price: 6,
      data: {hash: 'data', on: 'invoice'},
      date: '1970-01-01',
    )
    @invoice.reload
    @change = {'title' => ['New Invoice', 'New title']}
    @user = User.create(
      name: 'Vodoo',
      email: 'not@a_mail.this',
    )
    @servant = @klass.new(
      user: @user,
      record: @invoice,
      action: 'update',
    )
  end

  def change_invoice!
    @invoice.title = "New title"
    @invoice.save!
  end

  test "it has produce_log? false " do
    assert_not @servant.produce_log?
  end

  test "it has produce_log? false before save" do
    @invoice.title = "New title"
    assert_not @servant.produce_log?
  end

  test "it has produce_log? true after save" do
    change_invoice!
    assert @servant.produce_log?
  end

  test "it has empty log_data before save" do
    assert @servant.log_data.empty?
  end

  test "it has log_data to saved changes" do
    change_invoice!
    assert @servant.log_data, @change
  end

  test "it can return data" do
    change_invoice!
    expected = {
      record: @invoice,
      user_id: @user.id,
      action: :db_update,
      data: @change
    }
    assert_equal @servant.data, expected
  end

  test "data reflects a valid ApplicationRecordLog" do
    change_invoice!
    rec = ApplicationRecordLog.create!(@servant.data)
    assert rec.valid?
  end

  test "service can be called" do
    change_invoice!
    res = ApplicationRecordLogger::LogService.call(
      record: @invoice,
      user: @user,
      action: 'update',
    )
    assert res.valid?&&res.id&&res.persisted?
  end
end
