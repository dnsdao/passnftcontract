//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../utils/Owner.sol";


interface IPassCardWhiteList {
    function IsAWhiteMember(address user) external view returns(bool);
    function LevelAddr(address user_) external view returns(uint256);
    function AddWhiteAddr(address user_) external;
    function AddWhiteList(address[] memory userList) external;
}

contract BloomfilterWhiteList is owned{
    uint256[] public bitSet;
    uint256 constant bitSetLen = 400;
    uint256 constant bitsLen = bitSetLen*256;

    uint public defaultCnt;
    uint public otherCnt;


    constructor(){
        bitSet = new uint256[](bitSetLen);
        defaultCnt = 3;
        otherCnt = 0;
    }

    function setBitsets(uint idx, uint256[] calldata bitArray_) external onlyOwner {
        for(uint256 i=idx;i<bitArray_.length && i<bitSet.length;i++){
            bitSet[i] = bitArray_[i];
        }
    }

    function setDefaultCnt(uint cnt_,uint otherCnt_) external onlyOwner{
        defaultCnt = cnt_;
        otherCnt = otherCnt_;
    }

    function getKeccak256Mod(address x_) internal pure returns(uint256,uint256){
        uint256 a = (uint256(keccak256(abi.encodePacked(x_))))%bitsLen;
        return (a/256,1<<a%256);
    }

    function getSha256Mod(address x_) internal pure returns(uint256,uint256){
        uint256 a = (uint256(sha256(abi.encodePacked(x_))))%bitsLen;
        return (a/256,1<<a%256);
    }

    function getMod(address x_) internal pure returns(uint256,uint256){
        uint256 a = uint256(uint160(x_))%bitsLen;
        return (a/256,1<<a%256);
    }

    function IsAWhiteMember(address user) external view returns(bool){
        return _isAWhiteMember(user);
    }

    function addWhiteAddr(address user_) internal {
        (uint256 idx,uint256 v) = getKeccak256Mod(user_);
        bitSet[idx] = bitSet[idx] | v;
        (idx,v) = getSha256Mod(user_);
        bitSet[idx] = bitSet[idx] | v;
        (idx,v) = getMod(user_);
        bitSet[idx] = bitSet[idx] | v;
    }

    function AddWhiteAddr(address user_) external onlyOwner{
        addWhiteAddr(user_);
    }

    function AddWhiteList(address[] memory userList) external onlyOwner{
        for (uint i=0;i<userList.length;i++){
            addWhiteAddr(userList[i]);
        }
    }

    function _isAWhiteMember(address user) internal view returns(bool){
        (uint256 idx,uint256 v) = getKeccak256Mod(user);
        if((v & bitSet[idx]) == 0){
            return false;
        }

        (idx,v) = getSha256Mod(user);
        if((v & bitSet[idx]) == 0){
            return false;
        }
        (idx,v) = getMod(user);
        if((v & bitSet[idx]) == 0){
            return false;
        }

        return true;

    }

    function LevelAddr(address user_) external view returns(uint256){
        if (_isAWhiteMember(user_)){
            return defaultCnt;
        }else{
            return otherCnt;
        }
    }

}

