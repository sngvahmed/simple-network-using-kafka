rm -r crypto-config
rm -r channel-artifacts

mkdir crypto-config
mkdir channel-artifacts
cryptogen generate --config=crypto-config.yaml --output=crypto-config

configtxgen -profile OrgsChannel -outputCreateChannelTx channel.tx -channelID mychannel
configtxgen -profile OrgsChannel  -outputAnchorPeersUpdate Org1MSPanchors.tx -channelID mychannel -asOrg org1MSP
configtxgen -profile OrgsChannel  -outputAnchorPeersUpdate Org2MSPanchors.tx -channelID mychannel -asOrg org2MSP
configtxgen -profile OrgsOrdererGenesis -outputBlock genesis.block

mv genesis.block channel.tx Org1MSPanchors.tx channel-artifacts/
