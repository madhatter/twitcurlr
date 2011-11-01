require 'rubygems'
require 'twitter'
require 'curb'
require 'json'
require 'logger'

class Twitcurlr
  LOCATION_START = 'Location: '
  LOCATION_STOP  = "\r\n"

  def initialize(auth, hashtags)
    Twitter.configure do |config|
	config.consumer_key = auth['consumer_key']
	config.consumer_secret = auth['consumer_secret']
	config.oauth_token = auth['token']
	config.oauth_token_secret = auth['token_secret']
      end
    @twitter =  Twitter::Client.new
    @hashtags = hashtags
    # TODO Maybe it would be a good idea to store this in an file if the daemon stops
    @latest_id = 0
    @log = Logger.new(STDOUT)
    @log.level = -1
    @log.debug "log level set to #{@log.level}"
  end

  def latest_tweets(username = nil, count = 20)
    result = Array.new
    latest_id = 0
    #tweets = Twitter.user_timeline(username, {:count => count})
    tweets = @twitter.home_timeline({:count => count})
    tweets.each do |tweet|
      time_formated = format_time(convert_time(tweet.created_at))
      time_relative = calc_relative_time(convert_time(tweet.created_at)) 
      unless tweet.id <= @latest_id
	      result.push(get_tweet_string(time_relative, tweet.user.screen_name, tweet.text))
	      latest_id = tweet.id unless tweet.id < latest_id
      end
    end
    # TODO Tests. As content changes just count the elements in the array.
    @latest_id = latest_id unless latest_id == 0
    result
  end

  def last_tweet(username = nil)
    latest_tweets(username, 1)
  end

  def curl(username = nil, count = 20)
    result = Array.new
    latest_id = 0
    if username
      tweets = Twitter.user_timeline(username, {:count => count})
    else
      tweets = @twitter.home_timeline({:count => count})
    end
    tweets.each do |tweet|
      time_formated = format_time(convert_time(tweet.created_at))
      time_relative = calc_relative_time(convert_time(tweet.created_at)) 
      unless tweet.id <= @latest_id || tweet.retweeted
        matched_tweet = search_for_tags(tweet.text)
        if matched_tweet
          link = extract_image_url(matched_tweet[0])
          @log.debug link.to_s
          result.push(get_tweet_string(time_relative, tweet.user.screen_name, matched_tweet[0].to_s))
          latest_id = tweet.id unless tweet.id < latest_id
        end
      end
    end
    @latest_id = latest_id unless latest_id == 0
    result
  end

  def search_for_tags(tweet)
    # TODO Collect all matching tags in an own array to return.
    @hashtags.each do |tag|
      # matching case-insesitive
      if tweet.downcase =~ /#{tag}/
        return tweet, tag
      end
    end
    return nil
  end

  def extract_image_url(tweet)
    @log.debug "#{tweet}"
    url = extract_url_from_tweet(tweet)
    analyse_image_url(url)
  end

  def analyse_image_url(url)
    rurl = nil
    if !url.nil?
      rurl = get_tco_image(url) if url.index 't.co'
      rurl = get_twitpic_image(url) if url.index 'twitpic'
    end
    @log.debug "Got it: #{rurl}"
    rurl
  end

  def extract_url_from_tweet(tweet)
    start = tweet.index('http')
    if start
      stop = tweet.index(' ', start) || 0
    end
    tweet[start..stop -1]
  end

  def get_tco_image(url) 
    @log.debug "t.co"
    real_url = get_redirect_link(url)
    analyse_image_url(real_url)
  end

  def get_twitpic_image(url)
    @log.debug "twitpic"
    get_redirect_image(url, "http://twitpic.com/show/full/")
  end

  def get_redirect_link(short_link, stop_indicator = LOCATION_STOP)
    try = 0
    begin
      resp = Curl::Easy.http_get(short_link) { |res| res.follow_location = true }
    rescue => err
      @log.error "Curl::Easy.http_get failed: #{err}"
      try += 1
      sleep 3
      if try < 5
        retry
      else 
        return nil
      end
    end
    @log.debug "#{resp.header_str}"
    if(resp && resp.header_str.index(LOCATION_START) \
       && resp.header_str.index(stop_indicator))
      start = resp.header_str.index(LOCATION_START) + LOCATION_START.size
      stop = resp.header_str.index(stop_indicator, start)
      @log.debug "Get redirect link"
      resp.header_str[start..stop]
    else
      @log.debug "Not getting redirect link for #{short_link}"
      nil
    end
  end

  def get_redirect_image(image_url, service_endpoint, stop_indicator = LOCATION_STOP)
    @log.debug "#{service_endpoint}#{extract_image_id(image_url)}"
    get_redirect_link "#{service_endpoint}#{extract_image_id image_url }", stop_indicator
  end

  def extract_image_id(link)
    link.split('/').last if link.split('/')
  end

  def get_tweet_string(time_rel, screen_name, text)
    time_rel[:value].to_s + " " + time_rel[:entity] + ("s" unless time_rel[:value] < 2).to_s \
	    + " ago " + "\t" + screen_name + "\t\"" + text + "\"\n"
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

