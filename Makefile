.PHONY: check
check: rubocop security bundle-audit rspec

.PHONY: bundle_install
bundle_install:
	bundle install

.PHONY: console
console:
	bundle exec bin/console

.PHONY: rubocop
rubocop:
	bundle exec rubocop

.PHONY: security
security:
	bundle exec brakeman --no-pager

.PHONY: bundle-audit
bundle-audit:
	bundle exec bundle-audit check --update

.PHONY: rspec
rspec:
	APP_ENV=test bundle exec rspec

.PHONY: rspec
server:
	bundle exec puma

.PHONY: docker_start
docker_start:
	docker-compose -f docker-compose.yml up --abort-on-container-exit --exit-code-from api

.PHONY: docker_stop
docker_stop:
	docker-compose -f docker-compose.yml down --remove-orphans --volumes
