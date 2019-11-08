#!/bin/bash

echo "Foreign Trade End to End Application Script."
echo
CHANNEL_NAME="mychannel"
DELAY="$2"
: ${CHANNEL_NAME:="mychannel"}
: ${TIMEOUT:="60"}
LANGUAGE="golang"  #'golang' OR 'node'
COUNTER=1
MAX_RETRY=5
#ORDERER_CA=/home/fabric/crypto/ordererOrganizations/tc.com/orderers/orderer.tc.com/msp/tlscacerts/tlsca.tc.com-cert.pem
TRADE_ID="1"
#CC_PATH="github.com/hyperledger/fabric/examples/chaincode/go/tradecontract"
#if [ "$LANGUAGE" = "node" ]; then
#CC_PATH="/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go/tradecontract"
#fi
CHAINCODE_NAME=foreignTrade
CHANNEL_NAME=mychannel
CHAINCODE_VERSION=0

echo "Channel name : "$CHANNEL_NAME

# verify end-to-end test
verifyResult () {
    if [ $1 -ne 0 ] ; then
        echo "Trace "$2" "
    echo "ERROR - FAILED to execute Foreign Trade End to End Application."
        echo
        exit 1
    fi
}

setGlobals () {

    if [ $1 -eq 0 -o $1 -eq 1 ] ; then
        CORE_PEER_LOCALMSPID="Org1MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        if [ $1 -eq 0 ]; then
            CORE_PEER_ADDRESS=peer0.org1.example.com:7051
            #CORE_PEER_CHAINCODELISTENADDRESS=peer0.cc.tc.com:7052
        else
            CORE_PEER_ADDRESS=peer1.org1.example.com:7051
            #CORE_PEER_CHAINCODELISTENADDRESS=peer1.cc.tc.com:7052
#			CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/cc.tc.com/users/Admin@cc.tc.com/msp
        fi
    elif [ $1 -eq 2 -o $1 -eq 3 ] ; then
        CORE_PEER_LOCALMSPID="Org2BANK"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/bank.com/peers/peer0.bank.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/bank.com/users/Admin@bank.com/msp
        if [ $1 -eq 2 ]; then
            CORE_PEER_ADDRESS=peer0.bank.com:7051
        else
            CORE_PEER_ADDRESS=peer1.bank.com:7051
        fi
    elif [ $1 -eq 4 -o $1 -eq 5 ] ; then
        CORE_PEER_LOCALMSPID="Org3SHF"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/shf.com/peers/peer0.shf.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/shf.com/users/Admin@shf.com/msp
        if [ $1 -eq 4 ]; then
            CORE_PEER_ADDRESS=peer0.shf.com:7051
        else
            CORE_PEER_ADDRESS=peer1.shf.com:7051
        fi

     #Importer Bank
     elif [ $1 -eq 6 ] ; then
        CORE_PEER_LOCALMSPID="Org2BANK"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/bank.com/peers/peer0.bank.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/bank.com/users/User1@bank.com/msp
        CORE_PEER_ADDRESS=peer0.bank.com:7051
        PEER=PEER2

     #Exporter Bank
     elif [ $1 -eq 7 ] ; then
        CORE_PEER_LOCALMSPID="Org2BANK"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/bank.com/peers/peer0.bank.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/bank.com/users/User2@bank.com/msp
        CORE_PEER_ADDRESS=peer1.bank.com:7051
        PEER=PEER3

     #Seller
     elif [ $1 -eq 8 ] ; then
        CORE_PEER_LOCALMSPID="Org1TC"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/cc.tc.com/peers/peer0.cc.tc.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/cc.tc.com/users/User2@cc.tc.com/msp
        CORE_PEER_ADDRESS=peer0.cc.tc.com:7051
        #CORE_PEER_CHAINCODELISTENADDRESS=peer0.cc.tc.com:7052
        PEER=PEER0

     #Shipper
     elif [ $1 -eq 9 ] ; then
        CORE_PEER_LOCALMSPID="Org3SHF"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/shf.com/peers/peer0.shf.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/shf.com/users/User1@shf.com/msp
        CORE_PEER_ADDRESS=peer0.shf.com:7051
        PEER=PEER5

    #Buyer
     elif [ $1 -eq 10 ] ; then
        CORE_PEER_LOCALMSPID="Org1TC"
        CORE_PEER_TLS_ROOTCERT_FILE=/home/fabric/crypto/peerOrganizations/cc.tc.com/peers/peer0.cc.tc.com/tls/ca.crt
        CORE_PEER_MSPCONFIGPATH=/home/fabric/crypto/peerOrganizations/cc.tc.com/users/User1@cc.tc.com/msp
        CORE_PEER_ADDRESS=peer1.cc.tc.com:7051
        #CORE_PEER_CHAINCODELISTENADDRESS=peer1.cc.tc.com:7052
        PEER=PEER1

    fi

    env |grep CORE
}

