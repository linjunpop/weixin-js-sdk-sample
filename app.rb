require 'bundler/setup'

GC::Profiler.enable

require 'dotenv'
Dotenv.load

require 'securerandom'

require 'rollbar/middleware/sinatra'
require 'sinatra/base'

require 'weixin_js_sdk'
require 'dalli'

class App < Sinatra::Base
  use Rollbar::Middleware::Sinatra

  configure do
    Rollbar.configure do |config|
      if Sinatra::Base.environment == :development
        config.enabled = false
      end

      config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
      config.environment = Sinatra::Base.environment
      config.framework = "Sinatra: #{Sinatra::VERSION}"
      config.root = Dir.pwd

      config.exception_level_filters.merge!('Sinatra::NotFound' => 'ignore')
    end

    $cache = Dalli::Client.new(
      (ENV["MEMCACHIER_SERVERS"] || "").split(","),
      {
        :username => ENV["MEMCACHIER_USERNAME"],
        :password => ENV["MEMCACHIER_PASSWORD"],
        :failover => true,
        :socket_timeout => 1.5,
        :socket_failure_delay => 0.2,
        :expires_in => 6900
      }
    )
  end

  not_found do
    'This is nowhere to be found.'
  end

  get '/' do
    @timestamp = Time.now.to_i
    @nonce_str = SecureRandom.hex
    @signature = generate_signature(
      nonce_str: @nonce_str.to_s,
      timestamp: @timestamp.to_s,
      url: url('/')
    )
    erb :index
  end

  post '/signature' do
    content_type 'application/json'

    json = JSON.parse(request.body.read, symbolize_names: true)

    signature = generate_signature(
      nonce_str: json[:nonce_str],
      timestamp: json[:timestamp],
      url: json[:url]
    )

    { signature: signature }.to_json
  end

  private

  def generate_signature(nonce_str:, timestamp:, url:)
    WeixinJsSDK::Signature.new(
      ticket: ticket,
      nonce_str: nonce_str,
      timestamp: timestamp,
      url: url
    ).sign
  end

  def ticket
    if cached_ticket = $cache.get('ticket')
      return cached_ticket
    end

    access_token = WeixinJsSDK::AccessToken.new(
      app_id: ENV['WEIXIN_APP_ID'],
      app_secret: ENV['WEIXIN_APP_SECRET']
    ).fetch

    ticket = WeixinJsSDK::Ticket.new(access_token: access_token).fetch
    $cache.set('ticket', ticket)
  end
end
