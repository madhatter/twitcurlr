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
    hashtags = %w{#foo #bar #woot}
    @twitcurlr = Twitcurlr.new(auth, hashtags)
  end

  it "should have one response from twitter" do
    twitcurlr = @twitcurlr
    response = twitcurlr.last_tweet
    response.should_not be_empty
  end

  it "should match and return one tweet" do
    twitcurlr = @twitcurlr
    response = twitcurlr.search_for_tags("Testing twitcurlr #woot")
    response.should_not be_empty
  end

  it "should not match when tweet contains no tag" do
    twitcurlr = @twitcurlr
    response = twitcurlr.search_for_tags("Testing twitcurlr, no woot")
    response.should be_nil
  end
end

