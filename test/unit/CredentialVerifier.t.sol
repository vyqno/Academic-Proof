// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CredentialVerifier} from "../../src/CredentialVerifier.sol";
import {AcademicCredential} from "../../src/AcademicCredential.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {CredentialMetadata} from "../../src/libraries/CredentialMetadata.sol";

contract CredentialVerifierTest is Test {
    CredentialVerifier public verifier;
    AcademicCredential public credential;
    UniversityRegistry public registry;

    address public owner;
    address public uniAdmin;
    address public signer1;
    address public signer2;
    address public student;

    uint256 public universityId;

    function setUp() public {
        // Set a reasonable starting timestamp to avoid underflow
        vm.warp(365 days);

        owner = makeAddr("owner");
        uniAdmin = makeAddr("uniAdmin");
        signer1 = makeAddr("signer1");
        signer2 = makeAddr("signer2");
        student = makeAddr("student");

        vm.startPrank(owner);
        registry = new UniversityRegistry();

        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        credential = new AcademicCredential(address(registry));
        verifier = new CredentialVerifier(address(credential), address(registry));
        vm.stopPrank();
    }

    function testVerifierDeployment() public view {
        (address credAddr, address regAddr) = verifier.getContracts();
        assertEq(credAddr, address(credential));
        assertEq(regAddr, address(registry));
    }

    function testVerifyNonExistentCredential() public {
        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(999);

        assertFalse(result.exists);
        assertFalse(result.isValid);
    }

    function testVerifyPendingCredential() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential"
        );

        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(credentialId);

        assertTrue(result.exists);
        assertFalse(result.isIssued);
        assertFalse(result.isValid);
        assertEq(result.student, student);
        assertEq(result.universityId, universityId);
        assertEq(result.major, "Computer Science");
    }

    function testVerifyIssuedCredential() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.prank(signer2);
        credential.signCredential(credentialId);

        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(credentialId);

        assertTrue(result.exists);
        assertTrue(result.isIssued);
        assertFalse(result.isRevoked);
        assertTrue(result.isValid);
        assertEq(result.student, student);
        assertEq(result.universityName, "MIT");
        assertEq(result.major, "Computer Science");
        assertEq(result.gpa, 385);
        assertEq(uint256(result.degreeType), uint256(CredentialMetadata.DegreeType.BACHELOR));
        assertEq(uint256(result.honors), uint256(CredentialMetadata.Honors.MAGNA_CUM_LAUDE));
    }

    function testVerifyRevokedCredential() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.prank(signer2);
        credential.signCredential(credentialId);

        vm.prank(signer1);
        credential.revokeCredential(credentialId, "Test revocation");

        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(credentialId);

        assertTrue(result.exists);
        assertTrue(result.isIssued);
        assertTrue(result.isRevoked);
        assertFalse(result.isValid);
    }

    function testIsCredentialValid() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        assertFalse(verifier.isCredentialValid(credentialId));

        vm.prank(signer2);
        credential.signCredential(credentialId);

        assertTrue(verifier.isCredentialValid(credentialId));

        vm.prank(signer1);
        credential.revokeCredential(credentialId, "Test");

        assertFalse(verifier.isCredentialValid(credentialId));
    }

    function testGetCredentialDetails() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.DOCTORATE,
            "Physics",
            400, // 4.00 GPA
            CredentialMetadata.Honors.SUMMA_CUM_LAUDE,
            block.timestamp - 30 days,
            "ipfs://credential"
        );

        vm.prank(signer2);
        credential.signCredential(credentialId);

        CredentialVerifier.VerificationResult memory result = verifier.getCredentialDetails(credentialId);

        assertTrue(result.isValid);
        assertEq(result.major, "Physics");
        assertEq(result.gpa, 400);
        assertEq(uint256(result.degreeType), uint256(CredentialMetadata.DegreeType.DOCTORATE));
    }

    function testBatchVerifyCredentials() public {
        // Create multiple credentials
        vm.startPrank(signer1);
        uint256 cred1 = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential1"
        );

        uint256 cred2 = credential.requestCredential(
            makeAddr("student2"),
            universityId,
            CredentialMetadata.DegreeType.MASTER,
            "Mathematics",
            395,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential2"
        );
        vm.stopPrank();

        vm.startPrank(signer2);
        credential.signCredential(cred1);
        credential.signCredential(cred2);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        ids[0] = cred1;
        ids[1] = cred2;

        CredentialVerifier.VerificationResult[] memory results = verifier.batchVerifyCredentials(ids);

        assertEq(results.length, 2);
        assertTrue(results[0].isValid);
        assertTrue(results[1].isValid);
        assertEq(results[0].major, "Computer Science");
        assertEq(results[1].major, "Mathematics");
    }

    function testVerifyStudentCredentials() public {
        // Create multiple credentials for same student
        vm.startPrank(signer1);
        uint256 cred1 = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp - 365 days,
            "ipfs://credential1"
        );

        uint256 cred2 = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.MASTER,
            "Data Science",
            395,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential2"
        );
        vm.stopPrank();

        vm.startPrank(signer2);
        credential.signCredential(cred1);
        credential.signCredential(cred2);
        vm.stopPrank();

        CredentialVerifier.VerificationResult[] memory results = verifier.verifyStudentCredentials(student);

        assertEq(results.length, 2);
        assertTrue(results[0].isValid);
        assertTrue(results[1].isValid);
        assertEq(results[0].student, student);
        assertEq(results[1].student, student);
    }

    function testGetVerificationSummary() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        // Pending credential
        string memory summary = verifier.getVerificationSummary(credentialId);
        assertTrue(bytes(summary).length > 0);

        vm.prank(signer2);
        credential.signCredential(credentialId);

        // Valid credential
        summary = verifier.getVerificationSummary(credentialId);
        assertTrue(bytes(summary).length > 0);

        vm.prank(signer1);
        credential.revokeCredential(credentialId, "Test");

        // Revoked credential
        summary = verifier.getVerificationSummary(credentialId);
        assertTrue(bytes(summary).length > 0);
    }

    function testGetVerificationSummaryNonExistent() public view {
        string memory summary = verifier.getVerificationSummary(999);
        assertTrue(bytes(summary).length > 0);
    }

    function testHasValidDegree() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.prank(signer2);
        credential.signCredential(credentialId);

        // Check with specific major
        assertTrue(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.BACHELOR, "Computer Science"));

        // Check with any major
        assertTrue(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.BACHELOR, ""));

        // Check wrong degree type
        assertFalse(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.MASTER, "Computer Science"));

        // Check wrong major
        assertFalse(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.BACHELOR, "Physics"));
    }

    function testHasValidDegreeIgnoresRevoked() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.prank(signer2);
        credential.signCredential(credentialId);

        assertTrue(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.BACHELOR, "Computer Science"));

        vm.prank(signer1);
        credential.revokeCredential(credentialId, "Test");

        assertFalse(verifier.hasValidDegree(student, CredentialMetadata.DegreeType.BACHELOR, "Computer Science"));
    }

    function testVerifierWithMultipleStudents() public {
        address student2 = makeAddr("student2");
        address student3 = makeAddr("student3");

        vm.startPrank(signer1);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://cred1"
        );

        credential.requestCredential(
            student2,
            universityId,
            CredentialMetadata.DegreeType.MASTER,
            "Physics",
            390,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://cred2"
        );

        credential.requestCredential(
            student3,
            universityId,
            CredentialMetadata.DegreeType.DOCTORATE,
            "Mathematics",
            400,
            CredentialMetadata.Honors.SUMMA_CUM_LAUDE,
            block.timestamp,
            "ipfs://cred3"
        );
        vm.stopPrank();

        vm.startPrank(signer2);
        credential.signCredential(1);
        credential.signCredential(2);
        credential.signCredential(3);
        vm.stopPrank();

        assertTrue(verifier.isCredentialValid(1));
        assertTrue(verifier.isCredentialValid(2));
        assertTrue(verifier.isCredentialValid(3));

        CredentialVerifier.VerificationResult memory result1 = verifier.getCredentialDetails(1);
        CredentialVerifier.VerificationResult memory result2 = verifier.getCredentialDetails(2);
        CredentialVerifier.VerificationResult memory result3 = verifier.getCredentialDetails(3);

        assertEq(result1.student, student);
        assertEq(result2.student, student2);
        assertEq(result3.student, student3);
    }
}
