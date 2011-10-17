require 'rubygems'
require 'twitter'

class Twitcurlr
  def initialize
    Twitter.configure do |config|
	config.consumer_key = "JOaCrxrtn8eKgCVOlpWRQ"
	config.consumer_secret = "brBx60OPfT6DlveRdxuwUFhdTBP9P9xIDbgol3UP8pU"
	config.oauth_token = "218466084-18G5H2rAWZaMqJH618Dtu7sPGrfHYfAWZIHyyVGd"
	config.oauth_token_secret = "t6s6H081tGhQew0tBfWZXd6nYsr43NkxMZ8Tgdhd8"
      end
    @twitter =  Twitter::Client.new
  end

  def latest_tweets(username = nil, count = 20)
    result = Array.new
    #tweets = Twitter.user_timeline(username, {:count => count})
    tweets = @twitter.home_timeline({:count => count})
    tweets.each do |tweet|
      date = format_time(tweet.created_at)
      result.push(date.localtime.strftime("%m/%d/%Y %T:%M") + "\t\"" + tweet.text + "\"\n")
    end
    result
  end

  def last_tweet(username = nil)
    latest_tweets(username, 1)
  end

  def format_time(date_string)
    date_array = date_string.split
    time_array = date_array[3].split(":")
    date = Time.utc(date_array[5], date_array[1], date_array[2], time_array[0], time_array[1], time_array[2])
  end
end

