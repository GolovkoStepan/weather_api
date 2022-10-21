require 'rest-client'
require 'json'

module Services
  class WeatherDataService
    attr_reader :configuration, :logger

    def initialize(configuration:, logger:)
      @configuration = configuration
      @logger = logger
    end

    def fetch_current_data
      make_request(build_current_data_uri)
    end

    def fetch_historical_data
      enrich_historical_data(make_request(build_historical_data_uri))
    end

    private

    def build_current_data_uri
      configuration[:current_data_uri] % configuration[:city_id]
    end

    def build_historical_data_uri
      configuration[:historical_data_uri] % configuration[:city_id]
    end

    def make_request(uri)
      response = RestClient.get(uri, { params: { apikey: configuration[:api_key] } })

      parse_json(response.body).tap do |data|
        logger.info("[WeatherDataService] Received data: #{data}")
      end
    end

    def parse_json(json)
      JSON.parse(json).map do |item|
        {
          timestamp: item['EpochTime'],
          value: item.dig('Temperature', 'Metric', 'Value')
        }
      end
    end

    def enrich_historical_data(data)
      values_by_timestamp = data.each_with_object({}) do |item, object|
        object[item[:timestamp]] = item[:value]
      end

      {
        items: values_by_timestamp,
        max: values_by_timestamp.values.max,
        min: values_by_timestamp.values.min,
        avg: (values_by_timestamp.values.sum(0.0) / values_by_timestamp.values.count).round(1)
      }
    end
  end
end
