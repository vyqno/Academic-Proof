// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {AcademicCredential} from "../../src/AcademicCredential.sol";
import {CredentialVerifier} from "../../src/CredentialVerifier.sol";
import {CredentialMetadata} from "../../src/libraries/CredentialMetadata.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title RegisterUniversityInteraction
 * @notice Interaction script to register a university
 */
contract RegisterUniversityInteraction is Script {
    function registerUniversity(address registryAddress) public {
        // Get the most recently deployed UniversityRegistry if address not provided
        if (registryAddress == address(0)) {
            registryAddress = DevOpsTools.get_most_recent_deployment("UniversityRegistry", block.chainid);
        }

        UniversityRegistry registry = UniversityRegistry(registryAddress);

        address uniAdmin = vm.envAddress("UNI_ADMIN");
        string memory uniName = vm.envString("UNI_NAME");
        string memory uniCountry = vm.envString("UNI_COUNTRY");
        string memory metadataURI = vm.envString("UNI_METADATA_URI");
        uint256 requiredSigners = vm.envUint("REQUIRED_SIGNERS");

        // Parse signers
        address signer1 = vm.envAddress("SIGNER_1");
        address signer2 = vm.envAddress("SIGNER_2");

        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        console.log("Registering university:", uniName);
        console.log("Registry:", registryAddress);
        console.log("Admin:", uniAdmin);

        vm.startBroadcast();

        uint256 universityId =
            registry.registerUniversity(uniAdmin, uniName, uniCountry, metadataURI, signers, requiredSigners);

        vm.stopBroadcast();

        console.log("University registered with ID:", universityId);
    }

    function run() external {
        registerUniversity(address(0));
    }
}

/**
 * @title IssueCredentialInteraction
 * @notice Interaction script to issue a credential
 */
contract IssueCredentialInteraction is Script {
    function issueCredential(address credentialAddress) public returns (uint256) {
        // Get the most recently deployed AcademicCredential if address not provided
        if (credentialAddress == address(0)) {
            credentialAddress = DevOpsTools.get_most_recent_deployment("AcademicCredential", block.chainid);
        }

        AcademicCredential credential = AcademicCredential(credentialAddress);

        address student = vm.envAddress("STUDENT_ADDRESS");
        uint256 universityId = vm.envUint("UNIVERSITY_ID");
        uint8 degreeTypeInt = uint8(vm.envUint("DEGREE_TYPE"));
        string memory major = vm.envString("MAJOR");
        uint16 gpa = uint16(vm.envUint("GPA"));
        uint8 honorsInt = uint8(vm.envUint("HONORS"));
        uint256 graduationDate = vm.envUint("GRADUATION_DATE");
        string memory metadataURI = vm.envString("METADATA_URI");

        CredentialMetadata.DegreeType degreeType = CredentialMetadata.DegreeType(degreeTypeInt);
        CredentialMetadata.Honors honors = CredentialMetadata.Honors(honorsInt);

        console.log("Issuing credential...");
        console.log("Credential contract:", credentialAddress);
        console.log("Student:", student);
        console.log("University ID:", universityId);

        vm.startBroadcast();

        uint256 credentialId = credential.requestCredential(
            student, universityId, degreeType, major, gpa, honors, graduationDate, metadataURI
        );

        vm.stopBroadcast();

        console.log("Credential requested with ID:", credentialId);

        return credentialId;
    }

    function run() external returns (uint256) {
        return issueCredential(address(0));
    }
}

/**
 * @title SignCredentialInteraction
 * @notice Interaction script to sign a credential
 */
contract SignCredentialInteraction is Script {
    function signCredential(address credentialAddress, uint256 credentialId) public {
        // Get the most recently deployed AcademicCredential if address not provided
        if (credentialAddress == address(0)) {
            credentialAddress = DevOpsTools.get_most_recent_deployment("AcademicCredential", block.chainid);
        }

        AcademicCredential credential = AcademicCredential(credentialAddress);

        console.log("Signing credential ID:", credentialId);
        console.log("Credential contract:", credentialAddress);

        // Get approval status before signing
        (uint256 sigCount, uint256 required, bool issued) = credential.getApprovalStatus(credentialId);
        console.log("Before - Signatures:", sigCount);
        console.log("Required:", required);
        console.log("Issued:", issued);

        vm.startBroadcast();

        credential.signCredential(credentialId);

        vm.stopBroadcast();

        // Get approval status after signing
        (sigCount, required, issued) = credential.getApprovalStatus(credentialId);
        console.log("After - Signatures:", sigCount);
        console.log("Required:", required);
        console.log("Issued:", issued);

        if (issued) {
            console.log("Credential has been issued!");
        } else {
            console.log("Additional signatures required:", required - sigCount);
        }
    }

    function run() external {
        uint256 credentialId = vm.envUint("CREDENTIAL_ID");
        signCredential(address(0), credentialId);
    }
}

