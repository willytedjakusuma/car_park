require "http/client"
require "json"
require "uri"

module Utils::Svy21::WithOpenMapApi
  # This module is used to cross check lat long 
  # with openmap API 
  # if the result is too deviated from this API
  # need to adjust the converter function
  # in to_wgs84 module
  
  extend self

  def get_lat_long(x : Float64, y : Float64)
    begin
      uri = URI.parse("#{ENV["ONEMAP_URL"]}/common/convert/3414to4326")
      uri.query = build_query_params({"X" => x, "Y" => y})
      token_info = get_token
  
      unless token_info && token_info["access_token"]?
        raise "Failed to get token from openmap api"
      end
  
      headers = HTTP::Headers{
        "Content-Type"  => "application/json",
        "Authorization" => "Bearer #{token_info["access_token"]}",
      }
  
      response = HTTP::Client.get(uri, headers)
      JSON.parse(response.body)
    rescue ex : Exception
      puts ex.message
    end
  end

  def get_token
    begin
      payload = {
        "email":    ENV["ONEMAP_EMAIL"],
        "password": ENV["ONEMAP_PASSWORD"],
      }.to_json
  
      headers = HTTP::Headers{
        "Content-Type" => "application/json",
      }
  
      response = HTTP::Client.post("#{ENV["ONEMAP_URL"]}/auth/post/getToken", headers, body: payload)

      unless response.status.success? 
        raise "Request token from OPENMAP API failed with code #{response.status.code}, #{response.status.description} "
      end

      JSON.parse(response.body) 
    rescue ex : Exception
      puts ex.message
    end
  end

  private def build_query_params(params : Hash(String, Float64)) : String
    params.map { |key, value| "#{URI.encode_path(key)}=#{URI.encode_path(value.to_s)}" }.join("&")
  end
end
