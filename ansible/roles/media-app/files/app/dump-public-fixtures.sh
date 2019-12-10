#!/bin/bash
set -e

cd $HOME/media-site/current/
. $HOME/.rvm/scripts/rvm

mkdir -p tmp/fixtures

export RAILS_ENV="production"
bundle exec rake db:fixtures:dump FIXTURES_PATH=tmp/fixtures

tar --exclude admin_users.yml \
  --exclude active_admin_comments.yml \
  --exclude api_keys.yml \
  -cz -f public/system/voctoweb.dump.tar.gz tmp/fixtures/
rm -fr tmp/fixtures
