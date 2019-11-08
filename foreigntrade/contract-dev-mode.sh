#!/usr/bin/env bash
set +e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)
CC_SRC_LANGUAGE=go
CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
CC_SRC_PATH=/opt/gopath/src/github.com/chaincode/coffeebean4

## Terminal 1 : start the chaincode
CHAINCODE_FOLDER=foreigntrade
CHAINCODE_PATH=~/src/blk/foreign-trade-mine/chaincode/
CHAINCODE_NAME=foreignTrade
CHANNEL_NAME=mychannel

cd ${CHAINCODE_PATH}${CHAINCODE_FOLDER}
go build -o ${CHAINCODE_NAME}
CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
docker exec -it\
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
  cli bash

CHAINCODE_FOLDER=foreigntrade
CHAINCODE_NAME=foreignTrade
CHANNEL_NAME=mychannel
CHAINCODE_VERSION=0
cd /opt/gopath/src/github.com/chaincode/${CHAINCODE_FOLDER}
CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=peer0.org1.example.com:7052 CORE_CHAINCODE_ID_NAME=${CHAINCODE_NAME}:$CHAINCODE_VERSION ./${CHAINCODE_NAME}

## Ternimal 2 : Instantiate the chain code
CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

docker exec -it\
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
  cli bash

CHAINCODE_FOLDER=foreigntrade
CHAINCODE_NAME=foreignTrade
CHAINCODE_VERSION=0
CHANNEL_NAME=mychannel
cd /opt/gopath/src/github.com/chaincode/${CHAINCODE_FOLDER}
peer chaincode install -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -p github.com/chaincode/${CHAINCODE_FOLDER}
TRADE_ID=001
argsstr='{"Args":["init","'"$TRADE_ID"'","TC_B_1","TC_S_1","SKU001","10","1"]}'
peer chaincode instantiate -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -c ${argsstr} -o orderer.example.com:7050 -C mychannel

## Ternimal 3: Query the chaincode

argsstr='{"Args":["query","'"$TRADE_ID"'"]}'
peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c $argsstr


echo "Waiting for instantiation request to be committed ..."
sleep 10

echo "Done"
set +x

cat <<EOF
Total setup execution time : $(($(date +%s) - starttime)) secs ...
EOF

