require 'redis'

require_relative '../../../lib/application'
require_relative '../../../lib/services/cache_service'

RSpec.describe Services::CacheService do
  subject(:service) do
    described_class.new(
      configuration: Application.config.cache_service.to_h,
      logger: Application.logger
    )
  end

  let(:redis_instance) { instance_double(Redis) }

  before do
    allow(Redis).to receive(:new)
      .with(Application.config.cache_service.redis.to_h)
      .and_return(redis_instance)
  end

  describe '#read_current_data' do
    let(:result) { { a: 1, b: 2 } }
    let(:redis_result) { JSON.generate(result) }

    before do
      allow(redis_instance).to receive(:get)
        .with(Application.config.cache_service.key_prefix % 'current')
        .and_return(redis_result)
    end

    it 'returns value by key from redis' do
      expect(service.read_current_data).to eq(result)
    end
  end

  describe '#read_historical_data' do
    let(:result) { { c: 3, d: 4 } }
    let(:redis_result) { JSON.generate(result) }

    before do
      allow(redis_instance).to receive(:get)
        .with(Application.config.cache_service.key_prefix % 'historical')
        .and_return(redis_result)
    end

    it 'returns value by key from redis' do
      expect(service.read_historical_data).to eq(result)
    end
  end

  describe '#write_current_data' do
    let(:data) { { a: 1, b: 2 } }
    let(:json_data) { JSON.generate(data) }

    before do
      allow(redis_instance).to receive(:setex)
        .with(
          (Application.config.cache_service.key_prefix % 'current'),
          Application.config.cache_service.ttl,
          json_data
        )
        .and_return('OK')
    end

    it 'writes value to redis with ttl' do
      expect(service.write_current_data(data)).to eq('OK')
    end
  end

  describe '#write_historical_data' do
    let(:data) { { c: 3, d: 4 } }
    let(:json_data) { JSON.generate(data) }

    before do
      allow(redis_instance).to receive(:setex)
        .with(
          (Application.config.cache_service.key_prefix % 'historical'),
          Application.config.cache_service.ttl,
          json_data
        )
        .and_return('OK')
    end

    it 'writes value to redis with ttl' do
      expect(service.write_historical_data(data)).to eq('OK')
    end
  end

  describe '#reset!' do
    before do
      allow(redis_instance).to receive(:del)
        .with(
          (Application.config.cache_service.key_prefix % 'current'),
          (Application.config.cache_service.key_prefix % 'historical')
        )
        .and_return(1)
    end

    it 'deletes all values' do
      expect(service.reset!).to eq(1)
    end
  end
end
