#!/bin/bash

echo "Validating service..."

status_code=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:80)

echo  "health check status: $status_code"


if [[ "$status_code" -ne 200 ]] ; then
  exit 1
else
  exit 0
fi

