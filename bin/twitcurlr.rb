#!/usr/bin/env ruby

require 'daemons'
require 'eventmachine'
require 'yaml'
require 'oauth'
require 'logger'
require_relative '../lib/twitcurlr.rb'

begin
  auth = {}
  auth_file = File.join(Dir.pwd, 'config', 'auth.yml')
  CONFIG = YAML.load_file(auth_file)

  auth['consumer_key'] = CONFIG['consumer_key']
  auth['consumer_secret'] = CONFIG['consumer_secret']
  auth['token'] = CONFIG['token']
  auth['token_secret'] = CONFIG['token_secret']

  # TODO if not authorized yet... this has to be somewhere else
  unless auth['token'] && auth['token_secret']
      consumer = OAuth::Consumer.new auth['consumer_key'],
				     auth['consumer_secret'],
				     { :site => 'https://api.twitter.com',
				       :request_token_path => '/oauth/request_token',
				       :authorize_path => '/oauth/authorize',
				       :access_token_path => '/oauth/access_token'}

      request_token = consumer.get_request_token
       
      puts "Visit the following URL, log in if you need to, and authorize the app"
      puts request_token.authorize_url
      puts "When you've authorized that token, enter the verifier code you are assigned:"
      verifier = gets.strip
      puts "Converting request token into access token..."
      access_token=request_token.get_access_token(:oauth_verifier => verifier)
       
      auth['token'] = access_token.token
      auth['token_secret'] = access_token.secret

      #store the auth information
      puts "Storing authentication information for future usage..."
      File.open(auth_file, 'w') {|f| YAML.dump(auth, f)}
  end
  # load configuration file
  config_file = File.join(Dir.pwd, 'config', 'twitcurlr.yml')
  CONFIG = YAML.load_file(config_file)

  LOGLEVEL = CONFIG['loglevel'] || Logger::INFO
  @twitcurlr = Twitcurlr.new(auth)
rescue SystemCallError
  $stderr.puts "What did you do!?!"
  exit(1)
end

Daemons.run_proc('twitcurlr', :dir_mode => :script, :dir => './', \
                 :backtrace => true, :log_output => true) do
  @log = Logger.new(STDOUT)
  @log.info "starting twitcurlr daemon..." 
  @log.info "creating a new twitcurlr instance using this config: \n#{CONFIG.inspect}"

  EventMachine::run {
    EventMachine::add_periodic_timer(60) {
      @log.info "curling..."
      results = @twitcurlr.last_tweet
      if results
        results.each do |tweet|
          @log.info tweet
        end
      else
        @log.info "It's log, it's log, \
        It's big, it's heavy, it's wood. \
        It's log, it's log, it's better than bad, it's good.\n"
      end
    }
  }
end

