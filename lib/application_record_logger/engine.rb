module ApplicationRecordLogger
  class Engine < ::Rails::Engine
    isolate_namespace ApplicationRecordLogger
    config.generators.api_only = true
  end
end
