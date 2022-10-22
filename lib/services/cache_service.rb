require 'redis'
require 'json'

module Services
  class CacheService
    attr_reader :configuration, :logger

    def initialize(configuration:, logger:)
      @configuration = configuration
      @logger = logger
    end

    def read_current_data
      read_from_redis('current')
    end

    def read_historical_data
      read_from_redis('historical').tap do |data|
        data[:items]&.transform_keys! { |key| key.to_s.to_i } if data
      end
    end

    def write_current_data(data)
      write_to_redis('current', data)
    end

    def write_historical_data(data)
      write_to_redis('historical', data)
    end

    def reset!
      logger.info('[CacheService] Clear cache')
      redis.del(full_key_name('current'), full_key_name('historical'))
    end

    private

    def read_from_redis(key)
      data = redis.get(full_key_name(key))
      logger.info("[CacheService] Read from redis. Key: #{key}, data: #{data}")
      data ? JSON.parse(data, symbolize_names: true) : nil
    end

    def write_to_redis(key, data)
      logger.info("[CacheService] Write to redis. Key: #{key}, data: #{data}")
      redis.setex(full_key_name(key), ttl, JSON.generate(data))
    end

    def redis
      @redis ||= Redis.new(**configuration[:redis])
    end

    def full_key_name(key)
      configuration[:key_prefix] % key
    end

    def ttl
      configuration[:ttl]
    end
  end
end
