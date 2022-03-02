module ApplicationRecordLogger
  class Service
    include ActionParser
    attr_accessor :user, :user_id, :config, :action

    def initialize(**kwargs, &block)
      kwargs.each do |key, value|
        send("#{key}=", value) if respond_to? "#{key}="
      end
      yield self if block_given?
    end

    def self.call(**kwargs, &block)
      new(**kwargs, &block).call
    end

    def user_id
      @user_id ||= user ? user.id : nil
    end

    def logs
      ::ApplicationRecordLog.where(record_id: record_id, record_type: record_type)
    end

    def action=(value)
      @action = parse_action(value)
    end

    def record
      @record ||= find_record
    end

    def record=(rec)
      @record_id = rec.id
      @record_type = rec.class.name
      @record = rec
    end

    def record_id
      @record_id ||= record ? record.id : nil
    end

    def record_id=(id)
      @record = nil
      @record_id = id
    end

    def record_type
      @record_type ||= record ? record.class.name : nil
    end

    def record_type=(type)
      @record = nil
      @record_type = type.to_s
    end

    def config
      @config ||= record_klass.logging_options
    end

    def record_klass
      record_type.constantize
    end

    def find_record
      record_klass.find_by(id: record_id) if record_type && record_id
    end
  end
end
