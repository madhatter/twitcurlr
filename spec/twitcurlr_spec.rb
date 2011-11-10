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

  it "should ignore the case when matching tags" do
    twitcurlr = @twitcurlr
    response = twitcurlr.search_for_tags("Uppercase FTW. #WOOT.")
    response.should_not be_empty
  end

  it "should match strings when I tell him to" do
    twitcurl = Twitcurlr.new(auth, %w{foo bar woot})
    response = twitcurl.search_for_tags("I want more food.")
    response.should_not be_empty
  end

  it "should extract an URL from a string (tweet)" do
    twitcurlr = @twitcurlr
    response = twitcurlr.extract_url_from_tweet("Follow the link http://bit.to/bla12fasel #lnk")
    response.should == 'http://bit.to/bla12fasel'
  end

  it "should extract an URL when it's the last word" do
    twitcurlr = @twitcurlr
    response = twitcurlr.extract_url_from_tweet("Follow the link http://img.ly/crap2l")
    response.should == 'http://img.ly/crap2l'
  end

  it "should get the header for the given short url" do
    twitcurlr = @twitcurlr
    response = twitcurlr.get_redirect_link("http://twitpic.com/show/full/76ktj4")
    response.should_not be_empty
  end

  it "should work when called twice for a t.co url" do
    twitcurlr = @twitcurlr
    response = twitcurlr.get_tco_image("http://t.co/3NHnPsjF")
    response.should_not be_empty
  end
end

