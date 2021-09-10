require_relative "lib/application_record_logger/version"

Gem::Specification.new do |spec|
  spec.name        = "application_record_logger"
  spec.version     = ApplicationRecordLogger::VERSION
  spec.authors     = ["Mads Hofstedt Jaeger","Martin Hellerup Madsen"]
  spec.email       = ["mhh@securespectrum.dk","mhm@securespectrum.dk"]
  spec.homepage    = "https://github.com/securecapital/application_record_logger"
  spec.summary     = "For logging of changes to application records with
  after_create, after_update, after_destroy callbacks."
  spec.description = "A ApplicationRrecordLog instance will be created with
  callback after each of the actions create, update and destroy. The instance
  will store the saved_changes hash on the record. The log record is polymorphic
  owned be any application record including this module. Setting current_user to
  an instance before modifiyng it will flag the user comitting the action,
  allowing to blame users of malicious ussage."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage + '/tree/master/app'
  spec.metadata["changelog_uri"] = spec.homepage + '/changelog'

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.3", ">= 6.1.3.2"
end
