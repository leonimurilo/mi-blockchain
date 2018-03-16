#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=mi-flow-channel
GENESIS_PROFILE=ThreeOrgsOrdererGenesis
CHANNEL_PROFILE=ThreeOrgsChannel

# change or add here
declare -a ORGS_MSPS=("Supplier1MSP" "Supplier2MSP" "City1MSP")
declare -a BINARIES=("configtxgen" "cryptogen")

# colors
Red='\033[0;31m'
Green='\033[0;32m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
NC='\033[0m'

for BINARY in "${BINARIES[@]}"
do
  which $BINARY
  if [ "$?" -ne 0 ]; then
    echo -e "${Red}$BINARY tool not found. exiting...${NC}"
    exit 1
  fi
done

# remove previous crypto material and config transactions
rm -fr config/configtx/*
rm -fr config/crypto-config/*

mkdir -p ./config/configtx/
mkdir -p ./config/crypto-config/

# generate crypto material
echo -e
echo -e "========= Generating crypto material at ${Blue}./config/crypto-config/*${NC}"
cryptogen generate --config=./crypto-config.yaml --output="./config/crypto-config"
if [ "$?" -ne 0 ]; then
  echo -e "Failed to generate crypto material..."
  exit 1
fi
echo -e "========= ${Cyan}Done!${NC}"

# generate genesis block for orderer
echo -e
echo -e "========= Generating orderer genesis block at ${Blue}./config/configtx/genesis.block${NC}"
configtxgen -profile $GENESIS_PROFILE -outputBlock ./config/configtx/genesis.block
if [ "$?" -ne 0 ]; then
  echo -e "Failed to generate orderer genesis block..."
  exit 1
fi
echo -e "========= ${Cyan}Done!${NC}"

# generate channel configuration transaction
echo -e
echo -e "========= Generating channel configuration transaction at ${Blue}./config/configtx/channel.tx${NC}"
configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./config/configtx/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo -e "Failed to generate channel configuration transaction..."
  exit 1
fi
echo -e "========= ${Cyan}Done!${NC}"

for ORG_MSP in "${ORGS_MSPS[@]}"
do
  echo -e
  echo -e "========= Generating anchor peer update for ${Purple}${ORG_MSP}${NC}"
  configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ./config/configtx/${ORG_MSP}anchors.tx -channelID $CHANNEL_NAME -asOrg ${ORG_MSP}
  if [ "$?" -ne 0 ]; then
    echo -e "Failed to generate anchor peer update for ${ORG_MSP}..."
    exit 1
  fi
  echo -e "========= ${Cyan}Done!${NC}"
done

echo -e
echo -e "${Green}All settings were successfully applied!${NC}"
echo -e

exit 0
