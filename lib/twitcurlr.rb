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
    @latest_id = 0
  end

  def latest_tweets(username = nil, count = 20)
    result = Array.new
    loop_count = 0
    latest_id = 0
    #tweets = Twitter.user_timeline(username, {:count => count})
    tweets = @twitter.home_timeline({:count => count})
    tweets.each do |tweet|
      time_formated = format_time(convert_time(tweet.created_at))
      time_relative = calc_relative_time(convert_time(tweet.created_at)) 
      # TODO There should be another method to build this string
      puts "@latest_id = #{@latest_id} , tweet_id = #{tweet.id}"
      unless tweet.id <= @latest_id
	result.push(time_relative[:value].to_s + " " + time_relative[:entity] \
		    + ("s" unless time_relative[:value] < 2).to_s + " ago "  \
		    + "\t" + tweet.user.screen_name + "\t\"" + tweet.text + "\"\n")
	latest_id = tweet.id if loop_count == 0
	loop_count += 1
      end
    end
    # TODO Tests. As content changes just count the elements in the array.
    @latest_id = latest_id
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
    if time_diff.tv_sec < 59
      atime = {:value => time_diff.tv_sec, :entity => 'second'}
    elsif time_diff.tv_sec > 59 && time_diff.tv_sec <= 3599
      atime = {:value => time_diff.min, :entity => 'minute'}
    elsif time_diff.tv_sec >= 3599 && time_diff.tv_sec < 86400
      # substract always 1 hour because time_diff.hour is already '2' at 3649 seconds
      atime = {:value => time_diff.hour - 1, :entity => 'hour'}
    else
      atime = {:value => time_diff.day, :entity => 'day'}
    end
  end
end

