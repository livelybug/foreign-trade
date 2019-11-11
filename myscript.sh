#!/usr/bin/env bash
cd /home/burt/src/blk/foreign-trade-mine/first-network/
./byfn.sh down
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images | grep fabcar | awk '{print $3}')
sudo rm -rf ../first-network/shared/ca/fabric-ca-server.db
sudo rm -rf ../first-network/shared/ca/Issue*

# fabcar start
# chaincode in chaincode/fabcar/go
cd ../fabcar/
./startFabric.sh javascript false &

cd javascript
rm -rf wallet/
npm install
node enrollAdmin.js
node registerUser.js
node query.js
node invoke.js
# fabcar end

# fabcar single org start
# chaincode in chaincode/fabcar/go
cd ../fabcar/
./startFabric-single.sh javascript &

cd javascript
rm -rf wallet/
npm install
node enrollAdmin.js
node registerUser.js
node query.js
node invoke.js
# fabcar single org end


## coffeebean start
cd /home/burt/src/blk/fabric-samples/basic-network
docker exec -it cli bash
peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
peer channel join -b mychannel.block
peer channel update -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/Org1MSPanchors.tx
peer chaincode install -n coffeebean4 -v 0 -p /opt/gopath/src/github.com/coffeebean4 -l node
peer chaincode instantiate -o orderer.example.com:7050 -n coffeebean4 -v 0 -l node -c '{"Args":["org.mycontract:instantiate"]} ' -C mychannel -P "AND ('Org1MSP.member')"
## coffeebean end

# Commercial paper start
# --------------------Terminal 1
mkdir -p $GOPATH/src/github.com/hyperledger/
cd $GOPATH/src/github.com/hyperledger/
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples/basic-network
./start.sh
docker network inspect net_basic
# --------------------Terminal 1

# --------------------Terminal 2
cd commercial-paper/organization/magnetocorp/configuration/cli/
./monitordocker.sh net_basic
# --------------------Terminal 2

# --------------------Terminal 3
docker-compose -f docker-compose.yml up -d cliMagnetoCorp
docker exec cliMagnetoCorp peer chaincode install -n papercontract -v 0 -p /opt/gopath/src/github.com/contract -l node
docker exec cliMagnetoCorp peer chaincode install -n papercontract -v 0 -p /opt/gopath/src/github.com/commercial_paper/contract/ -l node
docker exec cliMagnetoCorp peer chaincode instantiate -n papercontract -v 0 -l node -c '{"Args":["org.papernet.commercialpaper:instantiate"]} ' -C mychannel -P "AND ('Org1MSP.member')"
# --------------------Terminal 3

# --------------------Terminal 4
# --------------------Work as Magneto

cd ../../application
npm install
node addToWallet.js
ls ../identity/user/isabella/wallet/
node issue.js
#Process issue transaction response.
#{
#	"class": "org.papernet.commercialpaper",
#	"key": "\"MagnetoCorp\":\"00001\"",
#	"currentState": 1,
#	"issuer": "MagnetoCorp",
#	"paperNumber": "00001",
#	"issueDateTime": "2020-05-31",
#	"maturityDateTime": "2020-11-30",
#	"faceValue": "5000000",
#	"owner": "MagnetoCorp"
#}

# --------------------Terminal 4

# --------------------Terminal 5
# --------------------Work as Digibank
cd ../../application
npm install
node addToWallet.js
node buy.js
node redeem.js
# --------------------Terminal 5


# Commercial paper end


# Simple Asset Chaincode begin
# --------------------Terminal 0 Building Chaincode
mkdir -p $GOPATH/src/sacc && cd $GOPATH/src/sacc
touch sacc.go
sudo go get -u github.com/hyperledger/fabric/core/chaincode/shim
go build
# --------------------Terminal 0 Building Chaincode

# --------------------Terminal 1 Install Hyperledger Fabric Samples
cd chaincode-docker-devmode
docker-compose -f docker-compose-simple.yaml up
# --------------------Terminal 1 Install Hyperledger Fabric Samples

# --------------------Terminal 2 Build & start the chaincode
docker exec -it chaincode bash
cd sacc
go build
CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=mycc:0 ./sacc
# --------------------Terminal 2 Build & start the chaincode

# --------------------Terminal 3 - Use the chaincode
docker exec -it cli bash
peer chaincode install -p chaincodedev/chaincode/sacc -n mycc -v 0
peer chaincode instantiate -n mycc -v 0 -c '{"Args":["a","10"]}' -C myc
peer chaincode invoke -n mycc -c '{"Args":["set", "a", "20"]}' -C myc
peer chaincode query -n mycc -c '{"Args":["query","a"]}' -C myc
# --------------------Terminal 3 - Use the chaincode

# Simple Asset Chaincode end

# Query the CouchDB State Database
# --------------------Terminal 1
# Start the network
cd /home/burt/src/blk/fabric-samples/first-network
./byfn.sh down
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images | grep fabcar | awk '{print $3}')
./byfn.sh up -c mychannel -s couchdb
docker exec -it cli bash
# Query couchdb by index
peer chaincode install -n marbles -v 1.0 -p github.com/chaincode/marbles02/go
export CHANNEL_NAME=mychannel
peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /home/fabric/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n marbles -v 1.0 -c '{"Args":["init"]}' -P "OR ('Org0MSP.peer','Org1MSP.peer')"
peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /home/fabric/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n marbles -c '{"Args":["initMarble","marble1","blue","35","tom"]}'
peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}'

# Query the CouchDB State Database


# Develop the chaincode in dev mode -- Start
# * Set disable TLS of fabric network
# * Set the peer in dev mode
# * Start the network
## Terminal 1 : start the chaincode
cd ~/src/blk/foreign-trade-mine/chaincode/fabcar/go
rm -f fabCar02
go build -o fabCar02
CONFIG_ROOT=/home/fabric
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
docker exec -it\
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
  cli bash
cd /opt/gopath/src/github.com/chaincode/fabcar/go
CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_ADDRESS=peer0.org1.example.com:7052 CORE_CHAINCODE_ID_NAME=fabCarGo:0 ./fabCar02

## Ternimal 2 : Use the chain code
CONFIG_ROOT=/home/fabric
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

docker exec -it\
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
  cli bash

cd /opt/gopath/src/github.com/chaincode/fabcar/go
peer chaincode install -n fabCarGo -v 0 -p github.com/chaincode/fabcar/go
peer chaincode instantiate -n fabCarGo -v 0 -c '{"Args":[]}' -o orderer.example.com:7050 -C mychannel

peer chaincode invoke \
  -o orderer.example.com:7050 \
  -C mychannel \
  -n fabCarGo \
  -c '{"function":"initLedger","Args":[]}' \
  --waitForEvent

## Ternimal 3 : Query the chain code
CONFIG_ROOT=/home/fabric
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
chaincode_name=fabCarGo
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  cli \
  peer chaincode invoke \
    -o orderer.example.com:7050 \
    -C mychannel \
    -n "$chaincode_name" \
    -c '{"function":"queryAllCars","Args":[]}' \
    --waitForEvent

# Develop the chaincode in dev mode -- End

