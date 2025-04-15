-- +micrate Up
CREATE TABLE car_parks (
  id TEXT PRIMARY KEY,
  address TEXT NOT NULL,
  location geometry(Point, 4326) NOT NULL,
  type TEXT,
  parking_system TEXT,
  short_term_parking TEXT,
  free_parking TEXT,
  night_parking BOOLEAN,
  decks BIGINT,
  gantry_height DOUBLE PRECISION,
  basement BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);


-- +micrate Down
DROP TABLE IF EXISTS car_parks;
