#! /bin/bash

echo "Pulling latest rhel7 image"
docker pull rhel7:latest
echo "Checking if the latest image is new enough to trigger Jenkins"
COUNT=$(docker history rhel7:latest | awk 'FNR == 2 {print}' | grep -cE 'year|week|days')

COUNT=0
while [ "$COUNT" -lt 1 ]; do
  #curl http://host.secureworkslab.com/job/rhel7/build
  echo "Triggering Jenkins"
  response=$(curl --write-out %{http_code} --silent --output /dev/null http://host.secureworkslab.com/job/rhel7/build)
  if [ "$response" -eq 201 ]; then
    echo "Successfully triggered Jenkins"
    COUNT=1
  else
    echo "Could not connect to Jenkins, trying again"
    nscd -i hosts
  fi
done
