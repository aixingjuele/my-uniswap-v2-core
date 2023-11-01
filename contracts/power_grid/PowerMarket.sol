// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract PowerModel{

    enum OrderType { Buy, Sell }

    // 限价单  市价单
    enum LimitType {Limit, Market }
    /*已提交 (Submitted): 订单已被交易者提交到交易所，等待撮合。
      部分成交 (Partial Fill): 订单被部分成交，其中一部分订单数量已经完成，但仍有剩余未成交的部分。
      全部成交 (Filled): 订单的所有数量已被成功成交。
      已取消 (Canceled): 交易者主动取消了订单，订单将不再参与撮合。
      过期 (Expired): 订单在其有效期内未被成交，而且已经过了有效期。
      错误 (Pending): 订单可能会因错误或异常情况而无法正常处理。
*/
    enum OrderStatus {Submitted,PartialFill,Filled,Canceled,Expired,Pending}



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

        OrderStatus orderStatus;

        LimitType limitType;

    }
}



contract PowerMarket is PowerModel{

    event AddSellOrderInfo(Order o);
    event AddBuyOrderInfo(Order o);

    event DeleteSellOrderData(Order o);
    event DeleteBuyOrderData(Order o);


    event ExpireSellOrderData(Order o);
    event ExpireBuyOrderData(Order o);


    // 买单信息
    mapping (address=>mapping(string=>Order)) public buyOrderInfo;
    mapping (string=>Order) public allBuyOrderInfo;
    string[] public arrBuyOrderId;

    // 卖单信息
    mapping (address=>mapping(string=>Order)) public sellOrderInfo;
    mapping (string=>Order) public allSellOrderId;
    string[] public arrSellOrderId;



    function checkOrderParameter(Order memory o)public view  {
        require(bytes(o.orderId).length!=0,"OrderId can not empty");
        require(o.quantity > 0,"Quantity must be greater than 0");
        require(o.price > 0,"Price must be greater than 0");

        require(getBlockTimestamp() < o.expirationTime, "Timelock::expirationTime: has to more than blocktime.");

        require(bytes(o.subjectInformation).length!=0,"SubjectInformation can not empty");
        require(bytes(o.deliveryInformation).length!=0,"DeliveryInformation can not empty");

        require((o.limitType==LimitType.Limit||o.limitType==LimitType.Market),"Order type is limit or market");

    }


    //###########sellOrderInfo start#######################################################
    function addSellOrderInfo(Order memory o) public {

        checkOrderParameter(o);

        o.initialized = true;
        o.timestamp = block.timestamp;
        o.user = msg.sender;
        o.orderStatus = OrderStatus.Submitted;
        // o.orderType = OrderType.Sell;

        sellOrderInfo[msg.sender][o.orderId]=o;
        allSellOrderId[o.orderId]=o;
        arrSellOrderId.push(o.orderId);

        emit AddSellOrderInfo(o);
    }




    function getSellOrderInfo(string memory  _orderId) public view returns (Order memory o) {
        o = allSellOrderId[_orderId];
        return o;
    }




    function  cancelSellOrder(address _address,string memory _orderId) public {
        require(msg.sender == _address, "You can only delete your own data");


        if (isSellOrderInfoEmpty(_address,_orderId)){
            Order memory o = allSellOrderId[_orderId];
            delete sellOrderInfo[_address][_orderId];
            delete allSellOrderId[_orderId];
            removeArrSellOrderId(_orderId);
            emit DeleteSellOrderData(o);
        }
    }



    function expireSellOrder(address _address,string memory _orderId) internal {
        if (isSellOrderInfoEmpty(_address,_orderId)){

            allSellOrderId[_orderId].orderStatus = OrderStatus.Expired;
            Order memory o = allSellOrderId[_orderId];
            sellOrderInfo[_address][_orderId].orderStatus = OrderStatus.Expired;
            emit ExpireSellOrderData(o);
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
        o.orderStatus = OrderStatus.Submitted;
        // o.orderType = OrderType.Buy;


        buyOrderInfo[msg.sender][o.orderId]=o;
        allBuyOrderInfo[o.orderId]=o;
        arrBuyOrderId.push(o.orderId);

        emit AddBuyOrderInfo(o);
    }




    function getBuyOrderInfo(string memory  _orderId) public view returns (Order memory o) {
        o = allBuyOrderInfo[_orderId];
        return o;
    }


    function isBuyOrderInfoEmpty(address _address,string memory _orderId) public view returns (bool) {
        return buyOrderInfo[_address][_orderId].initialized;
    }

    function cancelBuyOrder(address _address,string memory _orderId) public {
        require(msg.sender == _address, "You can only delete your own data");


        if (isBuyOrderInfoEmpty(_address,_orderId)){

            Order memory o = allBuyOrderInfo[_orderId];
            delete buyOrderInfo[_address][_orderId];
            delete allBuyOrderInfo[_orderId];
            removeArrBuyOrderId(_orderId);

            emit DeleteBuyOrderData(o);
        }
    }


    function expireBuyOrder(address _address,string memory _orderId) internal {
        if (isBuyOrderInfoEmpty(_address,_orderId)){

            allBuyOrderInfo[_orderId].orderStatus = OrderStatus.Expired;
            Order memory o = allBuyOrderInfo[_orderId];
            buyOrderInfo[_address][_orderId].orderStatus = OrderStatus.Expired;
            emit ExpireBuyOrderData(o);
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
