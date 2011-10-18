require 'rubygems'
require 'twitter'

class Twitcurlr
  def initialize(auth)
    Twitter.configure do |config|
	config.consumer_key = auth['consumer_key']
	config.consumer_secret = auth['consumer_secret']
	config.oauth_token = auth['token']
	config.oauth_token_secret = auth['token_secret']
      end
    @twitter =  Twitter::Client.new
  end

  def latest_tweets(username = nil, count = 20)
    result = Array.new
    #tweets = Twitter.user_timeline(username, {:count => count})
    tweets = @twitter.home_timeline({:count => count})
    tweets.each do |tweet|
      time_formated = format_time(convert_time(tweet.created_at))
      time_relative = calc_relative_time(convert_time(tweet.created_at)) 
      puts time_relative[:value].to_s
      result.push(time_relative[:value].to_s + time_relative[:entity] + "ago"  + "\t\"" + tweet.text + "\"\n")
    end
    result
  end

  def last_tweet(username = nil)
    latest_tweets(username, 1)
  end

  def convert_time(date_string)
    date_array = date_string.split
    time_array = date_array[3].split(":")
    date = Time.utc(date_array[5], date_array[1], date_array[2], time_array[0], time_array[1], time_array[2])
  end

  def format_time(time)
    time.localtime.strftime("%m/%d/%Y %T:%M")
  end

  def calc_relative_time(time)
    atime = {}
    time_now = Time.now.utc
    time_diff = Time.at(time_now - time)
    if time_diff.min < 1 
      atime = {:value => time_diff.tv_sec, :entity => 'seconds'}
    elsif time_diff.min > 59
      atime = {:value => time_diff.hours, :entity => 'hours'}
    elsif time_diff.hour > 24
      atime = {:value => time_diff.days, :entity => 'days'}
    else
      atime = {:value => time_diff.min, :entity => 'minutes'}
    end
  end
end

