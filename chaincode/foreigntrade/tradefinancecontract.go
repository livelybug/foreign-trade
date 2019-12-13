package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
    "github.com/hyperledger/fabric/core/chaincode/lib/cid"
)

type TradeContract struct {
}

type TradeStatus int

const (
   TradeInitiated    TradeStatus = 0
   QuotationAccepted    TradeStatus = 1
   LOC_Created   TradeStatus = 2
   LOC_Validated TradeStatus = 3
   LOC_Approved  TradeStatus = 4
   ShipmentInit    TradeStatus = 5
   BOL_Initiated  TradeStatus = 6
   BOL_Endorsed  TradeStatus = 7
   PaymentMade  TradeStatus = 8
   TradeCompleted  TradeStatus = 9
   TradeError  TradeStatus = 99
)

type trade struct {
	TradeId      string //used
	BuyerOrgId   string //used
	Skuid        string //used
	SellerOrgId  string //used
	ExportBankId string // used
	ImportBankId string // used
	DeliveryDate string
	ShipperId    string
	Status       TradeStatus // used
    BuyerBankOrgId    string // used
    SellerBankOrgId   string // used

	TradePrice    int //used
	ShippingPrice int //used

}

var importerId, importerBankId, exporterId, exporterBankId, logisticId = "Org1MSP", "Org2MSP", "Org3MSP", "Org4MSP", "Org5MSP";

func (t *TradeContract) Init(stub shim.ChaincodeStubInterface) pb.Response {
    fmt.Println("Chaincode instantiated.")
	return setupTrade(stub)
}

func (t *TradeContract) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println("Chaincode invoked.")
    if function == "acceptQuotation" {
		return t.acceptQuotation(stub, args)
	} else if function == "createLOC" {
		return t.createLOC(stub, args)
	} else if function == "validateLOC" {
		return t.approveLOC(stub, args)
	} else if function == "approveLOC" {
		return t.approveLOC(stub, args)
	} else if function == "initiateShipment" {
		return t.initiateShipment(stub, args)
	} else if function == "deliverGoods" {
		return t.init_BOL(stub, args)
	} else if function == "shipmentDelivered" {
		return t.endorse_BOL(stub, args)
	} else if function == "makePayment" {
		return t.makePayment(stub, args)
	} else if function == "resetState" {
		return t.resetState(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}
	return shim.Error("Invalid function name")
}

func setupTrade(stub shim.ChaincodeStubInterface) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != exporterId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to init a trade, only %s is allowed", mspid, exporterId))
    }
	_, args := stub.GetFunctionAndParameters()
	tradeId := args[0]
	buyerOrgId := args[1]
	sellerOrgId := args[2]
	skuid := args[3]
	tradePrice, _ := strconv.Atoi(args[4])
	shippingPrice, _ := strconv.Atoi(args[5])
	buyerBankOrgId := args[6]
	sellerBankOrgId := args[7]

	tradeContract := trade{
		TradeId:       tradeId,
		BuyerOrgId:    buyerOrgId,
		SellerOrgId:   sellerOrgId,
		BuyerBankOrgId:    buyerBankOrgId,
		SellerBankOrgId:   sellerBankOrgId,
		Skuid:         skuid,
		TradePrice:    tradePrice,
		ShippingPrice: shippingPrice,
		Status:        TradeInitiated}

	tcBytes, _ := json.Marshal(tradeContract)
	stub.PutState(tradeContract.TradeId, tcBytes)

	return shim.Success(nil)
}

func (t *TradeContract) acceptQuotation(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != importerId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to accept a quotation, only %s is allowed", mspid, importerId))
    }

	tradeId := args[0]
	tcBytes, _ := stub.GetState(tradeId)
	tc := trade{}
	json.Unmarshal(tcBytes, &tc)

	if tc.Status == TradeInitiated {
		tc.Status = QuotationAccepted
	} else {
		tc.Status = TradeError
		fmt.Printf("Trade not initiated yet")
	}

	tcBytes, _ = json.Marshal(tc)
	stub.PutState(tradeId, tcBytes)

	return shim.Success(nil)
}

