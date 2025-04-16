require "csv"
require "../utils/svy21/to_wgs84"
require "../models/car_park"
require "debug"

module Services::CarParkDataLoader
  extend self

  DEFAULT_FILE_PATH = File.join(__DIR__, "../../resources/dataset/HDBCarparkInformation.csv")

  def call(file_path = DEFAULT_FILE_PATH)
    existing_car_parks = CarPark.all
    records = parse_csv(file_path)

    coord_data = Utils::Svy21::ToWgs84.batch_convert(records)
    car_parks = batch_build_car_park(existing_car_parks, records, coord_data)
    validated_data = batch_validate_model(car_parks)[:valid]
    updated_columns = ["address", "location", "type", "parking_system", "short_term_parking", "free_parking", "night_parking", "decks", "gantry_height", "basement"]

    CarPark.import(validated_data, update_on_duplicate: true, columns: updated_columns)
  end

  private def parse_csv(file_path = DEFAULT_FILE_PATH)  : Array(Hash(String, String))
    records = [] of Hash(String, String)

    File.open(file_path) do |file|
      csv = CSV.new(file, headers: true)
      csv.each do |row|
        record = {} of String => String

        csv.headers.each do |header|
          record[header] = row[header].to_s
        end

        records << record
      end
    end

    records
  end

  private def create_car_park(data : Hash(String, String)) : CarPark
    CarPark.new(
      car_park_no: data["car_park_no"],
      address: data["address"],
      location: data["location"],
      type: data["car_park_type"],
      parking_system: data["type_of_parking_system"],
      short_term_parking: data["short_term_parking"],
      free_parking: data["free_parking"],
      night_parking: data["night_parking"] == "YES",
      decks: data["car_park_decks"].to_i64,
      gantry_height: data["gantry_height"].to_f,
      basement: data["car_park_basement"] == "Y"
    )
  end

  private def batch_build_car_park(
    existing : Granite::Collection(CarPark),
    records : Array(Hash(String, String)), 
    coords : Hash(String, NamedTuple(lat: Float64, long: Float64))
  ) : Array(CarPark)
    records.map do |record| 
      car_park_no = record["car_park_no"]
      location = coords[car_park_no]
      record["location"] = CarPark.set_location(lat: location[:lat], long: location[:long])

      if existing_car_park = existing.find(&.car_park_no.==(car_park_no))
        update_car_park(existing_car_park, record)
      else
        create_car_park(record)
      end
    end
  end

  private def batch_validate_model(car_parks : Array(CarPark)) : NamedTuple(valid: Array(CarPark), invalid: Array(CarPark))
    valid, invalid = car_parks.partition(&.valid?)
    { valid: valid, invalid: invalid }
  end

  private def update_car_park(car_park : CarPark, record : Hash(String, String)) : CarPark
    car_park.car_park_no = record["car_park_no"]
    car_park.address = record["address"]
    car_park.location = record["location"]
    car_park.type = record["car_park_type"]
    car_park.parking_system = record["type_of_parking_system"]
    car_park.short_term_parking = record["short_term_parking"]
    car_park.free_parking = record["free_parking"]
    car_park.night_parking = record["night_parking"] == "YES"
    car_park.decks = record["car_park_decks"].to_i64
    car_park.gantry_height = record["gantry_height"].to_f
    car_park.basement = record["car_park_basement"] == "Y"

    car_park
  end
end