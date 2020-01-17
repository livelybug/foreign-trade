package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/lib/cid"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type TradeContract struct {
}

type TradeStatus int

const (
	TradeInitiated    TradeStatus = 0
	QuotationAccepted TradeStatus = 1
	LOC_Created       TradeStatus = 2
	LOC_Validated     TradeStatus = 3
	LOC_Approved      TradeStatus = 4
	ShipmentInit      TradeStatus = 5
	BOL_Initiated     TradeStatus = 6
	BOL_Endorsed      TradeStatus = 7
	PaymentMade       TradeStatus = 8
	TradeConcluded    TradeStatus = 9
	TradeError        TradeStatus = 99
)

type trade struct {
	TradeId         string      //used
	BuyerOrgId      string      //used
	SellerOrgId     string      //used
	BuyerBankOrgId  string      // used
	SellerBankOrgId string      // used
	Status          TradeStatus // used

	ShipperId    string
	DeliveryDate string
	Skuid        string //used

	TradePrice    int //used
	ShippingPrice int //used
}

var importerId, importerBankId, exporterId, exporterBankId, logisticId = "Org1MSP", "Org2MSP", "Org3MSP", "Org4MSP", "Org5MSP"

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
		return t.validateLOC(stub, args)
	} else if function == "approveLOC" {
		return t.approveLOC(stub, args)
	} else if function == "initiateShipment" {
		return t.initiateShipment(stub, args)
	} else if function == "init_BOL" {
		return t.init_BOL(stub, args)
	} else if function == "endorse_BOL" {
		return t.endorse_BOL(stub, args)
	} else if function == "makePayment" {
		return t.makePayment(stub, args)
	} else if function == "concludeTrade" {
		return t.concludeTrade(stub, args)
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
	if mspid != exporterId {
		return shim.Error(fmt.Sprintf("%s is not allowed to init a trade, only %s is allowed", mspid, exporterId))
	}
	_, args := stub.GetFunctionAndParameters()
	tradeId := args[0]
	buyerOrgId := args[1]
	sellerOrgId := args[2]
	skuid := args[5]
	tradePrice, _ := strconv.Atoi(args[6])
	shippingPrice, _ := strconv.Atoi(args[7])
	buyerBankOrgId := args[3]
	sellerBankOrgId := args[4]
	shipperId := args[8]

	tradeContract := trade{
		TradeId:         tradeId,
		BuyerOrgId:      buyerOrgId,
		SellerOrgId:     sellerOrgId,
		BuyerBankOrgId:  buyerBankOrgId,
		SellerBankOrgId: sellerBankOrgId,
		Skuid:           skuid,
		TradePrice:      tradePrice,
		ShippingPrice:   shippingPrice,
		ShipperId:       shipperId,
		Status:          TradeInitiated}

	tcBytes, _ := json.Marshal(tradeContract)
	stub.PutState(tradeContract.TradeId, tcBytes)

	return shim.Success(nil)
}

func (t *TradeContract) acceptQuotation(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	cert, err := cid.GetX509Certificate(stub)
	if err != nil {
		fmt.Printf("Faile to get X509 certificate, error: %v", err)
		return shim.Error(err.Error())
	}
	str, err := json.Marshal(cert)
	if err != nil {
		fmt.Printf("Fail to marshal certificate, error: %v", err)
		return shim.Error(err.Error())
	}
	fmt.Println(string(str))

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != importerId {
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
		return shim.Error("Trade not initiated yet")
	}

	tcBytes, _ = json.Marshal(tc)
	stub.PutState(tradeId, tcBytes)
	fmt.Println("Quotation accepted!")

	return shim.Success(nil)
}

func (t *TradeContract) createLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != importerBankId {
		return shim.Error(fmt.Sprintf("%s is not allowed to create LOC, only %s is allowed", mspid, importerBankId))
	}

	tradeId := args[0]
	tcBytes, _ := stub.GetState(tradeId)
	tc := trade{}
	json.Unmarshal(tcBytes, &tc)

	if tc.Status == QuotationAccepted {
		tc.BuyerBankOrgId = mspid
		tc.Status = LOC_Created
	} else {
		tc.Status = TradeError
		return shim.Error("Quotation not accepted yet")
	}

	tcBytes, _ = json.Marshal(tc)
	stub.PutState(tradeId, tcBytes)
	fmt.Println("LOC created!")

	return shim.Success(nil)
}

