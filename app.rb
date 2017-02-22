#!/usr/bin/ruby
# Drop Dead Lucky Dip Tracker
# By Ruby (@rubiimeow)
# Released under Creative Commons Attribution-ShareAlike
# License URL: http://creativecommons.org/licenses/by-sa/4.0/
require 'rubygems'
require 'logger'
require 'json'
require 'twitter'
require 'httparty'
require 'dotenv'

# Load Configuration
Dotenv.load

# SKUs of Lucky Dip items and corresponding names
sku_guys =  { "LDTGUY"  => "Guys T-Shirt",
              "LDOGUY"  => "Guys Outerwear",
              "LDJGUY"  => "Guys Jacket",
              "LDAGUY"  => "Guys Accessories"
            }

sku_girls = {   "LDTGRLS"  => "Girls T-Shirt",
                "LDOGRLS"  => "Girls Outerwear",
                "LDJGRLS"  => "Girls Jacket",
                "LDL"     => "Girls Leggings",
                "LDAGRLS" => "Girls Accessories"                 
            }

class DropDead

  def initialize(sku_guys, sku_girls, guys_twitter, girls_twitter)
    @logger = Logger.new(STDOUT)   
    @sku_guys = sku_guys
    @sku_girls = sku_girls
    @guys_twitter = Tweeter.new(guys_twitter)
    @girls_twitter = Tweeter.new(girls_twitter)
    @logger.level = Logger::INFO
    @logger.info("DropDead Luckydipper Started")
    update_stock
  end

  def update_feed
    @feed = JSON.parse(HTTParty.get(ENV["FEED_URL"]).body)
  end

  def update_stock
    update_feed
    new_stock = Hash.new
    @feed['offers'].each do |item|
      #DD's SKUs have hyphens in by default so this strips them to make it easier for me :)
      new_stock[item['sku'].gsub(/\d|\W/, "").to_sym] = item['in_stock']
    end

    if @stock
      #return the values that are now in stock
      now_stocked = Hash.new
      @stock.each do | sku, in_stock |
        if new_stock[sku] != in_stock
          now_stocked[sku] = new_stock[sku]
        end
      end

      if !now_stocked.empty?
        compile_tweets(SizeMapper.new(now_stocked))
      end
    end

    @stock = new_stock
    @logger.info("Luckydipper Updated")
  end

  def compile_tweets(size_map)
    @sku_guys.each do | sku_prefix, label |
      @guys_twitter.doTweet(size_map.get_sizes_now_stocked(sku_prefix), label)
    end

    @sku_girls.each do | sku_prefix, label |
       @girls_twitter.doTweet(size_map.get_sizes_now_stocked(sku_prefix), label)   
    end
  end
end

class SizeMapper
  def initialize(now_stocked)
    @now_stocked = now_stocked
  end

  def get_sizes_now_stocked(sku_prefix)
    sizes = Array.new
    @now_stocked.each do | sku, value |
      if value
        if sku.to_s.start_with?(sku_prefix)
          sizes.push(sku.to_s[sku_prefix.length..-1])
        end
      end
    end

    return sizes
  end
end

class Tweeter
  def initialize(client)
    @twitter = client
  end

  def doTweet(data, label)
    if !data.empty?
      if data.count == 1
        @twitter.update(ENV["BASE_TWEET"] + " " + label + " now available in " + data.first)  
        puts ENV["BASE_TWEET"] + " " + label + " now available in " + data.first         
      else
        @twitter.update(ENV["BASE_TWEET"] + " " + label + " now available in " + data.join(", "))
        puts ENV["BASE_TWEET"] + " " + label + " now available in " + data.join(", ")          
      end
    end
  end
end

guys_twitter = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["GUYS_ACCESS_TOKEN"]
  config.access_token_secret = ENV["GUYS_ACCESS_SECRET"]
end

girls_twitter = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["GIRLS_ACCESS_TOKEN"]
  config.access_token_secret = ENV["GIRLS_ACCESS_SECRET"]
end
    
drop_dead = DropDead.new(sku_guys, sku_girls, guys_twitter, girls_twitter)
loop do
  sleep(ENV["WAIT_TIME"].to_i)
  drop_dead.update_stock
end
