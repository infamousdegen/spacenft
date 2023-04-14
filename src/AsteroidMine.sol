// SPDX-License-Identifier: UNLICENSED

//@note: Using erc1155 and id 0 will be the users claim on iridium tokens (making the iridium tokens are erc20 )
//token id 1 will be the WHITELIST
//token id 2 will be KEYS
//token id 3 will be GEODUS

//@todo:Use weighted probability to choose the rewards


        /* -------------------------------------------------------------------
       |                      Issues                                        |
       | ________________________________________________________________ | */
//@note: Issue causing:- I am not storing the number of elements in the storage slot 
//@note: Users will be able to deposit and withdraw multiple times to claim unlimited rewards
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/solmate/src/tokens/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "forge-std/console.sol";
// import "lib/solmate/src/utils/ReentrancyGuard.sol";


contract AsteroidMines is ERC1155, VRFV2WrapperConsumerBase,ERC721Holder{
    using Math for uint256;
    using SafeERC20 for IERC20;
    

    IERC721 spaceRatNftAddy;

    IERC20 iridiumTokenAddy;

    //@todo: Make this updatable
    uint256 GeodusIridumReward = 100 * 1e18;

    //@todo: Make this updatable
    uint256 iridumTokenReward = 1000 *1e18;

    // Minimum wait time before you can crack open the geodus again
    //@MakeThisUpdatable 
    uint32 public minimumGeodusClaimTime;    


    enum Rewards {
        IRIDIUM,
        WHITELIST, 
        KEYS
    }

    constructor(
        address _vrfV2Wrapper,
        address _link,
        IERC721 _spaceRatNftAddy,
        address _iridiumTokenAddy
    ) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) {
        spaceRatNftAddy = _spaceRatNftAddy;
        iridiumTokenAddy = IERC20(_iridiumTokenAddy);


    }

    mapping(uint256 => address) private requestsIds;

    //Tracker for total iridiumissued
    uint256 _totalIridumIssued;


        

    //check for reentrancy
    //@note: I am not storing the number of elements in the storage slot 0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852
    //@note: Not sure why it will be needed 
    function depositNft(address _addy, uint256[] memory tokenIds) public {
        
        uint256 GeodusTokensToMint;
        
        unchecked{
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId =  tokenIds[i];
            spaceRatNftAddy.safeTransferFrom(_addy, address(this), tokenId);
                assembly {
                    //@note: keccak256 of "GOD FORGIVE ME FOR MY SINS"
                    let value := or(_addy,shl(160,timestamp()))
                    sstore(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId),value)
                }
                ++i;
            

        }
        }



        uint256 sharesToMint = _calculateShares(tokenIds.length);

        _totalIridumIssued = _totalIridumIssued + sharesToMint;
        _mint(_addy, 0, sharesToMint, "");
        _mint(_addy, 3, GeodusTokensToMint, "");

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
    function claimIridium(uint256[] memory _tokenIds ) public {

        uint256 totalRewards;
        unchecked{
        for(uint256 i;i<_tokenIds.length;){
            uint256 tokenId = _tokenIds[i];
            uint256 previoustimestamp;

            assembly{
                let value := sload(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId))
                let _addy := and(sub(shl(160,1),1),value)

                if iszero(eq(_addy,caller())){
                    revert(0,0)
                }
                previoustimestamp := shr(value,160)
                sstore(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId),or(_addy,shl(160,timestamp())))

            }
            //@note: Cannot realistically overflow I guess
           totalRewards = totalRewards + _caculateIriduRewards(block.timestamp - previoustimestamp);
        ++i;
        }

        }

        // //check whether this is needed here        (supply == 0) ? _initialConvertToAssets(shares, rounding) from erc4626
        iridiumTokenAddy.safeTransfer(msg.sender, totalRewards);
    }


    //the reward is calculated based on how long they have deposited out of 365 days

    function _caculateIriduRewards(
        uint256 _elapsedTime
    ) internal view returns (uint256) {
        uint256 supply = _totalIridumIssued;

        uint256 userBalance = balanceOf[msg.sender][0];



        uint256 interMediateBalance = (supply == 0 || userBalance == 0)
            ? 0
            : userBalance.mulDiv(iridumTokenReward, supply, Math.Rounding.Down);
        return
            _elapsedTime.mulDiv(
                interMediateBalance,
                365 days,
                Math.Rounding.Up
            );
    }

    //onlyAllowingToOpen 1 geodus at a time now
    function crackOpenGeodus() external {

        _burn(msg.sender, 3, 1);
        //@todo: Allow admint to configure these params
        requestRandomness(100000, 50, 1);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address _addy = requestsIds[_requestId];

        uint256 randomNumber = _randomWords[0] % 3;

        if (randomNumber == 0) {
            iridiumTokenAddy.safeTransfer(_addy, GeodusIridumReward);
        } else {
            _mint(_addy, randomNumber, 1, "");
        }
        //@todo
        //If we free up the the blockchain we get gas refunds right ? check this again
        delete requestsIds[_requestId];
    }

    //@todo:add claim rewards
    //Add Claim Rewards
//@note: This enables users to withdraw all their tokens or just partially
//@note:add reentrancy
    function withdraw(uint256[] memory _tokenIds) external {
        

        for(uint256 i; i< _tokenIds.length;){
            uint256 tokenId = _tokenIds[i];

            assembly{
                let value := sload(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId))
                let _addy := and(sub(shl(160,1),1),value)
                if iszero(eq(_addy,caller())){
                    revert(0,0)
                }

                sstore(add(0xe6fbf88f54b59f196282c146be0ae4b996dfb49fc44a38b19e4ff9e6efb3b852,tokenId),0x0)
            }

        ++i;

        spaceRatNftAddy.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        

    }





    //@note: have to update this 
    function uri(uint256 _id) public view override returns (string memory){
        return("Hi");
    } 


}
