# 🚗 Car Park
[![Amber Framework](https://img.shields.io/badge/using-amber_framework-orange.svg)](https://amberframework.org)

This is a project written using [Amber](https://amberframework.org). Enjoy!

## 🧠 Consideration
Here I am listing the reason why I am using technology inside this project

  - Amber 
  
    - Have built in ORM with Granite 
    - More Rails like

  - PostgreSQL

    - Have native geometry data type that can be used seamlessly with PostGIS

  - Redis

    - Work as caching in this project so we don't need to always API to the source

  - PostGIS

    - Have function to calculate distance

## 🚀 Getting Started

These instruction will guide you through how to setup and run this API end point

## 🛠️ Prerequisites

Things that need to be installed on your local before we start setting up the projects
  1. Crystal => [Crystal Installation Guide](https://crystal-lang.org/install/)
  2. PostgreSQL => [Ubuntu Installation Guide](https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/index.html)
  3. Amber => [Amber Dependencies for Ubuntu] => (https://docs.amberframework.org/amber/guides/installation#from-source)
  4. Amber => [Amber Installation Guide] (https://docs.amberframework.org/amber/guides/installation#from-source)
## ▶️ Run App

To start your Amber server:

1. On project root folder, run this command 
    ```bash
    chmod +x bin/setup
    ```
2. Change key `database_url` inside `config/environments/development.yml` to match your postgres database configuration 
    ```yml
    database_url: postgres://[postgres_user]:[postgres_password]@[host]:[port]/car_park_development
    ```
    e.g
    ```yaml
    database_url: postgres://postgres:mypass@localhost:5433/car_park_development
    ```
3. Rename `env.example` to `.env` and fill it according to your postgres setup
4. Run this command to start setup
    ```bash
    bin/setup
    ```
5. Wait until the setup is finished
6. Start Amber server with `amber watch`

Now you can visit http://localhost:3000/ from your browser / Postman

## 🌐 Access the API

You can access the api from this url in your browser / postman

`http://localhost:3000/car_parks/nearest?lat=[your_lat_value]&long=[your_long_value]`

## 🧊 Caching Strategy

1. When user request data, we check if redis have data inside it
2. If Redis have data then return it's data
3. If data is missing or cache expired we then fetch from API then store it in cache

## 🎖️ Credit
Credit to this [CGCAI/SVY21 Repo](https://github.com/cgcai/SVY21/tree/master/Ruby) for providing svy21 to wgs84 calculation that I implement in this project