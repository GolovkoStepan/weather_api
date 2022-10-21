.PHONY: check
check: rubocop rspec

.PHONY: bundle_install
bundle_install:
	bundle install

.PHONY: console
console:
	bundle exec bin/console

.PHONY: rubocop
rubocop:
	bundle exec rubocop

.PHONY: rspec
rspec:
	APP_ENV=test bundle exec rspec

.PHONY: rspec
server:
	bundle exec puma

.PHONY: docker_start
docker_start:
	docker-compose up

.PHONY: docker_stop
docker_stop:
	docker-compose down --remove-orphans
