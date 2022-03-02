module ApplicationRecordLogger
  module ActionParser
    def parse_action(value)
      case value
      when /create/i  then :db_create
      when /update/i  then :db_update
      when /destroy/i then :db_destroy
      when /delete/i then :db_destroy
      when /rollback/i then :rollback
      else
        value
      end
    end
  end
end
