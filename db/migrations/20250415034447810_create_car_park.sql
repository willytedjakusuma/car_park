-- +micrate Up
CREATE TABLE car_parks (
  id BIGSERIAL PRIMARY KEY,
  car_park_no TEXT NOT NULL,
  address TEXT NOT NULL,
  location geometry(Point, 4326) NOT NULL,
  type TEXT,
  parking_system TEXT,
  short_term_parking TEXT,
  free_parking TEXt,
  night_parking BOOLEAN,
  decks BIGINT,
  gantry_height DOUBLE PRECISION,
  basement BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- ALTER TABLE car_parks ADD CONSTRAINT unique_car_park_no UNIQUE (car_park_no);

-- +micrate Down
DROP TABLE IF EXISTS car_parks;
