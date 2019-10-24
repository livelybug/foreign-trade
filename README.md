# Setup a 5 org Fabric network

## Version 1

* Orgs: importer, bank, custom, logistic firm, exporter. One peer for each org.
* Use couchdb as state database
* Install smart contract on each org
* Test smart contract by query.js
* Change the default ca affiliations for org5.

##### Login
* Fabric node SDK cannot run in browser, build electron app instead.
* Read files from zip
* Import data into memory wallet

##### Register

#### Organization Name Mapping 
* org1 -> importer, 
* org2 -> bank
* org3 -> custom
* org4 -> logistic
* org5 -> exporter

### Version 2

* Use feature "Organizational Units" to separate banks for importers and exporters 

### Version 3

- Add a new organization: quality regulator 

### Version 4

- Change orderer type: solo -> Raft? 

