require "rack-timeout"
use Rack::Timeout, service_timeout: 20

require './app'
# require 'newrelic_rpm'

run App
