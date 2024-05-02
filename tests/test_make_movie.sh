#!/bin/bash
# Exit on failure
set -e

# This test verifies that the docker environment can create movies.
# Test Steps:
#   1. Send API request to create request the movie is created
#   2. Wait some time for the movie container to process the request
#   3. Send API request to retrieve status of the movie
#   4. Verify the movie was created successfully by checking the status

# 1. Send API request to create request the movie is created
# Obtained by monitoring the network tab and making a request within the container environment
response=$(curl -s -X GET "http://localhost:8081/?action=queueMovie&imageScale=19.36352704&layers=\[SOHO%2CLASCO%2CC2%2Cwhite-light%2C2%2C100%2C0%2C60%2C1%2C2024-05-01T11%3A48%3A29.000Z\]&events=&eventsLabels=true&scale=true&scaleType=earth&scaleX=-7534&scaleY=11199&format=mp4&size=0&movieIcons=0&followViewport=0&reqObservationDate=2023-12-01T00%3A48%3A07.000Z&switchSources=false&celestialBodiesLabels=&celestialBodiesTrajectories=&x1=-23381.4589008&x2=9865.71702688&y1=-12799.29137344&y2=12412.02083264&startTime=2023-11-30T12%3A48%3A07.000Z&endTime=2023-12-01T12%3A48%3A07.000Z&frameRate=15")
# Get the movie ID from the response
movie_id=$(echo $response | jq -r ".id")

# 2. Wait some time for the movie container to process the request
# It should be fast since it has one job.
sleep 5

# 3. Send API request to retrieve status of the movie
result=$(curl -s -X GET "http://localhost:8081/?action=getMovieStatus&id=$movie_id&format=mp4")

# 4. Verify the movie was created successfully by checking the status
status=$(echo $result | jq -r ".status")
if [ $status -ne 2 ]; then
    # On failure, print the error message and status of the request
    echo "Helioviewer environment failed to create a movie. Response:"
    echo $(echo $result | jq)
    exit 1
fi

# All good!
exit 0
