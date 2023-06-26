// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        // address 0x694AA1769357215DE4FAC081bf1f309aDC325306 (from https://docs.chain.link/data-feeds/price-feeds/addresses)
        // abi ✅ (imported the interface)

        (, int price, , , ) = priceFeed.latestRoundData();

        // Price of ETH in terms of usd
        return uint(price) * 1e10; // msg.value will have 18 decimals, but price will have 8 - so 18-8=10 which is 1e10
    }

    function getConversionRate(
        uint ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}
