require "./test/test_helper"

class ApplicationRecordLogTest < ActiveSupport::TestCase
  test "has correct attributes" do
    attrs = ApplicationRecordLog.column_names
    expected = %w(id record_type record_id user_id action data created_at updated_at)
    assert_equal (attrs & expected).size, expected.size
  end
end
