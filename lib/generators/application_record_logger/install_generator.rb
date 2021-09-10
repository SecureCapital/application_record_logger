# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'install_mixin.rb'

module ApplicationRecordLogger
  class InstallGenerator < Rails::Generators::Base
    include InstallMixin
    desc 'Installing ApplicationRecordLogger: creates table  application_record_logs.'
    source_root File.expand_path("../templates/", __FILE__)

    def create_migration
      template 'install_migration.rb', "#{migration_path}_create_application_record_logs.rb", migration_version: migration_version
    end

    def print_status
      puts "Created install migration. Run `rails db:migrate` to install the table `application_record_logs`."
    end
  end
end
