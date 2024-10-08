// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ,) = helperConfig.activeNetworkConfig(); 
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint64){
        console.log("ChainId is:", block.chainid);

        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id is:", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");

        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            , 
            , 
            address vrfCoordinator,
            ,
            uint64 subId,
            , 
            address link,
            uint256 deployKey) = helperConfig.activeNetworkConfig(); 
            fundSubscription(vrfCoordinator,subId,link);
    }

    function fundSubscription(
        address vrfCoordinator, 
        uint64 subId, 
        address link
    ) public {
        console.log("Funding subscription:", subId);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("On ChainID:", block.chainid);

        if (block.chainid == 31337){
            vm.startBroadcast();

            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );

            vm.stopBroadcast();
        } else {
            vm.startBroadcast();

            LinkToken(link).transferAndCall(
                vrfCoordinator, 
                FUND_AMOUNT, 
                abi.encode(subId)
            );

            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address raffle) public {        
        HelperConfig helperConfig = new HelperConfig();
        (
            , 
            , 
            address vrfCoordinator,
            ,
            uint64 subId,
            , 
            ,
            uint256 deployKey
        ) = helperConfig.activeNetworkConfig();  
        addConsumer(raffle,vrfCoordinator,subId,deployKey);
    }

    function addConsumer(
        address raffle, 
        address vrfCoordinator, 
        uint64 subId,
        uint256 deployKey
    )  public {
        console.log("Adding consumer contract:", raffle);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("On ChainID:", block.chainid);

        vm.startBroadcast(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        // vm.startBroadcast(deployKey)
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
        addConsumerUsingConfig(raffle);
    }
    
}