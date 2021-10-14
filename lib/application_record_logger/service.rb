module ApplicationRecordLogger
  class Service
    attr_accessor :user, :user_id, :config, :action, :record, :record_id, :record_type

    def self.call(**kwargs, &block)
      new(**kwargs, &block).call
    end

    def user_id
      @user_id ||= user ? user.id : nil
    end

    def logs
      ::ApplicationRecordLog.where(record: record)
    end

    def record
      @record ||= record_klass.find(record_id)
    end

    def record_id
      @record_id ||= record.id
    end

    def record_type
      @record_type ||= record.class.name
    end

    def config
      @config ||= record_klass.logging_options
    end

    def record_klass
      record_type.constantize
    end
  end
end