func (t *TradeContract) createLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != importerBankId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to create LOC, only %s is allowed", mspid, importerBankId))
    }

	tradeId := args[0]
	tcBytes, _ := stub.GetState(tradeId)
	tc := trade{}
	json.Unmarshal(tcBytes, &tc)

	if tc.Status == QuotationAccepted {
		tc.ImportBankId = mspid
		tc.Status = LOC_Created
	} else {
		tc.Status = TradeError
		fmt.Printf("Quotation not accepted yet")
	}

	tcBytes, _ = json.Marshal(tc)
	stub.PutState(tradeId, tcBytes)

	return shim.Success(nil)
}

func (t *TradeContract) validateLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != exporterBankId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to validate LOC, only %s is allowed", mspid, exporterBankId))
    }

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == LOC_Created {
		tc.ExportBankId = mspid
		tc.Status = LOC_Validated
	} else {
		tc.Status = TradeError
		fmt.Printf("LOC not created yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (t *TradeContract) approveLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != importerId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to approve LOC, only %s is allowed", mspid, importerId))
    }

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == LOC_Validated {
		tc.Status = LOC_Approved
	} else {
		tc.Status = TradeError
		fmt.Printf("LOC not validated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (t *TradeContract) initiateShipment(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != exporterId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to init shipment, only %s is allowed", mspid, exporterId))
    }

	tradeId := args[0]
	date := args[1]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == LOC_Approved {
		current := time.Now()
		current = current.AddDate(0, 1, 0)
// 		tc.DeliveryDate = current.Format("01-02-2006")
		tc.DeliveryDate = current.Format(date)
		tc.Status = ShipmentInit
	} else {
		tc.Status = TradeError
		fmt.Printf("LOC not approved yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)

	return shim.Success(nil)
}

func (t *TradeContract) init_BOL(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != logisticId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to init shipment, only %s is allowed", mspid, logisticId))
    }

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == ShipmentInit {
		tc.ShipperId = mspid
		tc.Status = BOL_Initiated
	} else {
        tc.Status = TradeError
		fmt.Printf("Shipment not initiated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)

	return shim.Success(nil)
}

func (t *TradeContract) endorse_BOL(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != importerId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to , only %s is allowed", mspid, importerId))
    }

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == BOL_Initiated {
		tc.Status = BOL_Endorsed
	} else {
        tc.Status = TradeError
		fmt.Printf("BOL not initiated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)

	return shim.Success(nil)
}

func (t *TradeContract) makePayment(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
    if(mspid != exporterId) {
        return shim.Error(fmt.Sprintf("%s is not allowed to , only %s is allowed", mspid, exporterId))
    }

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == BOL_Endorsed {
		tc.Status = PaymentMade
		fmt.Printf("Trade complete")
	} else {
		fmt.Printf("BOL not endorsed yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)

	return shim.Success(nil)
}

func (t *TradeContract) resetState(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	buyerOrgId := args[1]
	sellerOrgId := args[2]
	skuid := args[3]
	tradePrice, _ := strconv.Atoi(args[4])
	shippingPrice, _ := strconv.Atoi(args[5])
	buyerBankOrgId := args[6]
	sellerBankOrgId := args[7]

	tradeContract := trade{
		TradeId:       tradeId,
		BuyerOrgId:    buyerOrgId,
		SellerOrgId:   sellerOrgId,
		BuyerBankOrgId:    buyerBankOrgId,
		SellerBankOrgId:   sellerBankOrgId,
		Skuid:         skuid,
		TradePrice:    tradePrice,
		ShippingPrice: shippingPrice,
		Status:        TradeInitiated}

	tcBytes, _ := json.Marshal(tradeContract)
	stub.PutState(tradeContract.TradeId, tcBytes)

	return shim.Success(nil)
}

func (t *TradeContract) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A string // Entities
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}

	A = args[0]

	// Get the state from the ledger
	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil trade for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(Avalbytes)
}

func main() {

	err := shim.Start(new(TradeContract))
	if err != nil {
		fmt.Printf("Error creating new Trade Contract: %s", err)
	}
}
