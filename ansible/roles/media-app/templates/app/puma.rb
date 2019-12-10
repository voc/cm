#!/usr/bin/env puma

directory '/srv/media/media-site/current'
rackup "/srv/media/media-site/current/config.ru"
environment 'production'

# systemd requires process not to detach
daemonize       false

pidfile "/srv/media/media-site/shared/tmp/pids/puma.pid"
state_path "/srv/media/media-site/shared/tmp/pids/puma.state"
stdout_redirect '/srv/media/media-site/current/log/puma.error.log', '/srv/media/media-site/current/log/puma.access.log', true


bind 'unix:///srv/media/media-site/shared/tmp/sockets/media-site-puma.sock'
bind 'tcp://{{ puma_listen }}'

preload_app!
# 6, 8
workers {{ puma_workers }}
threads {{ puma_threads }}

on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = "/srv/media/media-site/current/Gemfile"
end

before_fork do
  require 'puma_worker_killer'
  PumaWorkerKiller.config do |config|
    config.ram           = {{ puma_max_mem }} # mb
    config.frequency     = 30     # seconds
    config.percent_usage = 0.95
    config.rolling_restart_frequency = false
  end
  PumaWorkerKiller.start
end
