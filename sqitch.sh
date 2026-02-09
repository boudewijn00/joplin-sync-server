#!/bin/bash
set -e

source .env

export SQITCH_TARGET="db:pg://$POSTGRES_USER@localhost:$POSTGRES_PORT/$POSTGRES_DATABASE"
export PGPASSWORD="$POSTGRES_PASSWORD"

sqitch "$@"
