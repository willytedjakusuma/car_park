module Utils::Svy21::ToWgs84
  # Credit here to https://github.com/cgcai
  # Below calculation was taken from 
  # https://github.com/cgcai/SVY21/blob/master/Ruby/lib/svy21.rb
  # With some adjustment to match crystal syntax
  extend self

  # Ratio to convert degrees to radians.
  RAD_RATIO = Math::PI / 180.0
  
  # Datum and Projection.
  
  # Semi-major axis of reference ellipsoid.
  A = 6378137.0
  # Ellipsoidal flattening
  F = 1.0 / 298.257223563
  # Origin latitude (degrees).
  ORIGIN_LATITUDE = 1.366666
  # Origin longitude (degrees).
  ORIGIN_LONGITUDE = 103.833333
  # False Northing.
  FALSE_NORTHING = 38744.572
  # False Easting.
  FALSE_EASTING = 28001.642
  # Central meridian scale factor.
  K = 1.0
  
  # Computed Projection Constants
  
  # Naming convention: the trailing number is the power of the variable.
  
  # Semi-minor axis of reference ellipsoid.
  B = A * (1.0 - F)
  # Squared eccentricity of reference ellipsoid.
  E2 = (2.0 * F) - (F * F)
  E4 = E2 * E2
  E6 = E4 * E2
  
  # Naming convention: A0..6 are terms in an expression, not powers.
  
  A0 = 1.0 - (E2 / 4.0) - (3.0 * E4 / 64.0) - (5.0 * E6 / 256.0)
  A2 = (3.0 / 8.0) * (E2 + (E4 / 4.0) + (15.0 * E6 / 128.0))
  A4 = (15.0 / 256.0) * (E4 + (3.0 * E6 / 4.0))
  A6 = 35.0 * E6 / 3072.0
  
  # Naming convention: the trailing number is the power of the variable.
  
  N = (A - B) / (A + B)
  N2 = N * N
  N3 = N2 * N
  N4 = N2 * N2
  
  G = A * (1.0 - N) * (1.0 - N2) * (1.0 + (9.0 * N2 / 4.0) + (225.0 * N4 / 64.0)) * RAD_RATIO

  # M: meridian distance.
  private def calc_m(lat)
    lat_r = lat * RAD_RATIO
    
    A * ((A0 * lat_r) - (A2 * Math.sin(2.0 * lat_r)) + (A4 * Math.sin(4.0 * lat_r)) - (A6 * Math.sin(6.0 * lat_r)))
  end
  
  # Rho: radius of curvature of meridian.
  private def calc_rho(sin_2_lat)
    num = A * (1.0 - E2)
    denom = (1.0 - E2 * sin_2_lat) ** (3.0 / 2.0)
    
    num / denom
  end
  
  # v: radius of curvature in the prime vertical.
  private def calc_v(sin_2_lat)
    poly = 1.0 - E2 * sin_2_lat
    
    A / Math.sqrt(poly)
  end

  def convert(x_coord : Float64, y_coord : Float64) : NamedTuple(lat: Float64, long: Float64)
    n_prime = y_coord - FALSE_NORTHING
    m_origin = calc_m(ORIGIN_LATITUDE)
    m_prime = m_origin + (n_prime / K)
    sigma = (m_prime / G) * RAD_RATIO
    
    # Naming convention: lat_prime_t1..4 are terms in an expression, not powers.
    lat_prime_t1 = ((3.0 * N / 2.0) - (27.0 * N3 / 32.0)) * Math.sin(2.0 * sigma)
    lat_prime_t2 = ((21.0 * N2 / 16.0) - (55.0 * N4 / 32.0)) * Math.sin(4.0 * sigma)
    lat_prime_t3 = (151.0 * N3 / 96.0) * Math.sin(6.0 * sigma)
    lat_prime_t4 = (1097.0 * N4 / 512.0) * Math.sin(8.0 * sigma)
    lat_prime = sigma + lat_prime_t1 + lat_prime_t2 + lat_prime_t3 + lat_prime_t4
    
    # Naming convention: sin_2_lat_prime = "square of sin(lat_prime)" = sin(lat_prime) ** 2.0
    sin_lat_prime = Math.sin(lat_prime)
    sin_2_lat_prime = sin_lat_prime * sin_lat_prime
    
    # Naming convention: the trailing number is the power of the variable.
    rho_prime = calc_rho(sin_2_lat_prime)
    v_prime = calc_v(sin_2_lat_prime)
    psi_prime = v_prime / rho_prime
    psi_prime_2 = psi_prime * psi_prime
    psi_prime_3 = psi_prime_2 * psi_prime
    psi_prime_4 = psi_prime_3 * psi_prime
    t_prime = Math.tan(lat_prime)
    t_prime_2 = t_prime * t_prime
    t_prime_4 = t_prime_2 * t_prime_2
    t_prime_6 = t_prime_4 * t_prime_2
    e_prime = x_coord - FALSE_EASTING
    x = e_prime / (K * v_prime)
    x2 = x * x
    x3 = x2 * x
    x5 = x3 * x2
    x7 = x5 * x2
    
    # Compute Latitude
    # Naming convention: lat_term_1..4 are terms in an expression, not powers.
    lat_factor = t_prime / (K * rho_prime)
    lat_term_1 = lat_factor * ((e_prime * x) / 2.0)
    lat_term_2 = lat_factor * ((e_prime * x3) / 24.0) * ((-4.0 * psi_prime_2 + (9.0 * psi_prime) * (1.0 - t_prime_2) + (12.0 * t_prime_2)))
    lat_term_3 = lat_factor * ((e_prime * x5) / 720.0) * ((8.0 * psi_prime_4) * (11.0 - 24.0 * t_prime_2) - (12.0 * psi_prime_3) * (21.0 - 71.0 * t_prime_2) + (15.0 * psi_prime_2) * (15.0 - 98.0 * t_prime_2 + 15.0 * t_prime_4) + (180.0 * psi_prime) * (5.0 * t_prime_2 - 3.0 * t_prime_4) + 360.0 * t_prime_4)
    lat_term_4 = lat_factor * ((e_prime * x7) / 40320.0) * (1385.0 - 3633.0 * t_prime_2 + 4095.0 * t_prime_4 + 1575.0 * t_prime_6)
    lat = lat_prime - lat_term_1 + lat_term_2 - lat_term_3 + lat_term_4
    
    # Compute Longitude
    # Naming convention: lon_term_1..4 are terms in an expression, not powers.
		sec_lat_prime = 1.0 / Math.cos(lat)
		lon_term_1 = x * sec_lat_prime
		lon_term_2 = ((x3 * sec_lat_prime) / 6.0) * (psi_prime + 2.0 * t_prime_2)
		lon_term_3 = ((x5 * sec_lat_prime) / 120.0) * ((-4.0 * psi_prime_3) * (1.0 - 6.0 * t_prime_2) + psi_prime_2 * (9.0 - 68.0 * t_prime_2) + 72.0 * psi_prime * t_prime_2 + 24.0 * t_prime_4)
		lon_term_4 = ((x7 * sec_lat_prime) / 5040.0) * (61.0 + 662.0 * t_prime_2 + 1320.0 * t_prime_4 + 720.0 * t_prime_6)
		lon = (ORIGIN_LONGITUDE * RAD_RATIO) + lon_term_1 - lon_term_2 + lon_term_3 - lon_term_4
    
    { lat: lat / RAD_RATIO, long: lon / RAD_RATIO }
  end

  def batch_convert(records : Array(Hash(String, String))) : Hash(String, NamedTuple(lat: Float64, long: Float64))
    records.each_with_object({} of String => NamedTuple(lat: Float64, long: Float64)) do |record, result|
      result[record["car_park_no"]] = convert(
        x_coord: record["x_coord"].to_f,
        y_coord: record["y_coord"].to_f
      )
    end
  end
end