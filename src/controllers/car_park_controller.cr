require "../utils/data_gov_sg/car_park_availability"

class CarParkController < ApplicationController
  def nearest
    unless params.has_key?("lat") && params.has_key?("long")
      return respond_with 400 do
        error_message = { error: "missing lat / long" }
        json error_message.to_json
      end
    end

    page = params["page"]?.try(&.to_i) || 1
    limit = params["limit"]?.try(&.to_i) || 10
    latitude = params["lat"].to_f
    longitude = params["long"].to_f

    car_parks = CarPark.all(
      "WHERE ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)) IS NOT NULL
      ORDER BY ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)) ASC
      LIMIT $3 
      OFFSET $4", [longitude, latitude, limit, (page - 1) * limit])

    return respond_with 200 do
      json build_result(car_parks, latitude, longitude)
    end
  end

  private def build_result(car_parks : Granite::Collection(CarPark), latitude : Float64, longitude : Float64) : String
    availability = DataGovSg::CarParkAvailability.fetch
    return car_parks.to_json if availability == ""

    carparks_availability = fetch_carpark_data(JSON.parse(availability))

    results = car_parks.map do |cp|
      carpark_data = fetch_availability_by_carpark_no(cp.car_park_no, carparks_availability)
      distance = get_distance(latitude, longitude, cp)
      cp = cp.to_h.merge({"distance_in_meter" => distance})

      if carpark_data
        carpark_lot = carpark_data.dig("carpark_info", 0)
        update_timestamp = carpark_data.dig("update_datetime")
        lot_data = {
          "total_lots" => carpark_lot.dig("total_lots"),
          "lots_available" => carpark_lot.dig("lots_available"),
          "updated_as_per" => update_timestamp.as_s
        }
        cp.merge({"lot_data" => lot_data})
      else
        cp.merge({"lot_data" => "Lot data not availabe"})
      end
    end

    return results.to_json
  end

  private def fetch_carpark_data(availability : JSON::Any) : Array(JSON::Any)
    availability.dig("items", 0, "carpark_data").as_a
  end

  private def fetch_availability_by_carpark_no(carpark_no : String, availability : Array(JSON::Any)) : JSON::Any | Nil
    availability.find {|a| a.dig("carpark_number") == carpark_no }
  end

  private def get_distance(lat : Float64, long : Float64, cp : CarPark) : Float64?
    sql = "SELECT ST_DistanceSphere(ST_GeomFromText($3, 4326), ST_SetSRID(ST_MakePoint($1, $2), 4326))"
    CarPark.adapter.database.query_one?(sql, long, lat, cp.location, as: Float64)
  end
end