createChannel() {
    setGlobals 0

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer channel create -o orderer.tc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
    else
        peer channel create -o orderer.tc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Channel creation failed!!!"
    echo "Channel \"$CHANNEL_NAME\" is created successfully."
    echo
}



joinWithRetry () {
    peer channel join -b $CHANNEL_NAME.block  >&log.txt
    res=$?
    cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
        COUNTER=` expr $COUNTER + 1`
        echo "PEER$1 failed to join the channel, Retry after 2 seconds"
        sleep $DELAY
        joinWithRetry $1
    else
        COUNTER=1
    fi
  verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel!!!"
}

joinChannel () {
    for ch in 0 1 2 3 4 5; do
        setGlobals $ch
        joinWithRetry $ch
        echo "PEER$ch joined on the channel \"$CHANNEL_NAME\"."
        sleep $DELAY
        echo
    done
}

installChaincode () {
    PEER=$1
    setGlobals $PEER
    peer chaincode install -n foreigntradecc -v 1.0 -l $LANGUAGE -p $CC_PATH >&log.txt
    res=$?
    cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has failed!!!"
    echo "Chaincode is installed on remote peer PEER $PEER."
    echo
}

instantiateChaincode () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["init","'"$TRADE_ID"'","TC_B_1","TC_S_1","SKU001","10","1"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode instantiate -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -l $LANGUAGE -v 1.0 -c $argsstr -P "OR	('Org1TC.member','Org2BANK.member','Org3SHF.member')" >&log.txt
    else
        peer chaincode instantiate -o orderer.tc.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -l $LANGUAGE -v 1.0 -c $argsstr -P "OR ('Org1TC.member','Org2BANK.member','Org3SHF.member')" >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed."
    echo "Chaincode Instantiation on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
    echo
}

resetChaincodeState () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["resetState","'"$TRADE_ID"'","TC_B_1","TC_S_1","SKU001","10","1"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed."
    echo "Chaincode Instantiation on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
    echo
}

chaincodeQuery () {
  PEER=$1
  echo "Querying on PEER$PEER on channel '$CHANNEL_NAME'."
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  argsstr='{"Args":["query","'"$TRADE_ID"'"]}'
  #Take time to sync across nodes
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
  done
  echo
  cat log.txt
}

