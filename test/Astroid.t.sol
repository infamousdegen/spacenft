// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import 'src/AsteroidMine.sol';
import 'src/SpaceRatNft.sol';
import 'lib/solmate/src/test/utils/mocks/MockERC20.sol';
import "forge-std/console.sol";


contract AsterpodTest is Test {

    address owner = address(0x69);
    address depositor1 = address(0x50);
    address depositor2 = address(0x39);
    address random1 = address(0x420);
    address random2 = address(0x421);
    SpaceRats _spacerats;
    AsteroidMines _asteroidMine;
    MockERC20 mocktoken;

    function setUp() public {
        vm.startPrank(owner);
        _spacerats = new SpaceRats();
        mocktoken = new MockERC20("MockToken","MCK",18);
        _asteroidMine = new AsteroidMines(random1,random2,_spacerats,address(mocktoken));
        mocktoken.mint(address(_asteroidMine),type(uint256).max);

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

    function test_mintPublicSale3() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }

    function test_mintPublicSale4() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale5() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale6() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale7() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale8() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale9() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }
        function test_mintPublicSale10() public {
        vm.prank(depositor1);
        _spacerats.publicSale(depositor1);
    }


    function test_Deposit() public {
        test_togglePublicSale();
        test_mintPublicSale1();
        test_mintPublicSale2();
        test_mintPublicSale3();
        vm.startPrank(depositor1);
        _spacerats.setApprovalForAll(address(_asteroidMine),true);
        uint256[] memory array = new uint256[](3); 
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;
        _asteroidMine.depositNft(depositor1,array);
        vm.stopPrank();



    }

    function test_claimIridium() public {
        test_Deposit();
        vm.startPrank(depositor1);

        console.log(_spacerats.balanceOf(depositor1));

        vm.warp(1641070800);
        uint256[] memory array = new uint256[](3); 
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;

        _asteroidMine.claimIridium(array);
    }

    function test_withdraw() public{
        test_Deposit();

        vm.startPrank(depositor1);
        uint256[] memory array = new uint256[](3); 
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;
        _asteroidMine.withdraw(array);
    }

    
}


