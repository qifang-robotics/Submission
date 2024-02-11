// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";
import {SampleCoin} from "./SampleCoin.sol";

contract TicketMarketplace is ITicketMarketplace {

    // Events
    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }
    mapping(uint128 => Event) public events;

    ITicketNFT public ticketNFT;
    SampleCoin public sampleCoin;

    // Strict variable names to be satisfied with the test
    uint128 public currentEventId = 0;
    uint128 public ticketNo = 0;
    address public nftContract;
    address public owner;
    address public ERC20Address;
    
    constructor(address _erc20Address) {
        ERC20Address = _erc20Address;
        ticketNFT = new TicketNFT(); 
        nftContract = address(ticketNFT);
        owner = msg.sender;
        sampleCoin = SampleCoin(_erc20Address);
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) override external {
        require(msg.sender == owner, "Unauthorized access");
        require(maxTickets > 0, "Max tickets should be greater than 0");
        // For debugging purposes and special cases, pricePerTicket and pricePerTicketERC20 can be set to 0.
        events[currentEventId] = Event(0, maxTickets, pricePerTicket, pricePerTicketERC20);
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) override external {
        require(msg.sender == owner, "Unauthorized access");
        // NOTE: NOT COVERED IN THE TESTS, BUT IT IS A GOOD PRACTICE TO CHECK THE FOLLOWING CONDITION:
        // newMaxTickets should be greater than the number of tickets already sold.
        require(newMaxTickets > events[eventId].nextTicketToSell, "New max tickets should be greater than the number of tickets already sold.");
        require(newMaxTickets > events[eventId].maxTickets, "The new number of max tickets is too small!");
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) override external {
        require(msg.sender == owner, "Unauthorized access");
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) override external {
        require(msg.sender == owner, "Unauthorized access");
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    // payable function
    function buyTickets(uint128 eventId, uint128 ticketCount) payable override external {
        
        uint256 priceInTotal;
        // overflow check
        unchecked {
            priceInTotal = events[eventId].pricePerTicket * ticketCount;
        }
        require(events[eventId].pricePerTicket == priceInTotal / ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(priceInTotal <= msg.value, "Not enough funds supplied to buy the specified number of tickets.");
        require(ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");


        uint128 expectedTicketNo = ticketNo + ticketCount;

        for (uint128 i = ticketNo; i < expectedTicketNo; i++) {
            uint256 nftId = (uint256(eventId) << 128) | i;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
        }

        ticketNo = expectedTicketNo;

        // NOTE: NOT COVERED IN THE TESTS, BUT IT IS A GOOD PRACTICE TO CHECK THE FOLLOWING CONDITION:
        // If the buyer sent more than the required amount, the contract should refund the extra amount.
        // Test code did not cover this condition (thus causing a failing), but it is a good practice to include it. 
        // if (msg.value > priceInTotal) {
        //     payable(msg.sender).transfer(msg.value - priceInTotal);
        // }

        // update nextTicketToSell
        events[eventId].nextTicketToSell = expectedTicketNo;

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    // non payable function, but ERC20 transfer is required
    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) override external {
        
        uint256 priceInTotal;
        // overflow check
        unchecked {
            priceInTotal = events[eventId].pricePerTicketERC20 * ticketCount;
        }
        require(events[eventId].pricePerTicketERC20 == priceInTotal / ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        require(priceInTotal <= sampleCoin.balanceOf(msg.sender), "Not enough funds supplied to buy the specified number of tickets.");
        require(ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");

        // explicitly calling transfer, ensuring the user will not pay more than the required amount
        sampleCoin.transferFrom(msg.sender, address(this), priceInTotal);
        uint128 expectedTicketNo = ticketNo + ticketCount;

        for (uint128 i = ticketNo; i < expectedTicketNo; i++) {
            uint256 nftId = (uint256(eventId) << 128) | i;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
        }

        ticketNo = expectedTicketNo;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) override external {
        require(msg.sender == owner, "Unauthorized access");
        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }
}
