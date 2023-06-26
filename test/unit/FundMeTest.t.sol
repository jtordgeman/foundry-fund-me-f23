// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 10 ether;
    uint constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        //assertEq(fundMe.i_owner(), address(this)); // the actual owner of the deployed FundMe is FundMeTest, not msg.sender (msg.sender is the caller, the contract was deployed by the test contract i.e FundMeTest)
        assertEq(fundMe.i_owner(), msg.sender); // this time the owner is msg.sender because the deploy script deployed the contract and because vm is used - its really the msg.sender who is the owner
    }

    function testPriceFeedVersionIsAccurate() public {
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund(); // sending 0 value
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        // Act
        //uint gasStart = gasleft(); // uncomment the gas lines to actually set a gas price for this TX
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint gasEnd = gasleft();
        //uint gasUsed = (gasStart - gasEnd) * tx.gasprice;
        //console.log(gasUsed);

        // Assert
        uint endingOwnerBalance = fundMe.getOwner().balance;
        uint endingFundMeBalnace = address(fundMe).balance;

        assertEq(endingFundMeBalnace, 0); // by default Anvil sets the price of gas to 0 - this is why these asserts work.
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFundersIndex = 1; // we shouldnt use the 0 address (address(0)) in test.

        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // coming from the forge-std library. It basically does vm.prank and vm.deal in one call.
            fundMe.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // everything between the startPrank and stopPrank will be acted upon the supplied address (in this case fundMe.getOwner())
        fundMe.withdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFundersIndex = 1; // we shouldnt use the 0 address (address(0)) in test.

        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // coming from the forge-std library. It basically does vm.prank and vm.deal in one call.
            fundMe.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // everything between the startPrank and stopPrank will be acted upon the supplied address (in this case fundMe.getOwner())
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
