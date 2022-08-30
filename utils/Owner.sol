//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.21;

contract owned {
    address payable public  owner;

    constructor(){
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) external virtual onlyOwner  {
        owner = newOwner;
    }
}