// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./PowerMarket.sol"
import "./PowerMarket.sol";

contract PowerTradeMatch is PowerMarket{


    event TradeExecuted(
        string indexed buyOrderId,
        string indexed sellOrderId,
        uint256 quantity,
        uint256 price,
        address indexed buyer,
        address  seller
    );

    function checkLimitOrderStatus(Order memory o,OrderType orderType)private  returns (bool) {

        //匹配限价单
        if(o.limitType!=LimitType.Limit){
            return false;
        }

        //匹配已提交和部分提交
        if(!(o.orderStatus==OrderStatus.Submitted||o.orderStatus==OrderStatus.PartialFill)){
            return false;
        }
        //判断交易是否过期
        if (getBlockTimestamp() >= o.expirationTime) {
            if(OrderType.Buy==orderType){
                expireBuyOrder(o.user,o.orderId);
            }else{
                expireSellOrder(o.user,o.orderId);
            }

            return false;
        }
        return  true;

    }

    function matchLimitOrders()override public {
        emit TestEvent("hello matchLimitOrders");
        for (uint256 i = 0; i < arrBuyOrderId.length; i++) {
            string memory buyOrderId = arrBuyOrderId[i];
            Order storage buyOrder = allBuyOrderInfo[buyOrderId];
            bool buyOrderFlag = checkLimitOrderStatus(buyOrder,OrderType.Buy);
            if(!buyOrderFlag){
                continue;
            }


            for (uint256 j = 0; j < arrSellOrderId.length; j++) {
                string memory sellOrderId = arrSellOrderId[j];
                Order storage sellOrder = allSellOrderInfo[sellOrderId];

                bool sellOrderFlag = checkLimitOrderStatus(sellOrder,OrderType.Sell);
                if(!sellOrderFlag){
                    continue ;
                }

                if (sellOrder.price <= buyOrder.price) {
                    uint256 tradeQuantity = sellOrder.quantity;
                    if (tradeQuantity > buyOrder.remainingQuantity) {
                        tradeQuantity = buyOrder.remainingQuantity;
                    }

                    // Execute the trade
                    sellOrder.remainingQuantity -= tradeQuantity;
                    buyOrder.remainingQuantity -= tradeQuantity;


                    if (sellOrder.remainingQuantity == 0) {
                        sellOrder.orderStatus = OrderStatus.Filled;
                    }else{
                        sellOrder.orderStatus = OrderStatus.PartialFill;
                    }


                    emit TradeExecuted(
                        buyOrderId,
                        sellOrderId,
                        tradeQuantity,
                        sellOrder.price,
                        buyOrder.user,
                        sellOrder.user
                    );

                    if (buyOrder.remainingQuantity == 0) {
                        buyOrder.orderStatus = OrderStatus.Filled;
                        break;
                    }
                }
            }

            if (buyOrder.quantity != buyOrder.remainingQuantity && buyOrder.remainingQuantity > 0) {
                buyOrder.orderStatus = OrderStatus.PartialFill;
            }
        }
    }



    function checkMarketOrderStatus(Order memory o,OrderType orderType)private  returns (bool) {

        //匹配市价单
        if(o.limitType!=LimitType.Market){
            return false;
        }
        return checkMarkteSimpleStatus(o,orderType);

    }


    function checkMarkteSimpleStatus(Order memory o,OrderType orderType)private  returns (bool) {

        //匹配已提交和部分提交
        if(!(o.orderStatus==OrderStatus.Submitted||o.orderStatus==OrderStatus.PartialFill)){
            return false;
        }
        //判断交易是否过期
        if (getBlockTimestamp() >= o.expirationTime) {
            if(OrderType.Buy==orderType){
                expireBuyOrder(o.user,o.orderId);
            }else{
                expireSellOrder(o.user,o.orderId);
            }

            return false;
        }
        return  true;

    }



    function matchMarketOrders() override public {
        emit TestEvent("Matching market orders");

        // 遍历买单市场
        for (uint256 i = 0; i < arrBuyOrderId.length; i++) {
            string memory buyOrderId = arrBuyOrderId[i];
            Order storage buyOrder = allBuyOrderInfo[buyOrderId];
            bool buyOrderFlag = checkMarketOrderStatus(buyOrder,OrderType.Buy);
            if(!buyOrderFlag){
                continue;
            }
            processMarketBuyOrder(buyOrderId);

        }

        // 遍历卖单市场
        for (uint256 j = 0; j < arrSellOrderId.length; j++) {

            string memory sellOrderId = arrSellOrderId[j];
            Order storage sellOrder = allSellOrderInfo[sellOrderId];
            bool sellOrderFlag = checkMarketOrderStatus(sellOrder,OrderType.Sell);
            if(!sellOrderFlag){
                continue;
            }
            processMarketSellOrder(sellOrderId);

        }
    }



    function processMarketBuyOrder(string memory buyOrderId) private {
        Order storage buyOrder = allBuyOrderInfo[buyOrderId];


        bool existsSellOrder = false;
        do {
            // 待执行的代码块
            string memory sellOrderId = findBestSellOrder(buyOrder.price);

            existsSellOrder = isStringNotEmpty(sellOrderId);

            if(existsSellOrder){
                Order storage sellOrder = allSellOrderInfo[sellOrderId];
                uint256 tradeQuantity = sellOrder.remainingQuantity;
                if (tradeQuantity > buyOrder.remainingQuantity) {
                    tradeQuantity = buyOrder.remainingQuantity;
                }

                // 执行交易
                sellOrder.remainingQuantity -= tradeQuantity;
                buyOrder.remainingQuantity -= tradeQuantity;

                if (sellOrder.remainingQuantity == 0) {
                    sellOrder.orderStatus = OrderStatus.Filled;
                }else {
                    sellOrder.orderStatus = OrderStatus.PartialFill;
                }


                emit TradeExecuted(
                    buyOrderId,
                    sellOrderId,
                    tradeQuantity,
                    sellOrder.price,
                    buyOrder.user,
                    sellOrder.user
                );

                if (buyOrder.remainingQuantity == 0) {
                    buyOrder.orderStatus = OrderStatus.Filled;
                    break; // 买单已全部成交，跳出卖单循环
                }
            }

        } while (existsSellOrder);

        if (buyOrder.quantity != buyOrder.remainingQuantity && buyOrder.remainingQuantity > 0) {
            buyOrder.orderStatus = OrderStatus.PartialFill;
        }
        if (buyOrder.orderStatus == OrderStatus.Submitted) {
            // 未成交的市价买单将被取消
            cancelBuyOrder(buyOrder.user, buyOrderId);
        }
    }


    function processMarketSellOrder(string memory sellOrderId) public {
        Order storage sellOrder = allSellOrderInfo[sellOrderId];

        bool existsBuyOrder = false;
        do {
            // 待执行的代码块
            string memory buyOrderId = findBestBuyOrder(sellOrder.price);

            existsBuyOrder = isStringNotEmpty(buyOrderId);


            if(existsBuyOrder){
                Order storage buyOrder = allBuyOrderInfo[buyOrderId];
                uint256 tradeQuantity = sellOrder.remainingQuantity;
                if (tradeQuantity > buyOrder.remainingQuantity) {
                    tradeQuantity = buyOrder.remainingQuantity;
                }

                // 执行交易
                sellOrder.remainingQuantity -= tradeQuantity;
                buyOrder.remainingQuantity -= tradeQuantity;

                if (sellOrder.remainingQuantity == 0) {
                    sellOrder.orderStatus = OrderStatus.Filled;
                }else{
                    sellOrder.orderStatus = OrderStatus.PartialFill;
                }


                emit TradeExecuted(
                    buyOrderId,
                    sellOrderId,
                    tradeQuantity,
                    sellOrder.price,
                    buyOrder.user,
                    sellOrder.user
                );


                if (buyOrder.remainingQuantity == 0) {
                    buyOrder.orderStatus = OrderStatus.Filled;
                    break; // 买单已全部成交，跳出卖单循环
                }


            }

        } while (existsBuyOrder);



        if (sellOrder.quantity != sellOrder.remainingQuantity && sellOrder.remainingQuantity > 0) {
            sellOrder.orderStatus = OrderStatus.PartialFill;
        }
        if (sellOrder.orderStatus == OrderStatus.Submitted) {
            // 未成交的市价卖单将被取消
            cancelSellOrder(sellOrder.user, sellOrderId);
        }
    }




    function findBestBuyOrder(uint256 sellPrice) private returns (string memory) {
        string memory bestBuyOrderId;
        uint256 bestBuyPrice = 0;

        for (uint i = 0; i < arrBuyOrderId.length; i++) {
            string memory buyOrderId = arrBuyOrderId[i];
            Order storage buyOrder = allBuyOrderInfo[buyOrderId];

            bool buyOrderFlag = checkMarkteSimpleStatus(buyOrder,OrderType.Buy);
            if(!buyOrderFlag){
                continue;
            }

            if (buyOrder.price >= sellPrice) {
                if (bestBuyPrice == 0 || buyOrder.price < bestBuyPrice) {
                    bestBuyPrice = buyOrder.price;
                    bestBuyOrderId = buyOrderId;
                }
            }
        }

        return bestBuyOrderId;
    }

    function findBestSellOrder(uint256 buyPrice) private returns (string memory) {
        string memory bestSellOrderId;
        uint256 bestSellPrice = type(uint256).max;

        for (uint i = 0; i < arrSellOrderId.length; i++) {
            string memory sellOrderId = arrSellOrderId[i];
            Order storage sellOrder = allSellOrderInfo[sellOrderId];


            bool sellOrderFlag = checkMarkteSimpleStatus(sellOrder,OrderType.Sell);
            if(!sellOrderFlag){
                continue;
            }

            if (sellOrder.price <= buyPrice) {
                if (sellOrder.price < bestSellPrice) {
                    bestSellPrice = sellOrder.price;
                    bestSellOrderId = sellOrderId;
                }
            }
        }
        return bestSellOrderId;
    }

}