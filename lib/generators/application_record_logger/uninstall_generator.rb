# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'install_mixin.rb'

module ApplicationRecordLogger
  class UninstallGenerator < Rails::Generators::Base
    include InstallMixin
    desc "Uninstalling application_record_logs: adds migration to remove application_record_logs table"
    source_root File.expand_path("../templates/", __FILE__)

    def create_migration
      template 'uninstall_migration.rb', "#{migration_path}_drop_application_record_logs.rb", migration_version: migration_version
    end

    def print_status
      puts %Q(Uninstall migration created. Remember to remove 'apllication_record_logs' from gemfile, any configuration, and all implementations in your models.)
    end
  end
end
