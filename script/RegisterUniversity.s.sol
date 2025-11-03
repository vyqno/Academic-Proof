// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {UniversityRegistry} from "../src/UniversityRegistry.sol";

/**
 * @title RegisterUniversity
 * @notice Script for registering new universities
 * @dev Run with: forge script script/RegisterUniversity.s.sol:RegisterUniversity --rpc-url <RPC_URL> --broadcast
 *
 * Environment variables required:
 * - PRIVATE_KEY: Deployer/owner private key
 * - REGISTRY_ADDRESS: Address of deployed UniversityRegistry
 * - UNI_ADMIN: University administrator address
 * - UNI_NAME: University name
 * - UNI_COUNTRY: University country
 * - UNI_METADATA_URI: IPFS URI for university metadata
 * - SIGNERS: Comma-separated list of signer addresses
 * - REQUIRED_SIGNERS: Number of required signatures
 */
contract RegisterUniversity is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        address uniAdmin = vm.envAddress("UNI_ADMIN");
        string memory uniName = vm.envString("UNI_NAME");
        string memory uniCountry = vm.envString("UNI_COUNTRY");
        string memory metadataURI = vm.envString("UNI_METADATA_URI");
        uint256 requiredSigners = vm.envUint("REQUIRED_SIGNERS");

        // Parse signers
        string memory signersStr = vm.envString("SIGNERS");
        address[] memory signers = _parseAddresses(signersStr);

        console.log("Registering university...");
        console.log("Registry address:", registryAddress);
        console.log("University admin:", uniAdmin);
        console.log("University name:", uniName);
        console.log("Country:", uniCountry);
        console.log("Required signers:", requiredSigners);
        console.log("Number of signers:", signers.length);

        UniversityRegistry registry = UniversityRegistry(registryAddress);

        vm.startBroadcast(deployerPrivateKey);

        uint256 universityId =
            registry.registerUniversity(uniAdmin, uniName, uniCountry, metadataURI, signers, requiredSigners);

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("UNIVERSITY REGISTERED");
        console.log("========================================");
        console.log("University ID:", universityId);
        console.log("Name:", uniName);
        console.log("Admin:", uniAdmin);
        console.log("========================================");
    }

    function _parseAddresses(string memory addressesStr) internal pure returns (address[] memory) {
        // Simple parser for comma-separated addresses
        // Format: "0x123...,0x456...,0x789..."
        bytes memory strBytes = bytes(addressesStr);
        uint256 count = 1;

        // Count commas to determine array size
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == ",") {
                count++;
            }
        }

        address[] memory addresses = new address[](count);
        uint256 index = 0;
        uint256 start = 0;

        for (uint256 i = 0; i <= strBytes.length; i++) {
            if (i == strBytes.length || strBytes[i] == ",") {
                // Extract substring
                bytes memory addrBytes = new bytes(i - start);
                for (uint256 j = start; j < i; j++) {
                    addrBytes[j - start] = strBytes[j];
                }

                // Convert to address (simplified - assumes valid hex)
                addresses[index] = _parseAddress(string(addrBytes));
                index++;
                start = i + 1;
            }
        }

        return addresses;
    }

    function _parseAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "Invalid address length");

        bytes memory addrBytes = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] =
                bytes1(_fromHexChar(uint8(strBytes[2 + i * 2])) * 16 + _fromHexChar(uint8(strBytes[3 + i * 2])));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function _fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }
}
