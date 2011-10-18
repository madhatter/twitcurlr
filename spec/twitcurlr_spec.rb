require_relative '../lib/twitcurlr.rb'
require 'yaml'
require 'oauth'

describe Twitcurlr do
  auth = Hash.new
  auth_file = File.join(Dir.pwd, 'config', 'auth.yml')
  CONFIG = YAML.load_file(auth_file)

  auth['consumer_key'] = CONFIG['consumer_key']
  auth['consumer_secret'] = CONFIG['consumer_secret']
  auth['token'] = CONFIG['token']
  auth['token_secret'] = CONFIG['token_secret']

  before :each do
    @twitcurlr = Twitcurlr.new(auth)
  end

  it "should have one response from twitter" do
    twitcurlr = @twitcurlr
    response = twitcurlr.last_tweet
    response.should_not be_empty
  end
end