chaincodeInvokeCreateLOC() {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["createLOC","'"$TRADE_ID"'"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Invoke:createLOC execution on PEER$PEER failed!!!"
    echo "Invoke:createLOC transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
    echo
}

chaincodeInvokeApproveLOC () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["approveLOC","'"$TRADE_ID"'"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Invoke:approveLOC execution on PEER$PEER failed!!!"
    echo "Invoke:approveLOC transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
    echo
}

chaincodeInvokeInitiateShipment () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["initiateShipment","'"$TRADE_ID"'"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Invoke:initiateShipment execution on PEER$PEER failed!!!"
    echo "Invoke:initiateShipment transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
    echo
}

chaincodeInvokeDeliverGoods () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["deliverGoods","'"$TRADE_ID"'"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Invoke:deliverGoods execution on PEER$PEER failed!!!"
    echo "Invoke:deliverGoods transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
    echo
}


chaincodeInvokeShipmentDelivered () {
    PEER=$1
    setGlobals $PEER
    argsstr='{"Args":["shipmentDelivered","'"$TRADE_ID"'"]}'
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        peer chaincode invoke -o orderer.tc.com:7050 -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    else
        peer chaincode invoke -o orderer.tc.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n foreigntradecc -c $argsstr >&log.txt
    fi
    res=$?
    cat log.txt
    verifyResult $res "Invoke:shipmentDelivered execution on PEER$PEER failed!!!"
    echo "Invoke:shipmentDelivered transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
    echo
}


#echo "Creating channel."
#createChannel
#
#echo "Peers joining the channel."
#joinChannel


echo "Installing chaincode on Org1TC/peer0."
installChaincode 0
echo "Installing chaincode on Org1TC/peer1."
installChaincode 1
echo "Install chaincode on Org2BANK/peer0."
installChaincode 2
echo "Installing chaincode on Org2BANK/peer1."
installChaincode 3
echo "Installing chaincode on Org3SHF/peer0."
installChaincode 4
echo "Installing chaincode on Org3SHF/peer1."
installChaincode 5
echo ---------------------------
#Instantiate chaincode
echo "Instantiating chaincode on Org1TC/peer1."
instantiateChaincode 1
echo ---------------------------
#Query chaincode on a different peer
echo "Querying chaincode on Org2BANK/peer0."
chaincodeQuery 2
echo ---------------------------

tradeRoutine()(
while [ true ]
do

#Invoke CreateLOC by Importer Bank - Org2BANK-USER1
echo "Sending Invoke-CreateLOC transaction by Org2BANK-USER1"
chaincodeInvokeCreateLOC 6
#User1 - Importer Bank
echo ---------------------------
#Query on chaincode on Org2BANK/peer0
echo "Querying chaincode on Org2BANK/peer0."
chaincodeQuery 2
echo ---------------------------
#Exporter Bank
echo "Sending  Invoke-approveLOC by Org2BANK-USER2"
chaincodeInvokeApproveLOC 7
echo ---------------------------
#Query on chaincode on Org3SHF/peer0
echo "Querying chaincode on Org3SHF/peer1."
chaincodeQuery 5
echo ---------------------------
#Seller
echo "Sending invoke-InitiateShipment by Org1TC-USER2."
chaincodeInvokeInitiateShipment 8
echo ---------------------------
#Query on chaincode on Org1TC/peer0
echo "Querying chaincode on Org1TC/peer0."
chaincodeQuery 0
echo ---------------------------
#Shipper
echo "Sending invoke-DeliverGoods by Org3SHF-USER1."
chaincodeInvokeDeliverGoods 9
#user1 - shipper
echo ---------------------------
#Query on chaincode on Org1TC/peer1
echo "Querying chaincode on Org1TC/peer1."
chaincodeQuery 1
echo ---------------------------
#Buyer
echo "Sending invoke-DeliverGoods by Org1TC-USER1."
chaincodeInvokeShipmentDelivered 10
#user1 - shipper
echo ---------------------------
echo "Querying chaincode for final status on Org1TC/peer1."
chaincodeQuery 1

echo ---------------------------
echo "Foreign Trade  End to End application completed."
echo ---------------------------

sleep 3h
TRADE_ID="$(($TRADE_ID + 1))"

#Reset chaincode state
echo "Reseting chaincode state on Org1TC/peer1."
resetChaincodeState 1
echo ---------------------------
#Query chaincode on a different peer
echo "Querying chaincode on Org2BANK/peer0."
chaincodeQuery 2
echo ---------------------------

done
)

tradeRoutine &

exit 0
