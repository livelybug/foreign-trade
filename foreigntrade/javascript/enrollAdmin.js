/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet, X509WalletMixin } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const orgNum = 5;
const caName = 'ca.org' + orgNum + '.example.com';
const mspId = 'Org' + orgNum + 'MSP';
const connetionFileName = 'connection-org' + orgNum + '.json';
const orgName = 'org' + orgNum;

const adminName = 'admin';
const ccpPath = path.resolve(__dirname, '..', '..', 'first-network', connetionFileName);
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

async function main() {
    try {

        // Create a new CA client for interacting with the CA.
        const caInfo = ccp.certificateAuthorities[caName];
        const caTLSCACerts = caInfo.tlsCACerts.pem;
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet', orgName);
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the admin user.
        const adminExists = await wallet.exists(adminName);
        if (adminExists) {
            console.log(`An identity for the admin user ${adminName} already exists in the wallet`);
            return;
        }

        // Enroll the admin user, and import the new identity into the wallet.
        const enrollment = await ca.enroll({ enrollmentID: adminName, enrollmentSecret: 'adminpw' });
        const identity = X509WalletMixin.createIdentity(mspId, enrollment.certificate, enrollment.key.toBytes());
        await wallet.import(adminName, identity);
        console.log(`Successfully enrolled admin user ${adminName} and imported it into the wallet`);

    } catch (error) {
        console.error(`Failed to enroll admin user "admin": ${error}`);
        process.exit(1);
    }
}

main();
