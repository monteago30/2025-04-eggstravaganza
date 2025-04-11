// SPDX-License-Identifier: MIT

import "../lib/forge-std/src/Script.sol";
import "../src/EggstravaganzaNFT.sol";
import "../src/EggVault.sol";
import "../src/EggHuntGame.sol";

contract InteractWithEggstravaganza is Script {
    // Contract addresses should be loaded from .env file
    EggstravaganzaNFT public eggNft;
    EggVault public eggVault;
    EggHuntGame public eggGame;

    address public owner;
    address public player1;
    address public player2;

    function run() external {
        // Load the private keys from the .env file
        uint256 ownerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        uint256 player1PrivateKey = vm.envUint("PLAYER1_PRIVATE_KEY");
        uint256 player2PrivateKey = vm.envUint("PLAYER2_PRIVATE_KEY");

        // Derive addresses from private keys
        owner = vm.addr(ownerPrivateKey);
        player1 = vm.addr(player1PrivateKey);
        player2 = vm.addr(player2PrivateKey);

        // Get contract addresses from .env file
        address eggNftAddress = vm.envAddress("EGG_NFT_ADDRESS");
        address eggVaultAddress = vm.envAddress("EGG_VAULT_ADDRESS");
        address eggGameAddress = vm.envAddress("EGG_GAME_ADDRESS");

        // Get the contract references
        eggNft = EggstravaganzaNFT(eggNftAddress);
        eggVault = EggVault(eggVaultAddress);
        eggGame = EggHuntGame(eggGameAddress);

        console.log("Loaded Contracts:");
        console.log("- NFT:", eggNftAddress);
        console.log("- Vault:", eggVaultAddress);
        console.log("- Game:", eggGameAddress);
        console.log("");
        console.log("Participants:");
        console.log("- Owner:", owner);
        console.log("- Player 1:", player1);
        console.log("- Player 2:", player2);
        console.log("");

        // Admin starts the game with a 30-minute duration
        vm.startBroadcast(ownerPrivateKey);
        eggGame.startGame(1800);
        // Set egg find threshold to 50% to make it easier to find eggs
        eggGame.setEggFindThreshold(50);
        vm.stopBroadcast();
        console.log("Game started with a 30-minute duration");
        console.log("Egg find threshold set to 50%");

        // Player 1 searches for eggs multiple times
        vm.startBroadcast(player1PrivateKey);
        for (uint256 i = 0; i < 10; i++) {
            eggGame.searchForEgg();
        }
        vm.stopBroadcast();
        console.log("Player 1 searched for eggs 10 times");

        // Check eggs found by Player 1
        uint256 player1Eggs = eggGame.eggsFound(player1);
        console.log("Player 1 found", player1Eggs, "eggs");

        // Player 2 searches for eggs
        vm.startBroadcast(player2PrivateKey);
        for (uint256 i = 0; i < 10; i++) {
            eggGame.searchForEgg();
        }
        vm.stopBroadcast();
        console.log("Player 2 searched for eggs 10 times");

        // Check eggs found by Player 2
        uint256 player2Eggs = eggGame.eggsFound(player2);
        console.log("Player 2 found", player2Eggs, "eggs");

        // If Player 1 found any eggs, let's deposit one to the vault
        if (player1Eggs > 0) {
            // Find a token ID that Player 1 owns
            uint256 tokenId = findPlayerToken(player1);

            if (tokenId > 0) {
                // Player 1 approves game contract to transfer the NFT
                vm.startBroadcast(player1PrivateKey);
                eggNft.approve(address(eggGame), tokenId);
                eggGame.depositEggToVault(tokenId);
                vm.stopBroadcast();
                console.log("Player 1 deposited egg with token ID", tokenId, "to the vault");
            } else {
                console.log("Could not find a sutiable token for Player 1 to desposit");
            }
        }

        // Simulate the game ending (admin ends the game)
        vm.startBroadcast(ownerPrivateKey);
        eggGame.endGame();
        vm.stopBroadcast();
        console.log("Game ended");

        // Check game status
        string memory gameStatus = eggGame.getGameStatus();
        console.log("Final game status:", gameStatus);

        // Summary of final state
        console.log("");
        console.log("Final Game State:");
        console.log("-----------------");
        console.log("Total eggs found:", eggGame.eggCounter());
        console.log("Player 1 eggs:", eggGame.eggsFound(player1));
        console.log("Player 2 eggs:", eggGame.eggsFound(player2));
    }

    // Helper function to find a token owned by a player
    function findPlayerToken(address player) internal view returns (uint256) {
        uint256 totalEggs = eggGame.eggCounter();

        // Iterate through tokens to find one owned by the player
        for (uint256 i = 1; i <= totalEggs; i++) {
            try eggNft.ownerOf(i) returns (address owner) {
                if (owner == player) {
                    return i;
                }
            } catch {
                // Skip tokens that don't exist or have errors
                continue;
            }
        }
        return 0; // No token found
    }
}
