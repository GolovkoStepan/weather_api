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
