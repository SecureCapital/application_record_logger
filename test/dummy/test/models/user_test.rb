require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    User.configure_logging_options do |opts|
      opts[:log_create_data] = true
      opts[:log_user_activity_only] = false
    end

    # Initial user
    base_user = {
      name:  "Name 0",
      email: "Email 0",
    }
    # Changes to user
    users = (1..4).map do |i|
      {
        name: base_user[:name][0..-2] + i.to_s,
        email: base_user[:email][0..-2] + i.to_s,
      }
    end
    # Create initial user
    @user_data = [base_user]+users
    @user = User.create(base_user)
    @record_id = @user.id
    @record_type = @user.class.name

    # Update the user 4 times
    users.each do |h|
      sleep(0.02)
      @user.assign_attributes(h)
      @user.save
    end
  end

  def log_count
    ApplicationRecordLog.where(record_id: @record_id, record_type: @record_type).count
  end

  test "has defualt logging_fields" do
    assert_equal User.logging_options[:log_fields], ["name", "email"]
  end

  test "five user logs exists on @user" do
    assert_equal @user.application_record_logs.size, 5
  end

  test "logging data has been composed" do
    logging_data = (0..4).map do |i|
      prev = if i == 0
        {}
      else
        @user_data[i-1]||{}
      end
      current = @user_data[i]
      {
        'name' => [prev[:name], current[:name]],
        'email' => [prev[:email], current[:email]],
      }
    end
    assert_equal @user.application_record_logs.map(&:data), logging_data
  end

  test "Rollback 0 steps returns current state" do
    # NOTE: do not use @user in rollback as this will modify the @user instance
    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      step: 0
    )
    assert_equal roll.slice('name','email'), {'name' => 'Name 4', 'email' => 'Email 4'}
    assert_equal roll.slice('name','email'), @user.slice('name','email')
  end

  test "Rollback 1 step returns previous state" do
    # NOTE: do not use @user in rollback as this will modify the @user instance
    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      step: 1
    )
    assert_equal roll.slice('name','email'), {'name' => 'Name 3', 'email' => 'Email 3'}
  end

  test "Rolback n returns to the n'th state" do
    (0..4).each do |step|
      expected = {
        'name' => "Name #{4-step}",
        'email' => "Email #{4-step}",
      }
      roll = ApplicationRecordLog.rollback(
        record_id: @record_id,
        record_type: @record_type,
        step: step
      )
      assert_equal roll.slice('name','email'), expected
    end
  end

  test "Rollback beyond ceate returns nil data" do
    [5,6].each do |step|
      expected = {
        'name' => nil,
        'email' => nil,
      }
      roll = ApplicationRecordLog.rollback(
        record_id: @record_id,
        record_type: @record_type,
        step: step
      )
      assert_equal roll.slice('name','email'), expected
    end
  end

  test "With log_create_data=false rollback to init returns init state" do
    # modify first log to hold data=nil, to act as log_create_data=false
    log = @user.application_record_logs.first
    log.data = nil
    log.save

    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      step: 4
    )
    assert_equal roll.slice('name','email'), {'name' => 'Name 0', 'email' => 'Email 0'}

    [5,6].each do |step|
      roll = ApplicationRecordLog.rollback(
        record_id: @record_id,
        record_type: @record_type,
        step: step
      )
      assert_equal roll.slice('name','email'), {'name' => nil, 'email' => nil}
    end
  end

  test "Destructed record can be rolled back" do
    @user.destroy
    assert_equal log_count, 6

    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      step: 0
    )
    assert_equal roll.slice('name','email'), {'name' => nil, 'email' => nil}

    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      step: 1
    )
    assert_equal roll.slice('name','email'), {'name' => 'Name 4', 'email' => 'Email 4'}

    roll.save
    assert_equal log_count, 7

    log = ApplicationRecordLog.where(
      record_id: @record_id,
      record_type: @record_type,
    ).last
    assert_equal log.action, 'db_create'
    assert_equal log.record_id, @record_id
    assert_equal log.data, {'name' => [nil, 'Name 4'], 'email' => [nil, 'Email 4']}
  end

  test "Rollback can take place with timepoints" do
    time_points = @user.application_record_logs.map(&:created_at)
    time_points.each_with_index do |tp, index|
      user = @user_data[index]
      roll = ApplicationRecordLog.rollback(
        record_id: @record_id,
        record_type: @record_type,
        timepoint: tp
      )
      assert_equal user.stringify_keys, roll.slice('name','email')
    end

    tp = time_points[0]-1.day
    roll = ApplicationRecordLog.rollback(
      record_id: @record_id,
      record_type: @record_type,
      timepoint: tp
    )
    user = {'name' => nil, 'email' => nil}
    assert_equal user, roll.slice('name','email')
  end
end
