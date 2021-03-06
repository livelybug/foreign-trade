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
CHAINCODE_VERSION=5

cd ${CHAINCODE_PATH}${CHAINCODE_FOLDER}
rm -f ${CHAINCODE_NAME}
go build -o ${CHAINCODE_NAME}
CONFIG_ROOT=/home/fabric

docker exec -e CHAINCODE_BIN=${CHAINCODE_NAME} -it\
  cli bash
  ps -ef | grep ${CHAINCODE_BIN} | awk '{print $2}' | xargs kill -9 $1
  exit
ps -ef | grep CORE_PEER_LOCALMSPID | awk '{print $2}' | xargs kill -9 $1

for orgnum in {1..5}
do
    declare ORG${orgnum}_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/users/Admin@org${orgnum}.example.com/msp
    declare ORG${orgnum}_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/peers/peer0.org${orgnum}.example.com/tls/ca.crt
    eval "value_msp=\"\${ORG${orgnum}_MSPCONFIGPATH}\""
    eval "value_tls=\"\${ORG${orgnum}_TLS_ROOTCERT_FILE}\""
    peerport=$(( 7051 + 2000 * (orgnum - 1) ))
    chaincodeport=$(( peerport + 1 ))

    docker exec\
      -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
      -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport} \
      -e CORE_PEER_MSPCONFIGPATH=${value_msp} \
      -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls} \
      cli bash -c \
      "CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${chaincodeport} CORE_CHAINCODE_ID_NAME=${CHAINCODE_NAME}:$CHAINCODE_VERSION /opt/gopath/src/github.com/${CHAINCODE_FOLDER}/${CHAINCODE_NAME}" &
done

## Ternimal 2 :
CONFIG_ROOT=/home/fabric
ORDERER_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
CHAINCODE_FOLDER=foreigntrade
CHAINCODE_NAME=foreignTrade
CHAINCODE_VERSION=5
CHANNEL_NAME=mychannel
TRADE_ID=1

# Install the chain code
for orgnum in {1..5}
do
    value_msps[${orgnum}]=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/users/Admin@org${orgnum}.example.com/msp
    value_tls[${orgnum}]=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/peers/peer0.org${orgnum}.example.com/tls/ca.crt
    peerport[${orgnum}]=$(( 7051 + 2000 * (orgnum - 1) ))

    docker exec \
      -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
      -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
      -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
      -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
      cli \
      peer chaincode install -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -p github.com/${CHAINCODE_FOLDER}
done
# Instantiate the chain code
orgnum=3
argsstr='{"Args":["init","'"$TRADE_ID"'","Org1MSP","Org3MSP","Org2MSP","Org4MSP","SKU001","1599","89","Org5MSP"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode instantiate -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Upgrade the chain code
orgnum=3
argsstr='{"Args":["init","'"$TRADE_ID"'","Org1MSP","Org3MSP","Org2MSP","Org4MSP","SKU001","1599","89","Org5MSP"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode upgrade -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Accept quotation
orgnum=1
argsstr='{"Args":["acceptQuotation","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Create LOC
orgnum=2
argsstr='{"Args":["createLOC","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Validate LOC
orgnum=4
argsstr='{"Args":["validateLOC","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Approve LOC
orgnum=1
argsstr='{"Args":["approveLOC","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Init Shipment
orgnum=3
argsstr='{"Args":["initiateShipment","'"$TRADE_ID"'","2000-02-02"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Init BOL
orgnum=5
argsstr='{"Args":["init_BOL","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Endorse BOL
orgnum=1
argsstr='{"Args":["endorse_BOL","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Pay
orgnum=1
argsstr='{"Args":["endorse_BOL","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel
# Conclude Trade
orgnum=1
argsstr='{"Args":["concludeTrade","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel



## Ternimal 3:
# Query the chaincode
CONFIG_ROOT=/home/fabric
CHAINCODE_NAME=foreignTrade
CHANNEL_NAME=mychannel
TRADE_ID=1

for orgnum in {1..5}
do
    value_msps[${orgnum}]=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/users/Admin@org${orgnum}.example.com/msp
    value_tls[${orgnum}]=${CONFIG_ROOT}/crypto/peerOrganizations/org${orgnum}.example.com/peers/peer0.org${orgnum}.example.com/tls/ca.crt
    peerport[${orgnum}]=$(( 7051 + 2000 * (orgnum - 1) ))
done

orgnum=1
argsstr='{"Args":["query","'"$TRADE_ID"'"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -c $argsstr
# Reset
orgnum=3
argsstr='{"Args":["resetState","'"$TRADE_ID"'","Org1MSP","Org3MSP","Org2MSP","Org4MSP","SKU001","1599","89","Org5MSP","4"]}'
docker exec \
  -e CORE_PEER_LOCALMSPID=Org${orgnum}MSP \
  -e CORE_PEER_ADDRESS=peer0.org${orgnum}.example.com:${peerport[${orgnum}]} \
  -e CORE_PEER_MSPCONFIGPATH=${value_msps[${orgnum}]} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${value_tls[${orgnum}]} \
  cli \
  peer chaincode invoke -n ${CHAINCODE_NAME} -c ${argsstr} -o orderer.example.com:7050 -C mychannel


echo "Waiting for instantiation request to be committed ..."
sleep 10

echo "Done"
set +x

cat <<EOF
Total setup execution time : $(($(date +%s) - starttime)) secs ...
EOF

