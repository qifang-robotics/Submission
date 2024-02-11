// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SampleCoin is ERC20 {
    constructor() ERC20("SampleCoin", "SMPL") {
        // mint 100 tokens, to be satisfied with the test
        uint256 initialSupply = 100 * (10 ** uint256(decimals()));
        _mint(msg.sender,  initialSupply);
    }

}