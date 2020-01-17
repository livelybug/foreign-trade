/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway, X509WalletMixin, InMemoryWallet } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const orgNum = 5;
const orgName = 'org' + orgNum;
const connetionFileName = 'connection-org' + orgNum + '.json';
const ccpPath = path.resolve(__dirname, '..', '..', 'first-network', connetionFileName);

const userName='user3';
async function main() {
    try {
        const walletPath = path.join(process.cwd(), 'wallet', orgName);
        const userWalletPath = path.join(walletPath, userName);
        const certNames = [];
        let [priKey, pubKey, mspId, cerPem] = [null, null, null, null];

        fs.readdirSync(userWalletPath).forEach(file => {
            certNames.push(file);
            if(certNames.length > 3)  throw Error ('Incorrect certificate pack, the number of files inside should be 3!');
            console.log(file);
            const filePath = path.join(userWalletPath, file);

            if(file.endsWith('-priv')) {
                priKey = fs.readFileSync(filePath, 'utf8');
                console.log(priKey)
            }
            else if(file.endsWith('-pub')) {
                pubKey = fs.readFileSync(filePath, 'utf8');
                console.log(pubKey)
            }
            else if(file === userName) {
                const userInfo = fs.readFileSync(filePath, 'utf8');
                mspId = JSON.parse(userInfo).mspid;
                cerPem = JSON.parse(userInfo).enrollment.identity.certificate;
                console.log(mspId);
            }
        });

        if(priKey && pubKey && mspId && cerPem === false) throw Error ('Corrupted certificate pack!');

        const wallet = new InMemoryWallet();
        await wallet.import(userName, X509WalletMixin.createIdentity(mspId, cerPem, priKey));

        const gateway = new Gateway();
        await gateway.connect(ccpPath, { wallet, identity: userName, discovery: { enabled: true, asLocalhost: true } });
        const network = await gateway.getNetwork('mychannel');
        const contract = network.getContract('fabcar');
        let result = await contract.evaluateTransaction('queryCar', 'CAR4');
        console.log(`Query CAR12, result is: ${result.toString()}`);
        result = await contract.evaluateTransaction('queryAllCars');
        console.log(`Query all, result is: ${result.toString()}`);

    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        process.exit(1);
    }
}

main();
