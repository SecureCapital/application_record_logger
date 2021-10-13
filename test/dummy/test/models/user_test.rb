require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has defualt logging_fields" do
    assert_equal User.logging_options[:log_fields], ["name", "email"]
  end
end
