require "./test/test_helper"
require_relative 'app_record_mock'

class ServiceTest < ActiveSupport::TestCase
  setup do
    @klass   = ApplicationRecordLogger::Service
    @servant = ApplicationRecordLogger::Service.new
    @test_record = AppRecordMock.new(id: 1, name: 'No name')
    @user = User.new(id: -1)
  end

  test "it has accessor reflecting ApplicationRecordLog" do
    meths = ApplicationRecordLog.column_names - %w(id data created_at updated_at)
    meths << :user
    meths << :record
    meths << :config
    meths += meths.map{|meth| "#{meth}="}
    assert meths.all?{|meth| @servant.respond_to?(meth)}
  end

  test "it can take record_id from record" do

    @servant.record = @test_record
    assert @servant.record_id == @test_record.id
  end

  test "it can take record_type form record" do
    @servant.record = @test_record
    assert @servant.record_type == 'AppRecordMock'
  end

  test "it will take config from record if none given" do
    @servant.record = @test_record
    assert @servant.config == AppRecordMock.logging_options
  end

  test "it will find record when given id and type" do
    @servant.record_id = 1
    @servant.record_type = 'AppRecordMock'
    assert @servant.record == @test_record
  end

  test "it will not find record if it does not exist" do
    @servant.record_id = 2
    @servant.record_type = 'AppRecordMock'
    assert @servant.find_record.nil?
  end

  test "it will raise an error if record_type is no constant" do
    @servant.record_type = 'UndefinedConstant'
    assert_raise(NameError) do
      @servant.recored_klass
    end
  end

  test "it will take user_id from user" do
    @servant.user = @user
    assert @servant.user_id == @user.id
  end

  test "it will list all application record_logs" do
    @servant.record_id = -3
    @servant.record_type = 'UndefinedClass'
    sql = @servant.logs.to_sql
    assert [
      (sql =~ /SELECT/) == 0,
      ((sql =~ /FROM .application_record_logs./)||0) > 0,
      ((sql =~ /WHERE .application_record_logs.\..record_id. = -3/)||0) > 0,
      ((sql =~ /AND .application_record_logs.\..record_type. = 'UndefinedClass'/)||0) > 0,
    ].all?
  end
end
