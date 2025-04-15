class CarPark < Granite::Base
  connection pg
  table car_parks

  column id : Int64, primary: true
  column car_park_no : String
  column address : String
  column location : String
  column type : String?
  column parking_system : String?
  column short_term_parking : String?
  column free_parking : Bool?
  column night_parking : Bool?
  column decks : Int64?
  column gantry_height : Float64?
  column basement : Bool?
  timestamps
  
  # POINT save lat later POINT(long, lat)
  # below methods is to access lat long separately
  # of any CarPark instance that returning lat and long
  # using ST_X and ST_Y for later postgis function

  # Access latitude using ST_Y PostGIS function
  def lat : Float64?
    fetch_coordinate("Y")
  end

  # Access longitude using ST_X PostGIS function
  def long : Float64?
    fetch_coordinate("X")
  end

  def self.set_location(lat : Float64, long : Float64)
    # Construct the POINT string for PostGIS
    "POINT(#{long} #{lat})"
  end

  # Helper method to execute the coordinate query
  private def fetch_coordinate(coord_type : String) : Float64?
    sql = "SELECT ST_#{coord_type}(location::geometry) FROM car_parks WHERE id = '#{self.id}'"
    result = pg.query(sql).first
    result[0].to_f64? if result
  end
end
