# Hyperledger Fabric Client Based On Electron

## Getting Started (Ubuntu 16.05)

### Prerequisites
* [Install Samples, Binaries and Docker Images](https://hyperledger-fabric.readthedocs.io/en/release-1.4/install.html)

### Running The Code
#### Start Fabric Network
```bash
git clone https://github.com/livelybug/foreign-trade.git
cd foreign-trade/fabcar
./startFabric.sh javascript
# Waiting for commands to complete ...
```

#### Register A User
```bash
cd javascript
rm -rf wallet/
npm install
node enrollAdmin.js
node registerUser.js
```

#### Package Certificates
```bash
# Goto repository root
cd fabcar/javascript/wallet/org5/user5
# Compress the 3 files into a zip file without folders. I saved it as "user5.zip" for latter reference
# My files names: a7c98bad3a266d674e1eba99324081213c54023afd46bdac9983a90eba542d8b-priv  a7c98bad3a266d674e1eba99324081213c54023afd46bdac9983a90eba542d8b-pub  user5
# Yours maybe different
```

#### Start Electron Client
* Please refer to the [client's readme](frontend/my-app/README.md)
* Use the "user5.zip" created above to login
