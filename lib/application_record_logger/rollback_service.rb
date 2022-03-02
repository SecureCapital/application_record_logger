require_relative "service"

module ApplicationRecordLogger
  class RollbackService < Service
    attr_accessor :step, :timepoint

    def initialize(**kwargs, &block)
      super(**kwargs,&block)
      unless (@record_type&&@record_id)||(record)
        raise ArgumentError.new("Missing argument record, or record_id and record_type")
      end
      unless @timepoint || @step
        raise ArgumentError.new("Missing argument step or timepoint")
      end
      @record = record_klass.new(id: record_id) unless record
      @record.current_user = user if user && @record.respond_to?(:current_user)
    end

    def call
      rollback
      return record
    end

    def call!
      rollback
      if record.save
        set_rollback_log
        return [record, true]
      else
        return [record, false]
      end
    end

    def set_rollback_log
      if current_logs.size == logs.count
        # No further log has been produced, hence prodcue one
        LogService.call(
          record: record,
          action: action,
          user: user,
          user_id: user_id,
          config: config,
        )
      else
        # A log post has been produced, set action and user
        a_log = logs.last
        a_log.user_id = user_id
        a_log.action = action
        a_log.save
      end
    end

    def rollback
      current_logs.each do |log|
        (log.data || nil_data).each do |key, arr|
          record.send("#{key}=", arr[0])
        end
      end
    end

    def current_logs
      if step
        step_logs
      else
        timepoint_logs
      end
    end

    def step_logs
      @step_logs ||= ::ApplicationRecordLog.where(
        record: record,
      ).order(:created_at => :desc).limit(step).to_a
    end

    def timepoint_logs
      @timepoint_logs ||= ::ApplicationRecordLog.where(
        record: record
      ).where(
        "`created_at` > ?", timepoint
      ).order(:created_at => :desc).to_a
    end

    def action
      @action ||= 'rollback'
    end

    def nil_data
      @nil_data ||= config[:log_fields].map{|key| [key,[nil,nil]]}.to_h
    end
  end
end
