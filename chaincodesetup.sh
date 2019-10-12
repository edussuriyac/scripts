export IMAGE_TAG=latest
export SYS_CHANNEL=byfn-sys-channel
export COMPOSE_PROJECT_NAME=nck
export CHANNEL_NAME=nckchannel

docker-compose -f docker-compose-cli.yaml up -d
docker-compose -f docker-compose-cli.yaml -f docker-compose-couch.yaml up -d

export CHANNEL_NAME=nckchannel
export WAREHOUSE_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/warehouse.nck.com/users/Admin@warehouse.nck.com/msp
export WAREHOUSE_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/warehouse.nck.com/peers/peer0.warehouse.nck.com/tls/ca.crt

export SUPPLIER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.nck.com/users/Admin@supplier.nck.com/msp 
export SUPPLIER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/supplier.nck.com/peers/peer0.supplier.nck.com/tls/ca.crt

export ISSUER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/issuer.nck.com/users/Admin@issuer.nck.com/msp 
export ISSUER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/issuer.nck.com/peers/peer0.issuer.nck.com/tls/ca.crt

export ORDERER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/nck.com/orderers/orderer.nck.com/msp/tlscacerts/tlsca.nck.com-cert.pem

echo "install channel"
docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_ADDRESS=peer0.warehouse.nck.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=$WAREHOUSE_MSPCONFIGPATH \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${WAREHOUSE_TLS_ROOTCERT_FILE} \
  cli \
  peer channel create \
    -o orderer.nck.com:7050 \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/channel.tx \
    --tls --cafile $ORDERER_TLS_ROOTCERT_FILE

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_ADDRESS=peer0.warehouse.nck.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${WAREHOUSE_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${WAREHOUSE_TLS_ROOTCERT_FILE} \
  cli \
  peer channel join \
    -b nckchannel.block 

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="SupplierMSP" \
  -e CORE_PEER_ADDRESS=peer0.supplier.nck.com:9051  \
  -e CORE_PEER_MSPCONFIGPATH=${SUPPLIER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${SUPPLIER_TLS_ROOTCERT_FILE} \
  cli \
  peer channel join \
  -b nckchannel.block 

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="IssuerMSP"  \
  -e CORE_PEER_ADDRESS=peer0.issuer.nck.com:10151  \
  -e CORE_PEER_MSPCONFIGPATH=${ISSUER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ISSUER_TLS_ROOTCERT_FILE} \
  cli \
  peer channel join \
  -b nckchannel.block 
  

echo "anchor peers"
docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_ADDRESS=peer0.warehouse.nck.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${WAREHOUSE_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${WAREHOUSE_TLS_ROOTCERT_FILE} \
  cli \
  peer channel update \
    -o orderer.nck.com:7050 \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/WarehouseMSPanchors.tx \
    --tls --cafile $ORDERER_TLS_ROOTCERT_FILE 

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="SupplierMSP" \
  -e CORE_PEER_ADDRESS=peer0.supplier.nck.com:9051  \
  -e CORE_PEER_MSPCONFIGPATH=${SUPPLIER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${SUPPLIER_TLS_ROOTCERT_FILE} \
  cli \
  peer channel update \
    -o orderer.nck.com:7050 \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/SupplierMSPanchors.tx \
    --tls --cafile $ORDERER_TLS_ROOTCERT_FILE 

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="IssuerMSP"  \
  -e CORE_PEER_ADDRESS=peer0.issuer.nck.com:10151  \
  -e CORE_PEER_MSPCONFIGPATH=${ISSUER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ISSUER_TLS_ROOTCERT_FILE} \
  cli \
  peer channel update \
  -o orderer.nck.com:7050 \
  -c $CHANNEL_NAME \
  -f ./channel-artifacts/IssuerMSPanchors.tx \
  --tls --cafile ${ORDERER_TLS_ROOTCERT_FILE} 

#chaincode
echo "install chaincode in the peers"
docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_ADDRESS=peer0.warehouse.nck.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${WAREHOUSE_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${WAREHOUSE_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
  -n nckcc \
  -v 1.0 \
  -l node \
  -p /opt/gopath/src/github.com/contract

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="SupplierMSP" \
  -e CORE_PEER_ADDRESS=peer0.supplier.nck.com:9051  \
  -e CORE_PEER_MSPCONFIGPATH=${SUPPLIER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${SUPPLIER_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
   -n nckcc \
   -v 1.0 \
   -l node \
   -p /opt/gopath/src/github.com/contract

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="IssuerMSP"  \
  -e CORE_PEER_ADDRESS=peer0.issuer.nck.com:10151  \
  -e CORE_PEER_MSPCONFIGPATH=${ISSUER_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ISSUER_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode install \
   -n nckcc \
   -v 1.0 \
   -l node \
   -p /opt/gopath/src/github.com/contract

#chaincode commands
docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_MSPCONFIGPATH=${WAREHOUSE_MSPCONFIGPATH} \
  cli \
  peer chaincode instantiate \
    -o orderer.nck.com:7050 \
    -C nckchannel \
    -n nckcc \
    -l node \
    -v 1.0 \
    -c '{"Args":[]}' \
    -P "AND ('WarehouseMSP.peer')" \
    --tls \
    --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
    --peerAddresses peer0.warehouse.nck.com:7051 \
    --tlsRootCertFiles ${WAREHOUSE_TLS_ROOTCERT_FILE} 

docker exec \
  -e CHANNEL_NAME=nckchannel \
  -e CORE_PEER_LOCALMSPID="WarehouseMSP" \
  -e CORE_PEER_ADDRESS=peer0.warehouse.nck.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${WAREHOUSE_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${WAREHOUSE_TLS_ROOTCERT_FILE} \
  cli \
  peer chaincode invoke \
    -o orderer.nck.com:7050 \
    -C nckchannel \
    -n nckcc \
    -c '{"function":"initLedger","Args":[]}' \
    --waitForEvent \
    --tls \
    --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
    --peerAddresses peer0.warehouse.nck.com:7051 \
    --peerAddresses peer0.supplier.nck.com:9051 \
    --peerAddresses peer0.issuer.nck.com:10151 \
    --tlsRootCertFiles ${WAREHOUSE_TLS_ROOTCERT_FILE} \
    --tlsRootCertFiles ${SUPPLIER_TLS_ROOTCERT_FILE} \
    --tlsRootCertFiles ${ISSUER_TLS_ROOTCERT_FILE}

