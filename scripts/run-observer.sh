#!/bin/bash
SHARD=metachain
cd ..

TAG_FROM_BINARY=$(cat binaryVersion)
#check if the tag binaryVersion file exits on the github
TAG_EXITS=$(git ls-remote https://github.com/ElrondNetwork/elrond-go.git "${TAG_FROM_BINARY}")
if [ -z "${TAG_EXITS}" ]; then
      echo "tag from binaryVersion file(${TAG_FROM_BINARY}) does not exit"
      exit 1
fi

# build docker image
export IMAGE_NAME=elrond-node-image-test
docker image build . -t ${IMAGE_NAME} -f ./docker/Dockerfile

# generate a new BLS key
OUTPUT_FOLDER=~/output/keys
if [ ! -f "${OUTPUT_FOLDER}/validatorKey.pem" ]; then
  mkdir -p ${OUTPUT_FOLDER}
  docker run --rm --mount type=bind,source=${OUTPUT_FOLDER},destination=/keys --workdir /keys elrondnetwork/elrond-go-keygenerator:latest
fi

## run docker image
PORT=8080
docker run -d -p 8080:${PORT} --mount type=bind,source=${OUTPUT_FOLDER}/,destination=/data ${IMAGE_NAME} --validator-key-pem-file="/data/validatorKey.pem" --log-level *:DEBUG --log-save --destination-shard-as-observer=${SHARD}

export ADDRESS_WITH_ROUTE=http://localhost:${PORT}/network/status

#check if 'curl' is installed
if ! command -v curl &> /dev/null; then
    apt install -y curl
fi

#check if 'jq' is installed
if ! command -v jq &> /dev/null; then
    apt install -y jq
fi


check_nonce_grows() {
  FIRST_TIME=0
  PREVIOUS_NONCE=0
  RE='^[0-9]+$'
  echo "node is running...wait for the tree to be synced"
  while true
  do
    #check if container is running
    CONTAINER_ID=$(docker ps -q  --filter ancestor=${IMAGE_NAME})
    if [ -z "${CONTAINER_ID}" ]; then
      echo "node is not running"
      exit 1
    fi

    CURRENT_NONCE=$(curl -s ${ADDRESS_WITH_ROUTE} | jq '.data["status"]["erd_nonce"]')
    #check if the current nonce is number
    if ! [[ ${CURRENT_NONCE} =~ ${RE} ]] ; then
       sleep 4s
       continue
    fi

    if [ "${CURRENT_NONCE}" -gt 0 ]; then
      # check if is first time when current nonce is greater than zero
      if [ "${FIRST_TIME}" -eq 0 ]; then
        FIRST_TIME=1
        PREVIOUS_NONCE=${CURRENT_NONCE}
        sleep 4s
        continue
      fi
      if [ "${CURRENT_NONCE}" -gt "${PREVIOUS_NONCE}" ]; then
        echo "node is syncing... nonce is increasing"
        break
      fi
      PREVIOUS_NONCE=${CURRENT_NONCE}
    fi
    sleep 4s
  done

}
export -f check_nonce_grows

TIMEOUT_DURATION=10m
timeout ${TIMEOUT_DURATION}  bash -c check_nonce_grows
EXIT_STATUS=$?
if [ ${EXIT_STATUS} -eq 1 ]; then
  exit 1
fi

# stop docker container
CONTAINER_ID=$(docker ps -q  --filter ancestor=${IMAGE_NAME})
docker stop "${CONTAINER_ID}"

if [ ${EXIT_STATUS} -eq 124 ]; then
   echo "exit with timeout"
   exit 1
fi
