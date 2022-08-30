//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../utils/Owner.sol";


interface IPassCardWhiteList {
    function IsAWhiteMember(address user) external view returns(bool);
    function LevelAddr(address user_) external view returns(uint256);
}


contract SimpleWhiteList is IPassCardWhiteList,owned{

    struct whiteItem{
        bool isDefault;
        uint256 cnt;
    }

    mapping(address=>whiteItem) public whiteAddrList;
    address public Operator;
    uint8 public defaultLevel;

    event EvAddWhiteAddr(address,address,uint8);
    event EvAddWhiteDefault(address,address,bool);
    event EvUpdateWhiteAddr(address,address,uint8);

    modifier onlyOperator {
        require(msg.sender == Operator);
        _;
    }

    constructor(){
        Operator = msg.sender;
        defaultLevel = 3;
    }

    function SetOperator(address op) external onlyOwner{
        Operator = op;
    }

    function setDefaultLevel(uint8 cnt_) external onlyOperator{
        defaultLevel = cnt_;
    }

    function addWhiteAddr(address user_) internal {
        whiteAddrList[user_] = whiteItem(true,0);
        emit EvAddWhiteDefault(msg.sender,user_,true);
    }

    function AddWhiteAddress(address user_, uint8 level_) external onlyOperator{
        require(whiteAddrList[user_].isDefault==false && whiteAddrList[user_].cnt == 0,"user is existed");
        whiteAddrList[user_] = whiteItem(false,level_);
        emit EvAddWhiteAddr(msg.sender,user_,level_);
    }

    function UpdateWhiteAddress(address user_, uint8 level_) external onlyOperator{
        require(whiteAddrList[user_].cnt >0 || whiteAddrList[user_].isDefault == true,"user not added");
        whiteAddrList[user_] = whiteItem(false,level_);
        emit EvUpdateWhiteAddr(msg.sender,user_,level_);
    }

    function LevelAddr(address user_) external override view returns(uint256){
        if( whiteAddrList[user_].cnt>0){
            return whiteAddrList[user_].cnt;
        }else if (whiteAddrList[user_].isDefault == true) {
            return defaultLevel;
        }else{
            return 0;
        }
    }

    function AddMultiWhiteAddr(address[] calldata addrs) external onlyOperator{
        for(uint256 i=0;i<addrs.length;i++){
            addWhiteAddr(addrs[i]);
        }
    }

    function IsAWhiteMember(address user_) external override view returns(bool){
        if(whiteAddrList[user_].cnt>0 || whiteAddrList[user_].isDefault==true){
            return true;
        }
        return false;
    }

}