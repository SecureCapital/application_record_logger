module ApplicationRecordLogger
  module InstallMixin
    private
    def migration_path
      "#{::Rails.root}/db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end

    def migration_version
      "[#{::Rails::VERSION::MAJOR}.#{::Rails::VERSION::MINOR}]"
    end
  end
end