/**
 * @title VerifyCredentialInteraction
 * @notice Interaction script to verify a credential
 */
contract VerifyCredentialInteraction is Script {
    function verifyCredential(address verifierAddress, uint256 credentialId) public view {
        // Get the most recently deployed CredentialVerifier if address not provided
        if (verifierAddress == address(0)) {
            verifierAddress = DevOpsTools.get_most_recent_deployment("CredentialVerifier", block.chainid);
        }

        CredentialVerifier verifier = CredentialVerifier(verifierAddress);

        console.log("Verifying credential ID:", credentialId);
        console.log("Verifier contract:", verifierAddress);

        CredentialVerifier.VerificationResult memory result = verifier.getCredentialDetails(credentialId);

        console.log("\n========================================");
        console.log("VERIFICATION RESULT");
        console.log("========================================");

        if (!result.exists) {
            console.log("Status: DOES NOT EXIST");
            return;
        }

        console.log("Valid:", result.isValid);
        console.log("Issued:", result.isIssued);
        console.log("Revoked:", result.isRevoked);
        console.log("");
        console.log("Student:", result.student);
        console.log("University:", result.universityName);
        console.log("Major:", result.major);
        console.log("GPA:", result.gpa);
        console.log("========================================");

        string memory summary = verifier.getVerificationSummary(credentialId);
        console.log("\nSummary:", summary);
    }

    function run() external view {
        uint256 credentialId = vm.envUint("CREDENTIAL_ID");
        verifyCredential(address(0), credentialId);
    }
}

/**
 * @title RevokeCredentialInteraction
 * @notice Interaction script to revoke a credential
 */
contract RevokeCredentialInteraction is Script {
    function revokeCredential(address credentialAddress, uint256 credentialId, string memory reason) public {
        // Get the most recently deployed AcademicCredential if address not provided
        if (credentialAddress == address(0)) {
            credentialAddress = DevOpsTools.get_most_recent_deployment("AcademicCredential", block.chainid);
        }

        AcademicCredential credential = AcademicCredential(credentialAddress);

        console.log("Revoking credential ID:", credentialId);
        console.log("Reason:", reason);

        vm.startBroadcast();

        credential.revokeCredential(credentialId, reason);

        vm.stopBroadcast();

        console.log("Credential revoked successfully");
    }

    function run() external {
        uint256 credentialId = vm.envUint("CREDENTIAL_ID");
        string memory reason = vm.envString("REVOKE_REASON");
        revokeCredential(address(0), credentialId, reason);
    }
}

/**
 * @title GetStudentCredentialsInteraction
 * @notice Interaction script to get all credentials for a student
 */
contract GetStudentCredentialsInteraction is Script {
    function getStudentCredentials(address credentialAddress, address studentAddress) public view {
        // Get the most recently deployed AcademicCredential if address not provided
        if (credentialAddress == address(0)) {
            credentialAddress = DevOpsTools.get_most_recent_deployment("AcademicCredential", block.chainid);
        }

        AcademicCredential credential = AcademicCredential(credentialAddress);

        console.log("Getting credentials for student:", studentAddress);

        uint256[] memory credentialIds = credential.getStudentCredentials(studentAddress);

        console.log("\n========================================");
        console.log("Student has", credentialIds.length, "credential(s)");
        console.log("========================================");

        for (uint256 i = 0; i < credentialIds.length; i++) {
            console.log("\nCredential", i + 1, "- ID:", credentialIds[i]);

            CredentialMetadata.Credential memory cred = credential.getCredential(credentialIds[i]);
            console.log("  University ID:", cred.universityId);
            console.log("  Major:", cred.major);
            console.log("  GPA:", cred.gpa);
            console.log("  Revoked:", cred.isRevoked);
        }
    }

    function run() external view {
        address studentAddress = vm.envAddress("STUDENT_ADDRESS");
        getStudentCredentials(address(0), studentAddress);
    }
}
