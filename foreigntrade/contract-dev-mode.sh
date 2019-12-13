#!/usr/bin/env bash
set +e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)
CC_SRC_LANGUAGE=golang
CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
CC_SRC_PATH=/opt/gopath/src/github.com/coffeebean4

## Terminal 1 : start the chaincode
CHAINCODE_FOLDER=foreigntrade
CHAINCODE_PATH=~/src/blk/foreign-trade-mine/chaincode/
CHAINCODE_NAME=foreignTrade
CHANNEL_NAME=mychannel
CHAINCODE_VERSION=1

cd ${CHAINCODE_PATH}${CHAINCODE_FOLDER}
rm -f ${CHAINCODE_NAME}
go build -o ${CHAINCODE_NAME}
CONFIG_ROOT=/home/fabric
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
docker exec\
  -e CORE_PEER_LOCALMSPID=Org3MSP \
  -e CORE_PEER_ADDRESS=peer0.org3.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG3_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG3_TLS_ROOTCERT_FILE} \
  cli bash -c \
  "CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=peer0.org3.example.com:11052 CORE_CHAINCODE_ID_NAME=${CHAINCODE_NAME}:$CHAINCODE_VERSION /opt/gopath/src/github.com/${CHAINCODE_FOLDER}/${CHAINCODE_NAME}"

## Ternimal 2 : Instantiate the chain code
CONFIG_ROOT=/home/fabric
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
ORG2_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
ORG2_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
ORG3_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
ORG3_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
ORG4_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
ORG4_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
ORG5_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org5.example.com/users/Admin@org5.example.com/msp
ORG5_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt
ORDERER_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
CHAINCODE_FOLDER=foreigntrade
CHAINCODE_NAME=foreignTrade
CHAINCODE_VERSION=1
CHANNEL_NAME=mychannel
TRADE_ID=1

docker exec \
  -e CORE_PEER_LOCALMSPID=Org3MSP \
  -e CORE_PEER_ADDRESS=peer0.org3.example.com:11051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG3_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG3_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -p github.com/${CHAINCODE_FOLDER}

argsstr='{"Args":["init","'"$TRADE_ID"'","Org1MSP","Org3MSP","Org2MSP","Org4MSP","SKU001","1599","89","0"]}'

docker exec \
  -e CORE_PEER_LOCALMSPID=Org3MSP \
  -e CORE_PEER_ADDRESS=peer0.org3.example.com:11051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG3_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG3_TLS_ROOTCERT_FILE} \
  cli \
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

