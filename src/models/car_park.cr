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
  column free_parking : String?
  column night_parking : Bool?
  column decks : Int64?
  column gantry_height : Float64?
  column basement : Bool?
  timestamps

  validate_not_blank :car_park_no
  validate_not_blank :address
  validate_not_blank :location

  validate_uniqueness :car_park_no

  # custom validation
  validate :location, "format incorrect" do |car_park|
    false unless car_park.location

    match_data = Regex.new("POINT\\(-?\\d+(\\.\\d+)? -?\\d+(\\.\\d+)?\\)").match(car_park.location)
    match_data.is_a?(Regex::MatchData)
  end

  select_statement <<-SQL
    SELECT *, ST_AsText(location) AS location
    FROM car_parks
  SQL

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
    sql = "SELECT ST_#{coord_type}(location::geometry) FROM car_parks WHERE id = $1"
    self.class.adapter.database.query_one?(sql, self.id, as: Float64)
  end
end
