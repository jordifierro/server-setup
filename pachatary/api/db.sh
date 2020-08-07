#!/bin/bash

source pachatary/api/db.env.list
sudo docker volume create pachatary-pgdata
sudo docker network create pachatary-net
sudo docker run --name pachatary-postgres -e POSTGRES_PASSWORD=$PACHATARY_POSTGRES_PASSWORD -v pachatary-pgdata:/var/lib/postgresql/data --restart=always --net pachatary-net -d postgres
sudo docker exec -t pachatary-postgres psql -U postgres -c  "CREATE ROLE $PACHATARY_DB_ROLE WITH LOGIN ENCRYPTED PASSWORD '$PACHATARY_DB_ROLE_PASSWORD'"
sudo docker exec -t pachatary-postgres psql -U postgres -c  "ALTER ROLE $PACHATARY_DB_ROLE createdb"
aws s3 cp s3://pachatary-db/latest.dump latest.dump --profile pachatary
sudo docker exec -t pachatary-postgres psql -U postgres -c "drop database $PACHATARY_DB"
sudo docker exec -t pachatary-postgres psql -U postgres -c "create database $PACHATARY_DB with owner $PACHATARY_DB_ROLE"
sudo docker run --rm -v $PWD:/src -v pachatary-pgdata:/dest -w /src alpine cp latest.dump /dest
sudo docker exec -t pachatary-postgres bash -c "psql -u $PACHATARY_DB_ROLE -d $PACHATARY_DB < /var/lib/postgresql/data/latest.dump"
