FROM ruby:3.1.2

RUN apt-get update -qq && apt-get install -qq libz-dev

WORKDIR /weather_api

COPY Gemfile /weather_api/Gemfile
COPY Gemfile.lock /weather_api/Gemfile.lock

RUN gem update bundler && bundle install

COPY . /weather_api/

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 9292

CMD ["bundle", "exec", "puma"]
