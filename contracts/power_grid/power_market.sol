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
    // mapping (string=>Order) public sellOrderInfo;
    // mapping (address=>string) public sellOrderId;



    function addBuyOrderInfo(Order memory o) public {

        o.initialized = true;
        o.timestamp = block.timestamp;
        buyOrderInfo[msg.sender][o.orderId]=o;
        allBuyOrderInfo[o.orderId]=o;
        arrBuyOrderId.push(o.orderId);
    }




    function getBuyOrderInfo(string memory  _orderId) public view returns (Order memory o) {
        o = allBuyOrderInfo[_orderId];
        return o;
    }


    function isStructEmpty(address _address,string memory _orderId) public view returns (bool) {
        return !buyOrderInfo[_address][_orderId].initialized;
    }

    function deleteData(address _address,string memory _orderId) public {
        require(msg.sender == _address, "You can only delete your own data");

        // mapping(string=>Order) addressMappOrder = buyOrderInfo[_address];

        if (isStructEmpty(_address,_orderId)){
            delete buyOrderInfo[_address][_orderId];
            delete allBuyOrderInfo[_orderId];
        }


    }


}
