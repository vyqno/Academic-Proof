// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AcademicCredential} from "../src/AcademicCredential.sol";
import {CredentialMetadata} from "../src/libraries/CredentialMetadata.sol";

/**
 * @title IssueCredential
 * @notice Script for issuing academic credentials
 * @dev Run with: forge script script/IssueCredential.s.sol:IssueCredential --rpc-url <RPC_URL> --broadcast
 *
 * Environment variables required:
 * - PRIVATE_KEY: Authorized signer private key
 * - CREDENTIAL_ADDRESS: Address of deployed AcademicCredential
 * - STUDENT_ADDRESS: Student wallet address
 * - UNIVERSITY_ID: University ID
 * - DEGREE_TYPE: Degree type (0-5: ASSOCIATE, BACHELOR, MASTER, DOCTORATE, CERTIFICATE, DIPLOMA)
 * - MAJOR: Field of study
 * - GPA: GPA * 100 (e.g., 385 for 3.85)
 * - HONORS: Honors level (0-5: NONE, CUM_LAUDE, MAGNA_CUM_LAUDE, SUMMA_CUM_LAUDE, WITH_DISTINCTION, WITH_HIGH_DISTINCTION)
 * - GRADUATION_DATE: Unix timestamp of graduation
 * - METADATA_URI: IPFS URI for credential metadata
 */
contract IssueCredential is Script {
    function run() external returns (uint256 credentialId) {
        // Load environment variables
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        address credentialAddress = vm.envAddress("CREDENTIAL_ADDRESS");
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
        console.log("Major:", major);
        console.log("GPA:", gpa);
        console.log("Degree Type:", CredentialMetadata.degreeTypeToString(degreeType));
        console.log("Honors:", CredentialMetadata.honorsToString(honors));

        AcademicCredential credential = AcademicCredential(credentialAddress);

        vm.startBroadcast(signerPrivateKey);

        credentialId = credential.requestCredential(
            student, universityId, degreeType, major, gpa, honors, graduationDate, metadataURI
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("CREDENTIAL REQUESTED");
        console.log("========================================");
        console.log("Credential ID:", credentialId);
        console.log("Student:", student);
        console.log("Status: Awaiting additional signatures");
        console.log("========================================");

        return credentialId;
    }
}
