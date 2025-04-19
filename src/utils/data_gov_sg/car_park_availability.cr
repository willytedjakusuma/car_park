require "json"
require "http/client"
require "../redis_client"
require "debug"

module DataGovSg::CarParkAvailability
  extend self

  CACHE_KEY = "car_park_availability"
  EXPIRY = 60

  def fetch : String
    # fetch data from redis cache
    cached = Utils::RedisClient.client.get(CACHE_KEY)

    # data found in cache, return it
    return cached unless cached.nil?

    # cache miss or expired (in 60 sec), fetch from api
    begin
      response = HTTP::Client.get("https://api.data.gov.sg/v1/transport/carpark-availability")

      # cache data if request success
      if response.status.success?
        Utils::RedisClient.client.setex(CACHE_KEY, EXPIRY, response.body)

        return response.body
      else
        # give log if request failed
        puts "Failed to fetch from DataGovSG: #{response.status_code}"
        raise "API request failed with status #{response.status_code}"
      end
    rescue ex
      puts "Exception occurred while fetching DataGovSG: #{ex.message}"
      return ""
    end
  end
end