require_relative '../../../lib/application'
require_relative '../../../lib/services/weather_data_service'

RSpec.describe Services::WeatherDataService do
  subject(:service) do
    described_class.new(
      configuration: Application.config.weather_data_service.to_h,
      logger: Application.logger
    )
  end

  before { WebMock.disable_net_connect! }

  after { WebMock.allow_net_connect! }

  describe '#fetch_current_data' do
    let(:response_body) do
      <<~TEXT
        [
          {
            "LocalObservationDateTime": "2022-10-21T15:53:00+03:00",
            "EpochTime": 1666356780,
            "WeatherText": "Cloudy",
            "WeatherIcon": 7,
            "HasPrecipitation": false,
            "PrecipitationType": null,
            "IsDayTime": true,
            "Temperature": {
              "Metric": {
                "Value": 6.1,
                "Unit": "C",
                "UnitType": 17
              },
              "Imperial": {
                "Value": 43.0,
                "Unit": "F",
                "UnitType": 18
              }
            },
            "MobileLink": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us",
            "Link": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us"
          }
        ]
      TEXT
    end

    let(:result) { [{ timestamp: 1_666_356_780, value: 6.1 }] }

    before do
      stub_request(:get, 'https://test.com/weather/1')
        .with(query: { 'apikey' => 'api_key' })
        .to_return(status: 200, body: response_body)
    end

    it 'make request and return data' do
      expect(service.fetch_current_data).to eq(result)
    end
  end

  describe '#fetch_historical_data' do
    let(:response_body) do
      <<~TEXT
        [
          {
            "LocalObservationDateTime": "2022-10-21T15:53:00+03:00",
            "EpochTime": 1666356780,
            "WeatherText": "Cloudy",
            "WeatherIcon": 7,
            "HasPrecipitation": false,
            "PrecipitationType": null,
            "IsDayTime": true,
            "Temperature": {
              "Metric": {
                "Value": 2,
                "Unit": "C",
                "UnitType": 17
              },
              "Imperial": {
                "Value": 43.0,
                "Unit": "F",
                "UnitType": 18
              }
            },
            "MobileLink": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us",
            "Link": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us"
          },
          {
            "LocalObservationDateTime": "2022-10-21T15:53:00+03:00",
            "EpochTime": 1666356781,
            "WeatherText": "Cloudy",
            "WeatherIcon": 7,
            "HasPrecipitation": false,
            "PrecipitationType": null,
            "IsDayTime": true,
            "Temperature": {
              "Metric": {
                "Value": 4,
                "Unit": "C",
                "UnitType": 17
              },
              "Imperial": {
                "Value": 43.0,
                "Unit": "F",
                "UnitType": 18
              }
            },
            "MobileLink": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us",
            "Link": "http://www.accuweather.com/en/ru/moscow/294021/current-weather/294021?lang=en-us"
          }
        ]
      TEXT
    end

    let(:result) do
      {
        items: { 1_666_356_780 => 2, 1_666_356_781 => 4 },
        max: 4,
        min: 2,
        avg: 3
      }
    end

    before do
      stub_request(:get, 'https://test.com/weather/1/historical/24')
        .with(query: { 'apikey' => 'api_key' })
        .to_return(status: 200, body: response_body)
    end

    it 'make request and return data' do
      expect(service.fetch_historical_data).to eq(result)
    end
  end
end
