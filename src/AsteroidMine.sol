// SPDX-License-Identifier: UNLICENSED

//@note: Using erc1155 and id 0 will be the users claim on iridium tokens (making the iridium tokens are erc20 )
//token id 1 will be the WHITELIST
//token id 2 will be KEYS
//token id 3 will be GEODUS

//@todo:Use weighted probability to choose the rewards

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/solmate/src/tokens/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "forge-std/console.sol";


contract AsteroidMines is ERC1155, VRFV2WrapperConsumerBase,ERC721Holder {
    using Math for uint256;
    using SafeERC20 for IERC20;
    

    IERC721 spaceRatNftAddy;
    IERC20 iridiumTokenAddy;

    //@todo: Make this updatable
    uint256 iridumTokenReward = 100 * 1e18;

    uint64 public minimumGeodusTime;    


    enum Rewards {
        IRIDIUM,
        WHITELIST,
        KEYS
    }

    constructor(
        address _vrfV2Wrapper,
        address _link,
        IERC721 _spaceRatNftAddy
    ) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) {
        spaceRatNftAddy = _spaceRatNftAddy;


    }

    mapping(uint256 => address) private requestsIds;

    //Tracker for total iridiumissued
    uint256 _totalIridumIssued;


    uint256 totalRewardTokens;


        

    //check for reentrancy
    //@note: I am not storing the number of elements in the storage slot 0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852
    //@note: Not sure why it will be needed 
    function depositNft(address _addy, uint256[] memory tokenIds) public {

        unchecked{
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId =  tokenIds[i];
            spaceRatNftAddy.safeTransferFrom(_addy, address(this), tokenId);
                uint256 timeStamp = block.timestamp;
                assembly {
                    //@note: keccak256 of "GOD FORGIVE ME FOR MY SINS"
                    let value := or(_addy,shl(160,timeStamp))
                    sstore(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId),value)
                }
                ++i;
            

        }
        }



        uint256 sharesToMint = _calculateShares(tokenIds.length);

        _totalIridumIssued = _totalIridumIssued + sharesToMint;
        _mint(_addy, 0, sharesToMint, "");
        _mint(_addy, 3, tokenIds.length, "");

    }


    //check for inflationa attacks
    function _calculateShares(uint256 _amount) internal view returns (uint256) {
        uint256 currentBalance = spaceRatNftAddy.balanceOf(address(this));
        return
            (_amount == 0)
                ? 0
                : _amount.mulDiv(1e18, currentBalance, Math.Rounding.Down);
    }


    //@note: add last claim reward snapshot
    //@param: tokenid's to claim the reward from
    //@note: more gas but allows user to have more control on which all token Id to claim reward from
    function claimIridium(uint256[] memory _tokenIds ) public {

        uint256 currentTimeStamp = block.timestamp;

        unchecked{
        for(uint256 i;i<_tokenIds.length;){
            uint256 tokenId = _tokenIds[i];
            assembly{
                let value := sload(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId))
                let isEqual := eq(shr(value,160),caller())

                if isZero(isEqual){
                    revert(0,0)
                }
                let timeStamp := shr(value,224)
            }

        }
        ++i;
        }

        uint256 elapsedTime = block.timestamp -
            _depositDetailsCache.depositSnapShot;

        //check whether this is needed here        (supply == 0) ? _initialConvertToAssets(shares, rounding) from erc4626
        uint256 rewards = _caculateIriduRewards(elapsedTime);

        _depositDetailsCache.depositSnapShot = uint64(block.timestamp);

        deposits[_id] = _depositDetailsCache;

        iridiumTokenAddy.safeTransfer(msg.sender, rewards);
    }

    function _claimIridium(DepositDetails memory _depositDetails) internal {}

    //the reward is calculated based on how long they have deposited out of 365 days

    function _caculateIriduRewards(
        uint256 _elapsedTime
    ) internal view returns (uint256) {
        uint256 supply = _totalIridumIssued;

        uint256 userBalance = balanceOf[msg.sender][0];

        uint256 interMediateBalance = (supply == 0 || userBalance == 0)
            ? 0
            : userBalance.mulDiv(totalRewardTokens, supply, Math.Rounding.Down);

        return
            _elapsedTime.mulDiv(
                interMediateBalance,
                365 days,
                Math.Rounding.Down
            );
    }

    //onlyAllowingToOpen 1 geodus at a time now
    function crackOpenGeodus() external {
        _burn(msg.sender, 3, 1);
        requestRandomness(100000, 50, 1);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address _addy = requestsIds[_requestId];
        //Use bit manupilation to do mod instead
        uint256 randomNumber = _randomWords[0] % 3;

        if (randomNumber == 0) {
            iridiumTokenAddy.safeTransfer(_addy, iridumTokenReward);
        } else {
            _mint(_addy, randomNumber, 1, "");
        }
        //@todo
        //If we free up the the blockchain we get gas refunds right ? check this again
        delete requestsIds[_requestId];
    }

    //@todo:add claim rewards
    //Add Claim Rewards
    // function withdraw(uint256 _id, uint64[] memory _tokenIds) external {
    //     DepositDetails memory _DepositDetailsCache = deposits[_id];

    //     require(
    //         msg.sender == _DepositDetailsCache._owner,
    //         "You are not the owner of this id"
    //     );
    //     _DepositDetailsCache.depositedTokenId.length >= _tokenIds.length
    //         ? _completeWithdrawal(_id, _DepositDetailsCache)
    //         : _partialWithdrawal(_tokenIds, _DepositDetailsCache);
    // }

    // //@note:It doesn't check for tokenIds in complete withdrawal it closes the pool and transfers everything
    // function _completeWithdrawal(
    //     uint256 _id,
    //     DepositDetails memory _DepositDetails
    // ) internal {
    //     for (uint256 i; i < _DepositDetails.depositedTokenId.length; ) {
    //         //@todo: Use safe transfer version
    //         spaceRatNftAddy.safeTransferFrom(
    //             address(this),
    //             _DepositDetails._owner,
    //             _DepositDetails.depositedTokenId[i]
    //         );

    //         unchecked {
    //             ++i;
    //         }
    //     }

    //     delete deposits[_id];
    // }

    // function _partialWithdrawal(
    //     uint64[] memory _tokenIdsToWithdraw,
    //     DepositDetails memory _DepositDetails,
    //     uint16 _size
    // ) internal {
    //     uint64[] memory _newArray = new uint64[](_size);


    // }



    //@note: have to update this 
    function uri(uint256 _id) public view override returns (string memory){
        return("Hi");
    } 


}
