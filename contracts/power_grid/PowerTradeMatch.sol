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

    function checkOrderStatus(Order memory o,OrderType orderType)private  returns (bool) {

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

    function matchLimitOrders() public {
        for (uint256 i = 0; i < arrBuyOrderId.length; i++) {
            string memory buyOrderId = arrBuyOrderId[i];
            Order storage buyOrder = allBuyOrderInfo[buyOrderId];
            bool buyOrderFlag = checkOrderStatus(buyOrder,OrderType.Buy);
            if(!buyOrderFlag){
                continue;
            }


            for (uint256 j = 0; j < arrSellOrderId.length; j++) {
                string memory sellOrderId = arrSellOrderId[j];
                Order storage sellOrder = allSellOrderId[sellOrderId];

                bool sellOrderFlag = checkOrderStatus(sellOrder,OrderType.Sell);
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
                    }

                    if (buyOrder.remainingQuantity == 0) {
                        buyOrder.orderStatus = OrderStatus.Filled;
                        break;
                    }

                    emit TradeExecuted(
                        buyOrderId,
                        sellOrderId,
                        tradeQuantity,
                        sellOrder.price,
                        buyOrder.user,
                        sellOrder.user
                    );
                }
            }

            if (buyOrder.quantity != buyOrder.remainingQuantity && buyOrder.remainingQuantity > 0) {
                buyOrder.orderStatus = OrderStatus.PartialFill;
                break;
            }
        }
    }



}