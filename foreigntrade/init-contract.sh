#!/usr/bin/env bash
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)
CC_SRC_LANGUAGE=javascript
CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
CC_SRC_PATH=/home/chaincode/coffeebean4

# clean the keystore
rm -rf ./hfc-key-store

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
set -x

chaincode_name=coffeebean4

echo "Installing smart contract on peer0.org1.example.com"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
    -n "$chaincode_name" \
    -v 1.0 \
    -p "$CC_SRC_PATH" \
    -l "$CC_RUNTIME_LANGUAGE"

echo "Installing smart contract on peer0.org2.example.com"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
    -n "$chaincode_name" \
    -v 1.0 \
    -p "$CC_SRC_PATH" \
    -l "$CC_RUNTIME_LANGUAGE"

echo "Installing smart contract on peer0.org3.example.com"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org3MSP \
  -e CORE_PEER_ADDRESS=peer0.org3.example.com:11051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG3_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG3_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
    -n "$chaincode_name" \
    -v 1.0 \
    -p "$CC_SRC_PATH" \
    -l "$CC_RUNTIME_LANGUAGE"

echo "Installing smart contract on peer0.org4.example.com"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org4MSP \
  -e CORE_PEER_ADDRESS=peer0.org4.example.com:13051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG4_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG4_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
    -n "$chaincode_name" \
    -v 1.0 \
    -p "$CC_SRC_PATH" \
    -l "$CC_RUNTIME_LANGUAGE"

echo "Installing smart contract on peer0.org5.example.com"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org5MSP \
  -e CORE_PEER_ADDRESS=peer0.org5.example.com:15051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG5_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG5_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
    -n "$chaincode_name" \
    -v 1.0 \
    -p "$CC_SRC_PATH" \
    -l "$CC_RUNTIME_LANGUAGE"

echo "Instantiating smart contract on mychannel"
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  cli \
  peer chaincode instantiate \
    -o orderer.example.com:7050 \
    -C mychannel \
    -n "$chaincode_name" \
    -l "$CC_RUNTIME_LANGUAGE" \
    -v 1.0 \
    -c '{"Args":[]}' \
    -P "AND('Org1MSP.member','Org2MSP.member')" \
    --tls \
    --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}

echo "Waiting for instantiation request to be committed ..."
sleep 10

echo "Done"
set +x

cat <<EOF
Total setup execution time : $(($(date +%s) - starttime)) secs ...
EOF

