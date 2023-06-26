// get funds from users
// withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 784542
// 740981

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint; // we attach PriceConverter library to all uint (and uint256). msg.value is a uint thus it is able to use it.

    address[] private s_funders;
    mapping(address => uint) private s_addressToAmountFunded; // private vars are more gas efficient

    uint public constant MINIMUM_USD = 5e18; // the result of getConversionRate will have 18 decimals , so we need the usd amount to also have that
    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // only ever gets called when the contract is deployed!
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didnt send enough ETH!"
        ); // The first argument that is passed is the value that is attached (i.e uint) thats why we dont need to send the actual argument in the call.
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint funderLength = s_funders.length;
        for (uint funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the funders array
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        // reset the mapping to 0
        for (
            uint funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the funders array
        s_funders = new address[](0);

        // withdraw the funds

        // transfer
        // payable(msg.sender).transfer(address(this).balance); // msg.sender is address and we need to make it payable. Casting to payable is done by just wrapping an address with payable. transfer will revert if tx failed.

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // if `send` fail it doesnt revert the transactiona and return the funds. This is why we use require on it - because require will.

        // call - recommended way to send tokens
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    /**
     * View / Pure functions (getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // if someone somehow sends the contract money but without calling the fund - we will fallback to this - and actually call fund
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
