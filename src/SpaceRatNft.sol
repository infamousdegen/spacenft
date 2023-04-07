// SPDX-License-Identifier: UNLICENSED

//@todo: Add option for buying for value 
//@todo: init function

pragma solidity ^0.8.0;
import 'lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol';
contract SpaceRats is ERC721Upgradeable,Ownable2StepUpgradeable,ReentrancyGuardUpgradeable{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokeId;

    //1 is for false and any other number is true (ideally it should be any other number than 0 to save gas)
    uint8 public isPublicSale = 1;

    uint8 public isWhitelistSale = 1;

//@todo: start this from 1
    uint16 public publicSaleCounter;

    uint16 public whiteListSaleCounter;


    bytes32 public root;

    string public baseURI;


    //1 for not minted and any other number for minted
    mapping(address => bool) public minted;

    mapping(address=>uint256) public totalMinted;
    

    function publicSale(address _addy) external nonReentrant{
        require(publicSaleCounter < 1000,"Public sale has ended");

        require(isPublicSale!=1,"Public sale has not started");

        uint256 currentTokenIdCache = _tokeId.current();

        _tokeId.increment();

        ++publicSaleCounter;

        _safeMint(_addy,currentTokenIdCache);

    }



    //If the user doesn't enter the correct _max then merkleProofVerify won't pass
    function whiteListSale(address _addy,uint256 _amountOfNft,uint256 _max,bytes32[] calldata _proof) external nonReentrant{


            require((whiteListSaleCounter+_amountOfNft) < 1000,"Whitelist sale has ended");

            require(isWhitelistSale!=1,"WhiteList sale has not started");

            
            require(MerkleProofUpgradeable.verifyCalldata(_proof,root,keccak256(bytes.concat(keccak256(abi.encode(_addy,_max))))),"Not allowed");
            
            uint256 currentMints = totalMinted[_addy] + _amountOfNft;

            require(currentMints < _max);

            uint16 whiteListSaleCounterCache = whiteListSaleCounter;

            uint256 currentTokenIdCache = _tokeId.current();




            for(uint256 i;i < _amountOfNft;){
                _safeMint(_addy,currentTokenIdCache);

                unchecked{
                    ++i;
                    ++currentTokenIdCache;
                    ++whiteListSaleCounterCache;
                }
                

            }
            totalMinted[_addy] = currentMints;
            _tokeId._value = currentTokenIdCache;
            whiteListSaleCounter = whiteListSaleCounterCache;



    }



        /* -------------------------------------------------------------------
       |                      Owner                                        |
       | ________________________________________________________________ | */


    function setBaseUri(string memory _baseUri) external onlyOwner{
        baseURI = _baseUri;
    }


     //1 for false and any other number for true
    function togglePublicSale(uint8 _value) external onlyOwner {
        isPublicSale = _value;

    }



    function updateRoot(bytes32 _root) external onlyOwner{
        root = _root;
    }

        /* -------------------------------------------------------------------
       |                      View                                        |
       | ________________________________________________________________ | */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }



}
