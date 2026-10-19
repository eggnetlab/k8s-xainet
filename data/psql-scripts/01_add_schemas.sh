#!/bin/bash
set -e

IFS=',' read -r -a schemas <<< $POSTGRES_SCHEMAS

for schema in ${schemas[@]}
do
    echo "adding schema $schema"
PGPASSWORD=$POSTGRES_PASSWORD psql \
    -v ON_ERROR_STOP=1 \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB <<-EOSQL
  CREATE USER ${schema} WITH PASSWORD '${POSTGRES_USER_PASSWORD}';
  GRANT CREATE ON DATABASE $POSTGRES_DB TO ${schema}
EOSQL

PGPASSWORD=$POSTGRES_USER_PASSWORD psql \
    -v ON_ERROR_STOP=1 \
    -U $schema \
    -d $POSTGRES_DB <<-EOSQL
  CREATE SCHEMA IF NOT EXISTS ${schema} AUTHORIZATION ${schema};
  GRANT ALL PRIVILEGES ON SCHEMA ${schema} TO ${schema};
  ALTER ROLE ${schema} SET search_path to ${schema};
EOSQL
done


