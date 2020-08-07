#!/bin/bash

source llaor/api/db.env.list
sudo docker volume create llaor-pgdata
sudo docker network create llaor-net
sudo docker run --name llaor-postgres -e POSTGRES_PASSWORD=$LLAOR_POSTGRES_PASSWORD-v llaor-pgdata:/var/lib/postgresql/data --restart=always --net llaor-net -d postgres
sudo docker exec -t llaor-postgres psql -U postgres -c  "CREATE ROLE $LLAOR_DB_ROLE WITH LOGIN ENCRYPTED PASSWORD '$LLAOR_DB_ROLE_PASSWORD'"
sudo docker exec -t llaor-postgres psql -U postgres -c  "ALTER ROLE $LLAOR_DB_ROLE createdb"
aws s3 cp s3://llaor/db/latest.dump latest.dump --profile llaor
sudo docker exec -t llaor-postgres psql -U postgres -c "drop database $LLAOR_DB"
sudo docker exec -t llaor-postgres psql -U postgres -c "create database $LLAOR_DB with owner $LLAOR_DB_ROLE"
sudo docker run --rm -v $PWD:/src -v llaor-pgdata:/dest -w /src alpine cp latest.dump /dest
sudo docker exec -t llaor-postgres bash -c "psql -U $LLAOR_DB_ROLE -d $LLAOR_DB < /var/lib/postgresql/data/latest.dump"
