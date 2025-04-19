require "redis"

module Utils::RedisClient
  extend self

  @@client : Redis::PooledClient? = nil

  def client
    @@client ||= Redis::PooledClient.new(
      host: "localhost", 
      port: 6379, 
      pool_size: 5, 
      pool_timeout: 1.second
    )
  end

  def set(key : String, value : String)
    client.set(key, value)
  end

  def get(key : String) : String?
    client.get(key)
  end

  def exists?(key : String) : Bool
    client.exists(key)
  end

  def delete(key : String)
    client.del(key)
  end
end