func (t *TradeContract) validateLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != exporterBankId {
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
		tc.Status = LOC_Validated
	} else {
		tc.Status = TradeError
		return shim.Error("LOC not created yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("LOC validated!")

	return shim.Success(nil)
}

func (t *TradeContract) approveLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != importerId {
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
		return shim.Error("LOC not validated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("LOC approved!")

	return shim.Success(nil)
}

func (t *TradeContract) initiateShipment(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != exporterId {
		return shim.Error(fmt.Sprintf("%s is not allowed to init shipment, only %s is allowed", mspid, exporterId))
	}

	tradeId := args[0]
	dateStr := args[1]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == LOC_Approved {
		const shortForm = "2006-01-02"
		current := time.Now()
		deliveryDate, err := time.Parse(shortForm, dateStr)
		if err != nil {
			return shim.Error(err.Error())
		}
		if current.After(deliveryDate) {
			return shim.Error(fmt.Sprintf("Delivery date %s cannot be earlier than current date %s", deliveryDate.Format(dateStr), current.Format(shortForm)))
		}

		// 		tc.DeliveryDate = deliveryDate.Format(""2013-01-03"")
		tc.DeliveryDate = deliveryDate.Format(shortForm)
		tc.Status = ShipmentInit
	} else {
		tc.Status = TradeError
		return shim.Error("LOC not approved yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	fmt.Println("Shipment initiated!")

	return shim.Success(nil)
}

func (t *TradeContract) init_BOL(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != logisticId {
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
		return shim.Error("Shipment not initiated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	fmt.Println("BOL initiated!")

	return shim.Success(nil)
}

func (t *TradeContract) endorse_BOL(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != importerId {
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
		return shim.Error("BOL not initiated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	fmt.Println("BOL endorsed!")

	return shim.Success(nil)
}

func (t *TradeContract) makePayment(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != exporterId {
		return shim.Error(fmt.Sprintf("%s is not allowed to , only %s is allowed", mspid, importerId))
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
	} else {
		return shim.Error("BOL not endorsed yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	fmt.Println("Payment made!")

	return shim.Success(nil)
}

func (t *TradeContract) concludeTrade(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != exporterId {
		return shim.Error(fmt.Sprintf("%s is not allowed to , only %s is allowed", mspid, exporterId))
	}

	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if tc.Status == PaymentMade {
		tc.Status = TradeConcluded
	} else {
		return shim.Error("Payment not made yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	fmt.Println("Trade concluded!")

	return shim.Success(nil)
}

func (t *TradeContract) resetState(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	mspid, err := cid.GetMSPID(stub)
	if err != nil {
		return shim.Error(err.Error())
	}
	if mspid != exporterId {
		return shim.Error(fmt.Sprintf("%s is not allowed to init a trade, only %s is allowed", mspid, exporterId))
	}
	//_, args := stub.GetFunctionAndParameters()
	tradeId := args[0]
	buyerOrgId := args[1]
	sellerOrgId := args[2]
	skuid := args[5]
	tradePrice, _ := strconv.Atoi(args[6])
	shippingPrice, _ := strconv.Atoi(args[7])
	buyerBankOrgId := args[3]
	sellerBankOrgId := args[4]
	shipperId := args[8]
	newState, _ := strconv.Atoi(args[9])

	tradeContract := trade{
		TradeId:         tradeId,
		BuyerOrgId:      buyerOrgId,
		SellerOrgId:     sellerOrgId,
		BuyerBankOrgId:  buyerBankOrgId,
		SellerBankOrgId: sellerBankOrgId,
		Skuid:           skuid,
		TradePrice:      tradePrice,
		ShippingPrice:   shippingPrice,
		ShipperId:       shipperId,
		Status:          TradeStatus(newState)}

	tcBytes, _ := json.Marshal(tradeContract)
	stub.PutState(tradeContract.TradeId, tcBytes)
	fmt.Println("Trade reset")

	return shim.Success(nil)
}

func (t *TradeContract) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	cert, err1 := cid.GetX509Certificate(stub)
	if err1 != nil {
		fmt.Printf("Faile to get X509 certificate, error: %v", err1)
		return shim.Error(err1.Error())
	}
	str, err1 := json.Marshal(cert)
	if err1 != nil {
		fmt.Printf("Fail to marshal certificate, error: %v", err1)
		return shim.Error(err1.Error())
	}
	fmt.Println(string(str))

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
		fmt.Println("Error creating new Trade Contract: %s", err)
	}
}
