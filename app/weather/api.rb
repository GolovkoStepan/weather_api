require 'grape'

require_relative '../../lib/application'

module Weather
  class API < Grape::API
    format :json

    rescue_from(:all) { |e| error!(json_error(e.message), 200) }

    helpers do
      def weather_data_service
        Application.services[:weather_data_service]
      end

      def cache_service
        Application.services[:cache_service]
      end

      def weather_current_data
        if (cached_data = cache_service.read_current_data)
          cached_data
        else
          weather_data_service.fetch_current_data.tap do |requested_data|
            cache_service.write_current_data(requested_data)
          end
        end
      end

      def weather_historical_data
        if (cached_data = cache_service.read_historical_data)
          cached_data
        else
          weather_data_service.fetch_historical_data.tap do |requested_data|
            cache_service.write_historical_data(requested_data)
          end
        end
      end

      def find_closest_timestamp(timestamp)
        timestamps = weather_historical_data[:items].keys
        return if timestamp.nil? || timestamp < timestamps.min || timestamp > timestamps.max

        timestamps.min do |candidate, next_value|
          (candidate - timestamp).abs <=> (next_value - timestamp).abs
        end
      end

      def json_response(data)
        { status: :ok, data: }
      end

      def json_ok(message)
        { status: :ok, message: }
      end

      def json_error(message)
        { status: :error, message: }
      end
    end

    desc 'Health check'
    get 'health' do
      json_ok('Service available')
    end

    resource 'weather' do
      desc 'Current temperature'
      get 'current' do
        json_response(value: weather_current_data.first[:value])
      end

      desc 'Temperature by timestamp'
      params { requires :timestamp, type: Integer, desc: 'Epoch Unix Timestamp' }
      get 'by_time' do
        if (target_timestamp = find_closest_timestamp(params[:timestamp]))
          json_response(value: weather_historical_data.dig(:items, target_timestamp))
        else
          json_error('not found')
        end
      end

      resource 'historical' do
        desc 'Temperature for last 24 hours'
        get do
          data = weather_historical_data[:items].map { |k, v| { timestamp: k, value: v } }
          json_response(data)
        end

        desc 'Max temperature for last 24 hours'
        get 'max' do
          json_response(value: weather_historical_data[:max])
        end

        desc 'Min temperature for last 24 hours'
        get 'min' do
          json_response(value: weather_historical_data[:min])
        end

        desc 'Avg temperature for last 24 hours'
        get 'avg' do
          json_response(value: weather_historical_data[:avg])
        end
      end
    end
  end
end
