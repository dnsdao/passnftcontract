//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../ERC721/ERC721.sol";
import "../utils/Owner.sol";
import "../whitelist/IPassCardWhiteList.sol";

contract ColdBoot is ERC721,owned{
    using Strings for uint256;

    uint256 public CardID;
    uint16 private colorCardBegin;
    uint16 private colorCardEnd;
    uint16 private colorUsed;
    uint16 private goldCardBegin;
    uint16 private goldCardEnd;
    uint16 private goldUsed;
    uint256 private TotalCardId;
    uint16 private greenBegin;
    uint16 private greenUsed;

    //    uint8 public cardNumPerAddr;
    uint8 public cardDefault;
    uint256 public ethBalance;
    IPassCardWhiteList public whiteListC;

    address public whiteOperator;
    bytes private baseUri;

    uint256 public openTime;

    enum PassCardColor {noColorCard,ColorCard,GoldColor,GreenColor}

    mapping(uint256=>PassCardColor) public passCard;
    mapping(address=>uint256) mintCount;
    mapping(address=>uint256[]) public tokenList;

    event EVMintCard(address user,uint256 CardId, PassCardColor color);

    constructor(string memory name_,string memory symbol_,address whiteList_) ERC721(name_,symbol_) {
        colorCardBegin = 1;
        colorCardEnd = 8;
        goldCardBegin = 8;
        goldCardEnd = 75;
        greenBegin = 75;
        TotalCardId = 9999;
        //        cardNumPerAddr = 3;
        cardDefault = 1;
        ethBalance = 1e16;
        openTime = block.timestamp + 365 days;
        whiteListC = IPassCardWhiteList(whiteList_);
    }

    function setWhiteOperator(address o_) external onlyOwner{
        whiteOperator = o_;
    }

    modifier OnlyOperator {
        require(msg.sender == whiteOperator);
        _;
    }

    function setOpenTime(uint256 openTime_) external onlyOwner{
        openTime = openTime_;
    }

    function setWhiteListAddr(address white_) external onlyOwner{
        whiteListC = IPassCardWhiteList(white_);
    }

    function setCardDefaultNum(uint8 count_) external onlyOwner{
        cardDefault = count_;
    }
    function setCheckEthBalance(uint256 balance_) external onlyOwner{
        ethBalance = balance_;
    }

    function setBaseUri(string memory baseUri_) external onlyOwner{
        baseUri = bytes(baseUri_);
    }

    function getTokenList(uint256 idx_) public view returns (bool,uint256,PassCardColor){
        if(idx_ < tokenList[msg.sender].length){
            return (true,tokenList[msg.sender][idx_],passCard[tokenList[msg.sender][idx_]]);
        }
        return (false,0,PassCardColor(0));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function ownerOf(uint256 tokenId) public view override returns (address){
        return super.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256){
        return super.balanceOf(owner);
    }
    function name() public view override returns (string memory){
        return super.name();
    }

    function symbol() public view override returns (string memory){
        return super.symbol();
    }

    function _baseURI() internal view override returns (string memory){
        return string(baseUri);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        //        return super.tokenURI(tokenId);
        super._requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) public  override{
        return super.approve(to,tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address){
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        return super.setApprovalForAll(operator,approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool){
        return super.isApprovedForAll(owner,operator);
    }

    function _dnsTokenId(address user_,uint256 tokenId_) internal view returns(bool,uint256){
        for(uint256 i=0;i<tokenList[user_].length;i++){
            if(tokenId_ == tokenList[user_][i]){
                return (true,i);
            }
        }
        return (false,0);
    }

    function _dnsTransfer(address from_, address to_, uint256 tokenId_) internal{
        (bool tokenExists,uint256 idx) = _dnsTokenId(from_,tokenId_);
        require(tokenExists,"token not found");

        tokenList[from_][idx]  = tokenList[from_][tokenList[from_].length-1];
        tokenList[from_].pop();
        tokenList[to_].push(tokenId_);
    }

    //transfer need to do ...@@author rickey liao
    function transferFrom(address from, address to, uint256 tokenId) public override{
        _dnsTransfer(from,to,tokenId);
        return super.transferFrom(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        _dnsTransfer(from,to,tokenId);
        super.safeTransferFrom(from,to,tokenId,data);
    }

    function _mintPassCard(address user_) internal {
        require(block.timestamp>openTime,"pass card mint not opened");
        uint256 randId = uint256(keccak256(abi.encodePacked(block.timestamp,
            block.coinbase,
            CardID,colorUsed,goldUsed,greenUsed)));
        uint256 id = randId%(TotalCardId)+1;
        if(id>=colorCardBegin && id<colorCardEnd && colorUsed<7){
            colorUsed ++;
            passCard[CardID] = PassCardColor.ColorCard;
        }else if (id>=goldCardBegin && id<goldCardEnd && goldUsed<67){
            goldUsed++;
            passCard[CardID] = PassCardColor.GoldColor;
        }else if(greenUsed < 9925){
            greenUsed++;
            passCard[CardID] = PassCardColor.GreenColor;
        }
        if (passCard[CardID] == PassCardColor(0)){
            if(goldUsed<67){
                goldUsed ++;
                passCard[CardID] = PassCardColor.GoldColor;
            }else if (colorUsed<7){
                colorUsed ++;
                passCard[CardID] = PassCardColor.ColorCard;
            }else{
                revert("oops, count error");
            }
        }
        tokenList[user_].push(CardID);
        mintCount[user_] ++;
        super._mint(user_,CardID);

        emit EVMintCard(user_, CardID, passCard[CardID]);
        CardID ++;

    }

    function MintPassCardOne() external{
        require(CardID<TotalCardId,"exceed total card count");
        require(msg.sender.balance>=ethBalance || ethBalance == 0,"eth balance not allowed");

        if(whiteListC.LevelAddr(msg.sender)>0){
            // require(tokenList[msg.sender].length<cardNumPerAddr,"only 3 nft for whit list user");
            require(mintCount[msg.sender]<whiteListC.LevelAddr(msg.sender),"only 3 nft for whit list user");
        }else{
            // require(tokenList[msg.sender].length<cardDefault,"only 1 nft for normal user");
            require(mintCount[msg.sender]<cardDefault,"only 1 nft for normal user");
        }
        _mintPassCard(msg.sender);
    }

    function MintPassCard() external{
        require(CardID<TotalCardId,"exceed total card count");
        require(msg.sender.balance>=ethBalance || ethBalance == 0,"eth balance not allowed");

        uint256 left;
        if(whiteListC.LevelAddr(msg.sender)>0){
            // require(tokenList[msg.sender].length<cardNumPerAddr,"only 3 nft for whit list user");
            require(mintCount[msg.sender]<whiteListC.LevelAddr(msg.sender),"only 3 nft for whit list user");
            // left = cardNumPerAddr - tokenList[msg.sender].length;
            left = whiteListC.LevelAddr(msg.sender) - mintCount[msg.sender];
        }else{
            // require(tokenList[msg.sender].length<cardDefault,"only 1 nft for normal user");
            require(mintCount[msg.sender]<cardDefault,"only 1 nft for normal user");
            // left = cardDefault - tokenList[msg.sender].length;
            left = cardDefault - mintCount[msg.sender];
        }

        for(uint256 i=0;i<left;i++){
            if(CardID<TotalCardId){
                _mintPassCard(msg.sender);
            }
        }
    }
    //burn all left nfts
    function MintByOperator(address user_,uint256 count_) external OnlyOperator{
        require(CardID<TotalCardId,"exceed total card count");
        require(user_==0x0000000000000000000000000000000000000000,"not allowed");
        require(tokenList[user_].length<count_,"card count not correct");
        uint256 cnt=count_-tokenList[user_].length;
        for(uint256 i=0;i<cnt;i++){
            if(CardID<TotalCardId){
                _mintPassCard(user_);
            }
        }
    }

    function PassCardType(uint256 tokenId_) public view returns(PassCardColor){
        require(tokenId_<TotalCardId && passCard[tokenId_]>PassCardColor(0),"tokenId not correct");
        return passCard[tokenId_];
    }

    function PassCardUsed() public view returns(uint256,uint256,uint256){
        return (colorUsed,goldUsed,greenUsed);
    }

    function getSettingParam() public view returns(uint256,uint256,uint256){
        return (ethBalance,openTime,cardDefault);
    }

}

