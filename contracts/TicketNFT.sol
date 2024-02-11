// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    address public owner;

    constructor() ERC1155("https://api.ticketnft.com/ticket/{id}.json") {
        owner = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) override external {
        require(msg.sender == owner, "Unauthorized access");
        _mint(to, nftId, 1, "");
    }
}