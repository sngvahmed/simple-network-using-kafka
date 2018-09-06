configtxgen -profile OrgsChannel -outputCreateChannelTx channel.tx -channelID mychannel
configtxgen -profile OrgsChannel  -outputAnchorPeersUpdate Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
configtxgen -profile OrgsOrdererGenesis -outputBlock genesis.block

rm channel-artifacts/*
mv genesis.block channel.tx Org1MSPanchors.tx channel-artifacts/
