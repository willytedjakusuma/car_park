class CarParkController < ApplicationController
  def nearest
    unless params.has_key?("lat") && params.has_key?("long")
      return respond_with 400 do
        error_message = { error: "missing lat / long" }
        json error_message.to_json
      end
    end

    page = params["page"]?.try(&.to_i) || 1
    offset = params["offset"]?.try(&.to_i) || 10
    latitude = params["lat"].to_f
    longitude = params["long"].to_f

    car_parks = CarPark.all(
      "WHERE ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)) IS NOT NULL
      ORDER BY ST_DistanceSphere(location, ST_SetSRID(ST_MakePoint($1, $2), 4326)) ASC
      LIMIT $3 
      OFFSET $4", [longitude, latitude, offset, (page - 1) * offset])

    return respond_with 200 do
      json car_parks.to_json
    end
  end

  # private def cp_with_distance(cp : CarPark, point_sql : String)
  #   CarPark
  #     .where(id: cp.id)
  #     .select("ST_DistanceSphere(location, #{point_sql}) AS distance")
  #     .first?
  #     .try { |c| c["distance"].to_f } || 0.0
  # end
end
