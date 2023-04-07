// SPDX-License-Identifier: UNLICENSED

//@note: Using erc1155 and id 1 will be the users claim on iridium tokens (making the iridium tokens are erc20 )
         //token id 2 will be the geodes 

pragma solidity ^0.8.0;

import 'lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol';
contract AsteroidMines is ERC1155SupplyUpgradeable{

    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC721Upgradeable spaceRatNftAddy;
    IERC20Upgradeable iridiumTokenAddy;



    uint256 iridiumTokenPerSecond;

    //let id start from 1
    uint256 id = 1;

        
    struct DepositDetails{
        address _owner;
        uint64 depositSnapShot;
        uint64[] depositedTokenId;

    }
 
    mapping(uint256 => DepositDetails) private deposits;

    uint256 totalRewardTokens;

    function __init__(IERC721Upgradeable _spaceRatNftAddy) external{
        spaceRatNftAddy = _spaceRatNftAddy;
    }


    //check for reentrancy
    function depositNft(address _addy,uint64[] memory tokenIds) external {
    

    DepositDetails memory _depositDetailsCache;

    for(uint256 i;i<tokenIds.length;){
            spaceRatNftAddy.safeTransferFrom(_addy,address(this),tokenIds[i]);

        unchecked{
            ++i;
            }
        }

    _depositDetailsCache.depositSnapShot = uint64(block.timestamp);
    _depositDetailsCache._owner = _addy;
    _depositDetailsCache.depositedTokenId = tokenIds;

    uint256 sharesToMint = _calculateShares(tokenIds.length);
    

    deposits[id] = _depositDetailsCache;

    ++id;

    _mint(_addy,1,sharesToMint,"");
    _mint(_addy,2,tokenIds.length,""); 

    }






    //check for inflationa attacks
    function _calculateShares(uint256 _amount) internal view returns(uint256){
        uint256 currentBalance = spaceRatNftAddy.balanceOf(address(this));
        return
        (_amount == 0)
        ? 0
        :_amount.mulDiv(1e18,currentBalance,MathUpgradeable.Rounding.Down);

    }

    //check for inflationa attacks

    //@note: add last claim reward snapshot
    function claimIridium(uint256 _id) public {

        DepositDetails memory _depositDetailsCache = deposits[_id];

        require(_depositDetailsCache._owner == msg.sender ,"You are not the owner of this id");

        uint256 elapsedTime = block.timestamp - _depositDetailsCache.depositSnapShot;

        //check whether this is needed here        (supply == 0) ? _initialConvertToAssets(shares, rounding) from erc4626
        uint256 rewards = _caculateIriduRewards(elapsedTime);

        _depositDetailsCache.depositSnapShot = uint64(block.timestamp);

        deposits[_id] = _depositDetailsCache;


        iridiumTokenAddy.safeTransfer(msg.sender,rewards);

    }

    //the reward is calculated based on how long they have deposited out of 365 days

    function _caculateIriduRewards(uint256 _elapsedTime) internal view returns(uint256){
        uint256 supply = totalSupply(1);

        uint256 userBalance = balanceOf(msg.sender,1);

        uint256 interMediateBalance = (supply == 0||userBalance == 0) ? 0 : userBalance.mulDiv(totalRewardTokens,supply,MathUpgradeable.Rounding.Down);

        return
        _elapsedTime.mulDiv(interMediateBalance,365 days,MathUpgradeable.Rounding.Down);

    }



}  