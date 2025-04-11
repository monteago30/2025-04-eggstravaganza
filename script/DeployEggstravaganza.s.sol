// SPDX-License-Identifier: MIT

import "../lib/forge-std/src/Script.sol";
import "../src/EggstravaganzaNFT.sol";
import "../src/EggVault.sol";
import "../src/EggHuntGame.sol";

contract DeployEggstravaganza is Script {
    function run() external {
        // Load the private key from .env
        uint256 newDeployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        address newDeployer = vm.addr(newDeployerPrivateKey);
        console.log("Deploying contracts from address:", newDeployer);

        // Start the boradcasting tranasactions
        vm.startBroadcast(newDeployerPrivateKey);

        // Deploy the EggstravaganzaNFT contract
        EggstravaganzaNFT eggNft = new EggstravaganzaNFT("Eggstravaganza", "EGG");
        console.log("EggstravaganzaNFT deployed at:", address(eggNft));

        // Deploy the EggVault contract
        EggVault eggVault = new EggVault();
        console.log("EggVault deployed at:", address(eggVault));

        // Deploy the EggHuntGame contract with references to NFT and Vault
        EggHuntGame eggGame = new EggHuntGame(address(eggNft), address(eggVault));
        console.log("EggHuntGame deployed at:", address(eggGame));

        // Configure the NFT contract to accept minting requests from the game
        eggNft.setGameContract(address(eggGame));
        console.log("NFT game contract set to:", address(eggGame));

        // Configure the vault with the NFT contract reference
        eggVault.setEggNFT(address(eggNft));
        console.log("EggVault NFT contract set to:", address(eggNft));

        // Stop the broadcasting transactions
        vm.stopBroadcast();

        // Print summary
        console.log("Deployment complete!");
        console.log("To start the game, call startGame(duration on the game contract.");
        console.log("--------------------------------------------");
        console.log("CONTRACT ADDRESS (save these for interaction)");
        console.log("--------------------------------------------");
        console.log("EGG NFT Contract:", address(eggNft));
        console.log("EGG Vault Contract:", address(eggVault));
        console.log("Egg Game Contract:", address(eggGame));
    }
}
