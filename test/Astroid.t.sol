// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import 'src/AsteroidMine.sol';
import 'src/SpaceRatNft.sol';

contract AsterpodTest is Test {

    address owner = address(0x69);
    address depositor1 = address(0x50);
    address depositor2 = address(0x39);
    address random1 = address(0x420);
    address random2 = address(0x421);
    SpaceRats _spacerats;
    AsteroidMines _asteroidMine;

    function setUp() public {
        vm.startPrank(owner);
        _spacerats = new SpaceRats();
        _asteroidMine = new AsteroidMines(random1,random2,_spacerats);
        vm.stopPrank();

    }

    function test_togglePublicSale() public {
        vm.startPrank(owner);
        _spacerats.togglePublicSale(2);
        vm.stopPrank();
    }

    function test_mintPublicSale1() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);

    }

    function test_mintPublicSale2() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }

    function test_Deposit() public {
        test_togglePublicSale();
        test_mintPublicSale1();
        test_mintPublicSale2();

        vm.startPrank(depositor1);
        _spacerats.setApprovalForAll(address(_asteroidMine),true);
        uint64[] memory array = new uint64[](2); 
        array[0] = 1;
        array[1] = 2;
        _asteroidMine.depositNft(depositor1,array);


    }


    
}


