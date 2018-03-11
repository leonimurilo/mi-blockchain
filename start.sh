#!/bin/bash
# Copyright IBM Corp All Rights Reserved
# SPDX-License-Identifier: Apache-2.0
# Exit on first error, print all commands.
# set -ev
# colors

Red='\033[0;31m'
Green='\033[0;32m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
NC='\033[0m'

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

# orgs declaration
declare -a ORGS_LIST=("supplier1" "supplier2" "city1")

docker-compose -f docker-compose.yml down
echo "running containers"
docker-compose -f docker-compose.yml up -d

# without CLI:
# docker-compose -f docker-compose.yml up -d \
# orderer.leonimurilo.com \
# peer0.supplier1.leonimurilo.com \
# ca.supplier1.leonimurilo.com \
# couchdb.supplier1.leonimurilo.com \
# peer0.supplier2.leonimurilo.com \
# ca.supplier2.leonimurilo.com \
# couchdb.supplier2.leonimurilo.com \
# peer0.city1.leonimurilo.com \
# ca.city1.leonimurilo.com \
# couchdb.city1.leonimurilo.com

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
echo Waiting ${FABRIC_START_TIMEOUT} seconds
sleep ${FABRIC_START_TIMEOUT}

echo
echo "========= Creating channel on ${Purple}peer0.supplier1.leonimurilo.com${NC}"
# Create the channel
docker exec \
-e "CORE_PEER_LOCALMSPID=Supplier1MSP" \
-e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@supplier1.leonimurilo.com/msp" \
peer0.supplier1.leonimurilo.com peer channel create \
-o orderer.leonimurilo.com:7050 \
-c mi-flow-channel \
-f /etc/hyperledger/configtx/channel.tx
echo "========= ${Cyan}Done!${NC}"

for ORG in "${ORGS_LIST[@]}"
do

  echo
  echo "========= Joining channel on ${Purple}peer0.$ORG.leonimurilo.com${NC}"
  # Join peer0.$ORG.leonimurilo.com to the channel.
  docker exec \
  -e "CORE_PEER_LOCALMSPID=$ORG_MSP" \
  -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@$ORG.leonimurilo.com/msp" \
  peer0.$ORG.leonimurilo.com peer channel join \
  -b mi-flow-channel.block
  echo "========= ${Cyan}Done!${NC}"
  echo
  echo
done

exit 0
