// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract PowerModel{
    enum OrderType { Buy, Sell }

    struct Order {

        //提交订单时间戳
        uint256 timestamp;

        //订单信息
        string orderId;


        address user;

        //数量
        uint256 quantity;

        //剩余数量
        uint256  remainingQuantity;


        //价格
        uint256 price;

        //有效期
        uint256 expirationTime;

        //主体信息
        string subjectInformation;

        //交付信息
        string deliveryInformation;

        bool initialized;

    }
}



contract PowerMarket is PowerModel{


    // 买单信息
    mapping (address=>mapping(string=>Order)) public buyOrderInfo;
    mapping (string=>Order) public allBuyOrderInfo;
    string[] public arrBuyOrderId;

    // 卖单信息
    mapping (address=>mapping(string=>Order)) public sellOrderInfo;
    mapping (string=>Order) public allSellOrderId;
    string[] public arrSellOrderId;



    function checkOrderParameter(Order memory o)public view  {
        require(bytes(o.orderId).length==0,"orderId can not empty");
        require(o.quantity > 0,"quantity needs to be greater than 0");
        require(o.price > 0,"price needs to be greater than 0");

        require(getBlockTimestamp() < o.expirationTime, "Timelock::expirationTime: has to more than blocktime.");

        require(bytes(o.subjectInformation).length==0,"subjectInformation can not empty");
        require(bytes(o.deliveryInformation).length==0,"deliveryInformation can not empty");
    }


    //###########sellOrderInfo start#######################################################
    function addSellOrderInfo(Order memory o) public {

        checkOrderParameter(o);

        o.initialized = true;
        o.timestamp = block.timestamp;
        o.user = msg.sender;
        sellOrderInfo[msg.sender][o.orderId]=o;
        allSellOrderId[o.orderId]=o;
        arrSellOrderId.push(o.orderId);
    }




    function getSellOrderInfo(string memory  _orderId) public view returns (Order memory o) {
        o = allSellOrderId[_orderId];
        return o;
    }




    function deleteSellOrderData(address _address,string memory _orderId) public {
        require(msg.sender == _address, "You can only delete your own data");


        if (isSellOrderInfoEmpty(_address,_orderId)){
            delete sellOrderInfo[_address][_orderId];
            delete allSellOrderId[_orderId];
            removeArrSellOrderId(_orderId);
        }
    }


    function isSellOrderInfoEmpty(address _address,string memory _orderId) public view returns (bool) {
        return sellOrderInfo[_address][_orderId].initialized;
    }

    function removeArrSellOrderId(string memory _orderId) internal{
        uint length =  arrBuyOrderId.length;
        for (uint i = 0; i < length; i++) {
            if (bytes(arrBuyOrderId[i]).length != 0 && isElementInArray(_orderId)) {
                arrBuyOrderId[i] = "";
            }
        }
    }


    //###########sellOrderInfo end########################################################

    //###########buyOrderInfo start#######################################################
    function addBuyOrderInfo(Order memory o) public {

        checkOrderParameter(o);


        o.initialized = true;
        o.timestamp = block.timestamp;
        o.user = msg.sender;

        buyOrderInfo[msg.sender][o.orderId]=o;
        allBuyOrderInfo[o.orderId]=o;
        arrBuyOrderId.push(o.orderId);
    }




    function getBuyOrderInfo(string memory  _orderId) public view returns (Order memory o) {
        o = allBuyOrderInfo[_orderId];
        return o;
    }


    function isBuyOrderInfoEmpty(address _address,string memory _orderId) public view returns (bool) {
        return buyOrderInfo[_address][_orderId].initialized;
    }

    function deleteBuyOrderData(address _address,string memory _orderId) public {
        require(msg.sender == _address, "You can only delete your own data");


        if (isBuyOrderInfoEmpty(_address,_orderId)){
            delete buyOrderInfo[_address][_orderId];
            delete allBuyOrderInfo[_orderId];
            removeArrBuyOrderId(_orderId);
        }
    }

    function removeArrBuyOrderId(string memory _orderId) internal{
        uint length =  arrBuyOrderId.length;
        for (uint i = 0; i < length; i++) {
            if (bytes(arrBuyOrderId[i]).length != 0 && isElementInArray(_orderId)) {
                arrBuyOrderId[i] = "";
            }
        }
    }

    function isElementInArray(string memory element) public view returns (bool) {
        bytes32 elementHash = keccak256(abi.encodePacked(element));
        for (uint i = 0; i < arrBuyOrderId.length; i++) {
            if (keccak256(abi.encodePacked(arrBuyOrderId[i])) == elementHash) {
                return true;
            }
        }
        return false;
    }

    //###########buyOrderInfo end#######################################################

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }
}
