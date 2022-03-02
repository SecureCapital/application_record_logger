require "./test/test_helper"

class ApplicationRecordLogTest < ActiveSupport::TestCase
  setup do
    @klass = ApplicationRecordLog
    @arl = ApplicationRecordLog.new
  end

  test "has correct attributes" do
    attrs = @klass.column_names
    expected = %w(id record_type record_id user_id action data created_at updated_at)
    assert_equal (attrs & expected).size, expected.size
  end

  test "is configured not to log self" do
    array = [
      @klass.log_create,
      @klass.log_update,
      @klass.log_destroy,
    ]
    assert_equal array, [false]*3
  end

  test "action setter interprets strings" do
    values = {
      'db_create'  => ['create',:create,:db_create,'CREATE','db_create'],
      'db_update'  => ['update',:update,:db_update,'UPDATE','db_update'],
      'db_destroy' => ['destroy',:destroy,:db_destroy,'DESTROY','db_destroy','delete',:delete,'DelEte'],
      'rollback'  => ['rollback',:rollback,:db_rollback,'ROLLBACK'],
      nil => [nil],
    }
    results = values.map do |expected, items|
      items.map do |value|
        @arl.action = value
        @arl.action == expected
      end
    end.flatten
    assert results.all?
  end

  test "action setter cannot be set to none enum values" do
    assert_raise(ArgumentError) do
      @arl.action = 'UNDEFIEND ACTION'
    end
  end

  test "it must have an action, record_id, and record_type" do
    @arl.valid?
    types = %i(action record_id record_type).map do |attr|
      err = @arl.errors.find{|err| err.attribute == attr}
      err ||= OpenStruct.new
      err.type
    end
    assert types.all?{|typ| typ==:blank}
  end

  test "It can have a records that does not exist" do
    @arl.record_type = 'Invoice'
    @arl.record_id = -1
    assert_equal @arl.record, nil
  end

  test "It has class methods log, rollback, and rollback!" do
    assert %i(log rollback rollback!).all? do |meth|
      @klass.respond_to meth
    end
  end
end
