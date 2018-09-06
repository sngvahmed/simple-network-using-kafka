#!/bin/bash
echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Init network...."
echo
echo
echo

sleep 10;

function testServer() {
    echo "Waiting to server $1 ...."
    while true; do
        ss=$(nc -z -v $1 2>&1)
        if [[ $ss  = *"open"* ]]; then
            echo "Connection Open"
            return
        fi
    done
}


testServer 'orderer_orange_com:7050'
testServer 'peer0_org1_orange_com:7051'
CHANNEL_NAME="mychannel"
DELAY=3
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/orange_com/orderers/orderer_orange_com/msp/tlscacerts/tlsca.orange_com-cert.pem
echo "Channel name : "$CHANNEL_NAME

# verify the result of the end-to-end test
verifyResult () {
    if [ $1 -ne 0 ] ; then
        echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
        echo
        exit 1
    fi
}

createChannel() {
    CORE_PEER_LOCALMSPID="Org1MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/peers/peer0_org1_orange_com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/users/Admin@org1_orange_com/msp
    CORE_PEER_ADDRESS=peer0_org1_orange_com:7051
    env |grep CORE

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then   
        peer channel create -o orderer_orange_com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
    else
        peer channel create -o orderer_orange_com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    fi
    res=$?
    #cat log.txt
    verifyResult $res "Channel creation failed"
    echo "===================== Channel "$CHANNEL_NAME" is created successfully ===================== "
    echo
}

updateAnchorPeers() {
   PEER=$1
   setGlobals $PEER
   if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
      peer channel update -o orderer_orange_com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
   else
      peer channel update -o orderer_orange_com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
   fi
   res=$?
   #cat log.txt
   verifyResult $res "Anchor peer update failed"
   echo "===================== Anchor peers for org "$CORE_PEER_LOCALMSPID" on "$CHANNEL_NAME" is updated successfully ===================== "
   sleep $DELAY
   echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinWithRetry () {
   peer channel join -b $CHANNEL_NAME.block  >&log.txt
   res=$?
   #cat log.txt
   if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
      COUNTER=` expr $COUNTER + 1`
      echo "$1 failed to join the channel, Retry after 2 seconds"
      sleep $DELAY
      joinWithRetry $1
   else
      COUNTER=1
   fi
   verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."

CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/peers/peer0_org1_orange_com/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/users/Admin@org1_orange_com/msp
CORE_PEER_ADDRESS=peer0_org1_orange_com:7051
env |grep CORE
joinWithRetry "peer0_org1_orange_com"
echo "===================== peer0_org1_orange_com joined on the channel "$CHANNEL_NAME" ===================== "
echo 
sleep $DELAY


## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/peers/peer0_org1_orange_com/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1_orange_com/users/Admin@org1_orange_com/msp
CORE_PEER_ADDRESS=peer0_org1_orange_com:7051
env |grep CORE

echo
echo "========= All GOOD, network initialization execution completed =========== "
echo

exit 0
