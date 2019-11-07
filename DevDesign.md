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

##### Trade Flow
* Exporter initiated a contract, with price
* Importer confirms the price in the contract
* The importer bank issues a letter of credit(LOC) to the exporter bank
* The exporter bank validates the letter of credit
* The seller/exporter approves the same LOC
* The seller/exporter initiates the shipment
* The shipping firm scans the goods and prepare the bill of lading. Starts the shipment.
* The buyer receives the goods and endorses the BOL
* Payment is made to the seller

##### Home Page
* Exporter initiates a quotation, with product name, product price, shipping price
* Importer consents to the quotation

#### Organization Name Mapping 
* org1 -> importer, 
* org2 -> importer bank
* org3 -> exporter
* org4 -> exporter bank
* org5 -> logistic


### Version 2

* Use feature "Organizational Units" to separate banks for importers and exporters 

### Version 3

- Add a new organization: quality regulator 

### Version 4

- Change orderer type: solo -> Raft? 

