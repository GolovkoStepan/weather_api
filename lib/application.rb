require 'singleton'
require 'forwardable'
require 'config'

require_relative 'services/weather_data_service'
require_relative 'services/cache_service'

class Application
  include Singleton

  class << self
    extend Forwardable
    delegate %i[root env config logger services] => :instance
  end

  def root
    @root ||= File.expand_path('..', __dir__)
  end

  def env
    @env ||= ENV.fetch('APP_ENV', 'development')
  end

  def logger
    @logger ||= Logger.new($stdout)
  end

  def services
    @services ||= {
      weather_data_service: Services::WeatherDataService.new(configuration: config.weather_data_service.to_h, logger:),
      cache_service: Services::CacheService.new(configuration: config.cache_service.to_h, logger:)
    }
  end

  def config
    @config ||= Config.tap do |config|
      config.fail_on_missing = true
    end.load_files(
      Config.setting_files(File.join(root, 'config'), env)
    )
  end
end
