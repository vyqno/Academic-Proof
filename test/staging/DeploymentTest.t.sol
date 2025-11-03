// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeploySystem} from "../../script/DeploySystem.s.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {AcademicCredential} from "../../src/AcademicCredential.sol";
import {CredentialVerifier} from "../../src/CredentialVerifier.sol";

/**
 * @title DeploymentTest
 * @notice Staging tests for deployment script
 * @dev Run on fork: forge test --match-path test/staging/* --fork-url $SEPOLIA_RPC_URL
 */
contract DeploymentTest is Test {
    DeploySystem public deployer;

    function setUp() public {
        deployer = new DeploySystem();
    }

    function testDeploymentOnAnvil() public {
        // Test deployment on local anvil
        (UniversityRegistry registry, AcademicCredential credential, CredentialVerifier verifier) = deployer.run();

        // Verify contracts are deployed
        assertTrue(address(registry) != address(0), "Registry should be deployed");
        assertTrue(address(credential) != address(0), "Credential should be deployed");
        assertTrue(address(verifier) != address(0), "Verifier should be deployed");

        // Verify contract connections
        assertEq(credential.getUniversityRegistry(), address(registry), "Credential should reference registry");

        (address credAddr, address regAddr) = verifier.getContracts();
        assertEq(credAddr, address(credential), "Verifier should reference credential");
        assertEq(regAddr, address(registry), "Verifier should reference registry");

        console.log("Deployment successful!");
        console.log("Registry:", address(registry));
        console.log("Credential:", address(credential));
        console.log("Verifier:", address(verifier));
    }

    function testDeploymentOwnership() public {
        (UniversityRegistry registry,,) = deployer.run();

        // Check that deployer is the owner
        address owner = registry.owner();
        assertTrue(owner != address(0), "Owner should be set");

        console.log("Registry owner:", owner);
    }

    function testBasicFunctionalityAfterDeployment() public {
        (UniversityRegistry registry, AcademicCredential credential,) = deployer.run();

        // Test basic functionality
        address[] memory signers = new address[](1);
        signers[0] = makeAddr("signer");

        // Register a university
        vm.prank(registry.owner());
        uint256 universityId =
            registry.registerUniversity(makeAddr("admin"), "Test University", "USA", "ipfs://test", signers, 1);

        assertEq(universityId, 1, "First university should have ID 1");
        assertTrue(registry.isUniversityActive(universityId), "University should be active");

        // Test credential counter
        assertEq(credential.getTotalCredentials(), 0, "Should start with 0 credentials");

        console.log("Basic functionality test passed!");
    }
}
