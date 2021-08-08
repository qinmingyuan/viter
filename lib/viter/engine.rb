require 'rails_com/all'

module Viter
  class Engine < ::Rails::Engine
    # Allows Viter config values to be set via Rails env config files
    config.viter = ActiveSupport::OrderedOptions.new

    initializer 'viter.bootstrap' do
      if defined?(Rails::Server) || defined?(Rails::Console)
        Viter.bootstrap
        if defined?(Spring)
          require 'spring/watcher'
          Spring.after_fork { Viter.bootstrap }
          Spring.watch(Viter.config.config_path)
        end
      end
    end

  end
end
