#!/usr/bin/env ruby

require 'yaml'
require 'logger'

begin
  puts Dir.pwd
  config_file = File.join(Dir.pwd, 'config', 'twitcurlr.yml')
  CONFIG = YAML.load_file(config_file)

  LOGLEVEL = CONFIG['loglevel'] || Logger::INFO
rescue SystemCallError
  $stderr.puts "What did you do!?!"
  exit(1)
end

@log = Logger.new(STDOUT)
@log.info "starting twitcurlr daemon..." 
@log.info "creating a new twitcurlr instance using this config: \n#{CONFIG.inspect}"
