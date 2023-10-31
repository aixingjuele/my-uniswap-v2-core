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

    function checkOrderStatus(Order memory o)private  returns (bool)    {

        //匹配限价单
        if(o.orderType!=LimitType.Limit){
            return false;
        }
        //匹配已提交和部分提交
        if(!(o.orderStatus==OrderStatus.Submitted||o.orderStatus==OrderStatus.PartialFill)){
            return false;
        }
        //判断交易是否过期
        if (getBlockTimestamp() >= o.expirationTime) {
            return false;
        }
        return  true;

    }

    function matchLimitOrders() public {
        for (uint256 i = 0; i < arrBuyOrderId.length; i++) {
            string memory buyOrderId = arrBuyOrderId[i];
            Order storage buyOrder = allBuyOrderInfo[buyOrderId];
            bool buyOrderFlag = checkOrderStatus(buyOrder);
            if(!buyOrderFlag){
                continue;
            }


            for (uint256 j = 0; j < arrSellOrderId.length; j++) {
                string memory sellOrderId = arrSellOrderId[j];
                Order storage sellOrder = allSellOrderId[sellOrderId];

                bool sellOrderFlag = checkOrderStatus(sellOrder);
                if(!sellOrderFlag){
                    continue ;
                }

                if (sellOrder.price <= buyOrder.price) {
                    uint256 tradeQuantity = sellOrder.quantity;
                    if (tradeQuantity > buyOrder.remainingQuantity) {
                        tradeQuantity = buyOrder.remainingQuantity;
                    }

                    // Execute the trade
                    sellOrder.quantity -= tradeQuantity;
                    buyOrder.remainingQuantity -= tradeQuantity;

                    emit TradeExecuted(
                        buyOrderId,
                        sellOrderId,
                        tradeQuantity,
                        sellOrder.price,
                        buyOrder.user,
                        sellOrder.user
                    );

                    if (sellOrder.quantity == 0) {
                        // sellOrder. = true;
                    }

                    if (buyOrder.remainingQuantity == 0) {
                        // buyOrder.isCancelled = true;
                        break;
                    }
                }
            }
        }
    }



}