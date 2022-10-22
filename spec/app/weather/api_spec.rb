require_relative '../../support/api_tests_helper'
require_relative '../../../app/weather/api'
require_relative '../../../lib/application'
require_relative '../../../lib/services/cache_service'
require_relative '../../../lib/services/weather_data_service'

describe Weather::API do
  include Rack::Test::Methods
  include ApiTestsHelper

  let(:cache_serivice_instance) { instance_double(Services::CacheService) }
  let(:weather_data_service_instance) { instance_double(Services::WeatherDataService) }

  let(:current_data) { [{ timestamp: 1_666_356_780, value: 6.1 }] }
  let(:historical_data) do
    {
      items: {
        1_666_356_780 => 2,
        1_666_359_780 => 4
      },
      max: 4,
      min: 2,
      avg: 3
    }
  end

  def app
    Application.api
  end

  describe 'GET /health' do
    it 'returns status ok json response' do
      get '/health'

      expect_http_status_ok
      expect_json_ok_response
      expect_json_payload_have('message' => 'Service available')
    end
  end

  RSpec.shared_examples 'api tests' do
    describe 'GET /weather/current' do
      it 'returns status ok json response' do
        get '/weather/current'

        expect_http_status_ok
        expect_json_ok_response
        expect_json_payload_have({ 'data' => { 'value' => 6.1 } })
      end
    end

    describe 'GET /weather/by_time' do
      context 'when closest timestamp is found' do
        it 'returns status ok json response' do
          get '/weather/by_time', {}, query_params: { timestamp: 1_666_356_780 }

          expect_http_status_ok
          expect_json_ok_response
          expect_json_payload_have({ 'data' => { 'value' => 2 } })
        end
      end

      context 'when closest timestamp is not found' do
        it 'returns status error json response' do
          get '/weather/by_time', {}, query_params: { timestamp: 1 }

          expect_http_status_ok
          expect_json_error_response
          expect_json_payload_have({ 'message' => 'not found' })
        end
      end

      context 'when timestamp param is not received' do
        it 'returns status error json response' do
          get '/weather/by_time'

          expect_http_status_ok
          expect_json_error_response
          expect_json_payload_have({ 'message' => 'timestamp is missing' })
        end
      end
    end

    describe 'GET /weather/historical' do
      it 'returns status ok json response' do
        get '/weather/historical'

        expect_http_status_ok
        expect_json_ok_response
        expect_json_payload_have(
          {
            'data' => [{ 'timestamp' => 1_666_356_780, 'value' => 2 },
                       { 'timestamp' => 1_666_359_780, 'value' => 4 }]
          }
        )
      end
    end

    describe 'GET /weather/historical/max' do
      it 'returns status ok json response' do
        get '/weather/historical/max'

        expect_http_status_ok
        expect_json_ok_response
        expect_json_payload_have({ 'data' => { 'value' => 4 } })
      end
    end

    describe 'GET /weather/historical/min' do
      it 'returns status ok json response' do
        get '/weather/historical/min'

        expect_http_status_ok
        expect_json_ok_response
        expect_json_payload_have({ 'data' => { 'value' => 2 } })
      end
    end

    describe 'GET /weather/historical/avg' do
      it 'returns status ok json response' do
        get '/weather/historical/avg'

        expect_http_status_ok
        expect_json_ok_response
        expect_json_payload_have({ 'data' => { 'value' => 3 } })
      end
    end
  end

  context 'when cached data present' do
    before do
      allow(Application.services).to receive(:[]).with(:cache_service).and_return(cache_serivice_instance)
      allow(cache_serivice_instance).to receive(:read_current_data).and_return(current_data)
      allow(cache_serivice_instance).to receive(:read_historical_data).and_return(historical_data)
    end

    include_examples 'api tests'
  end

  context 'when cache is empty' do
    before do
      allow(Application.services).to receive(:[]).with(:weather_data_service).and_return(weather_data_service_instance)
      allow(weather_data_service_instance).to receive(:fetch_current_data).and_return(current_data)
      allow(weather_data_service_instance).to receive(:fetch_historical_data).and_return(historical_data)

      allow(Application.services).to receive(:[]).with(:cache_service).and_return(cache_serivice_instance)
      allow(cache_serivice_instance).to receive(:read_current_data).and_return(nil)
      allow(cache_serivice_instance).to receive(:read_historical_data).and_return(nil)
      allow(cache_serivice_instance).to receive(:write_current_data).with(current_data).and_return(nil)
      allow(cache_serivice_instance).to receive(:write_historical_data).with(historical_data).and_return(nil)
    end

    include_examples 'api tests'
  end
end
