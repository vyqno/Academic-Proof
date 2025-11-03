// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AcademicCredential} from "../../src/AcademicCredential.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {CredentialVerifier} from "../../src/CredentialVerifier.sol";
import {CredentialMetadata} from "../../src/libraries/CredentialMetadata.sol";

/**
 * @title Integration Tests
 * @notice Tests complete workflows across all contracts
 */
contract IntegrationTest is Test {
    AcademicCredential public credential;
    UniversityRegistry public registry;
    CredentialVerifier public verifier;

    address public owner;
    address public mitAdmin;
    address public harvardAdmin;
    address public mitSigner1;
    address public mitSigner2;
    address public harvardSigner;
    address public student1;
    address public student2;
    address public employer;

    uint256 public mitId;
    uint256 public harvardId;

    function setUp() public {
        // Set a reasonable starting timestamp to avoid underflow (2+ years)
        vm.warp(800 days);

        owner = makeAddr("owner");
        mitAdmin = makeAddr("mitAdmin");
        harvardAdmin = makeAddr("harvardAdmin");
        mitSigner1 = makeAddr("mitSigner1");
        mitSigner2 = makeAddr("mitSigner2");
        harvardSigner = makeAddr("harvardSigner");
        student1 = makeAddr("student1");
        student2 = makeAddr("student2");
        employer = makeAddr("employer");

        // Deploy all contracts
        vm.startPrank(owner);
        registry = new UniversityRegistry();
        credential = new AcademicCredential(address(registry));
        verifier = new CredentialVerifier(address(credential), address(registry));

        // Register MIT with multi-sig
        address[] memory mitSigners = new address[](2);
        mitSigners[0] = mitSigner1;
        mitSigners[1] = mitSigner2;
        mitId = registry.registerUniversity(mitAdmin, "MIT", "USA", "ipfs://mit-metadata", mitSigners, 2);

        // Register Harvard with single sig
        address[] memory harvardSigners = new address[](1);
        harvardSigners[0] = harvardSigner;
        harvardId =
            registry.registerUniversity(harvardAdmin, "Harvard", "USA", "ipfs://harvard-metadata", harvardSigners, 1);

        vm.stopPrank();
    }

    /**
     * @notice Complete flow: Student graduates from MIT with multi-sig approval
     */
    function testCompleteGraduationFlow() public {
        // Step 1: University initiates credential
        vm.prank(mitSigner1);
        uint256 credId = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385, // 3.85 GPA
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp - 7 days,
            "ipfs://student1-bs-cs"
        );

        // Step 2: Verify pending status
        (uint256 sigCount, uint256 required, bool issued) = credential.getApprovalStatus(credId);
        assertEq(sigCount, 1);
        assertEq(required, 2);
        assertFalse(issued);

        // Step 3: Second signer approves
        vm.prank(mitSigner2);
        credential.signCredential(credId);

        // Step 4: Verify issued
        (,, issued) = credential.getApprovalStatus(credId);
        assertTrue(issued);

        // Step 5: Student receives NFT
        assertEq(credential.ownerOf(credId), student1);
        assertEq(credential.balanceOf(student1), 1);

        // Step 6: Employer verifies credential
        vm.prank(employer);
        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(credId);

        assertTrue(result.isValid);
        assertEq(result.student, student1);
        assertEq(result.universityName, "MIT");
        assertEq(result.major, "Computer Science");
        assertEq(result.gpa, 385);
        assertFalse(result.isRevoked);
    }

    /**
     * @notice Flow: Auto-issue with single signature
     */
    function testAutoIssueFlow() public {
        vm.prank(harvardSigner);
        uint256 credId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.MASTER,
            "Business Administration",
            390,
            CredentialMetadata.Honors.CUM_LAUDE,
            block.timestamp,
            "ipfs://student1-mba"
        );

        // Should be auto-issued
        (,, bool issued) = credential.getApprovalStatus(credId);
        assertTrue(issued);
        assertEq(credential.ownerOf(credId), student1);
    }

    /**
     * @notice Flow: Fraud detection and revocation
     */
    function testFraudRevocationFlow() public {
        // Issue credential
        vm.prank(harvardSigner);
        uint256 credId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Economics",
            350,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://student1-econ"
        );

        // Verify it's valid
        assertTrue(verifier.isCredentialValid(credId));

        // Fraud detected - revoke
        vm.prank(harvardSigner);
        credential.revokeCredential(credId, "Academic dishonesty discovered");

        // Verify it's now invalid
        assertFalse(verifier.isCredentialValid(credId));

        vm.prank(employer);
        CredentialVerifier.VerificationResult memory result = verifier.verifyCredential(credId);
        assertTrue(result.isRevoked);
        assertFalse(result.isValid);

        string memory summary = verifier.getVerificationSummary(credId);
        console.log("Revoked credential summary:", summary);
    }

    /**
     * @notice Flow: Student with multiple degrees
     */
    function testMultipleDegreeFlow() public {
        // Bachelor's from Harvard
        vm.prank(harvardSigner);
        uint256 bachelorId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            390,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp - 730 days,
            "ipfs://bs"
        );

        // Master's from MIT
        vm.startPrank(mitSigner1);
        uint256 masterId = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.MASTER,
            "Artificial Intelligence",
            395,
            CredentialMetadata.Honors.SUMMA_CUM_LAUDE,
            block.timestamp,
            "ipfs://ms"
        );
        vm.stopPrank();

        vm.prank(mitSigner2);
        credential.signCredential(masterId);

        // Verify student has both degrees
        uint256[] memory creds = credential.getStudentCredentials(student1);
        assertEq(creds.length, 2);

        // Verify both with employer
        vm.prank(employer);
        CredentialVerifier.VerificationResult[] memory results = verifier.verifyStudentCredentials(student1);

        assertEq(results.length, 2);
        assertTrue(results[0].isValid);
        assertTrue(results[1].isValid);

        // Check student has bachelor's
        assertTrue(verifier.hasValidDegree(student1, CredentialMetadata.DegreeType.BACHELOR, "Computer Science"));

        // Check student has master's
        assertTrue(verifier.hasValidDegree(student1, CredentialMetadata.DegreeType.MASTER, ""));
    }

    /**
     * @notice Flow: Batch verification for multiple students
     */
    function testBatchVerificationFlow() public {
        // Issue credentials to multiple students
        vm.startPrank(mitSigner1);
        uint256 cred1 = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Physics",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://1"
        );

        uint256 cred2 = credential.requestCredential(
            student2,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Mathematics",
            395,
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://2"
        );
        vm.stopPrank();

        vm.startPrank(mitSigner2);
        credential.signCredential(cred1);
        credential.signCredential(cred2);
        vm.stopPrank();

        // Employer batch verifies
        uint256[] memory ids = new uint256[](2);
        ids[0] = cred1;
        ids[1] = cred2;

        vm.prank(employer);
        CredentialVerifier.VerificationResult[] memory results = verifier.batchVerifyCredentials(ids);

        assertEq(results.length, 2);
        assertTrue(results[0].isValid);
        assertTrue(results[1].isValid);
        assertEq(results[0].student, student1);
        assertEq(results[1].student, student2);
    }

    /**
     * @notice Flow: University management - add/remove signers
     */
    function testUniversityManagementFlow() public {
        address newSigner = makeAddr("newSigner");

        // Add new signer
        vm.prank(mitAdmin);
        registry.addSigner(mitId, newSigner);

        assertTrue(registry.isAuthorizedSigner(mitId, newSigner));

        // New signer can sign credentials
        vm.prank(mitSigner1);
        uint256 credId = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.MASTER,
            "Engineering",
            380,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://eng"
        );

        vm.prank(newSigner);
        credential.signCredential(credId);

        (,, bool issued) = credential.getApprovalStatus(credId);
        assertTrue(issued);

        // Remove old signer
        vm.prank(mitAdmin);
        registry.removeSigner(mitId, mitSigner2);

        assertFalse(registry.isAuthorizedSigner(mitId, mitSigner2));
    }

    /**
     * @notice Flow: Deactivate university prevents new credentials
     */
    function testUniversityDeactivationFlow() public {
        // Deactivate MIT
        vm.prank(owner);
        registry.deactivateUniversity(mitId);

        // Try to issue credential
        vm.prank(mitSigner1);
        vm.expectRevert(AcademicCredential.AcademicCredential__UniversityNotActive.selector);
        credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://cred"
        );

        // Reactivate
        vm.prank(owner);
        registry.reactivateUniversity(mitId);

        // Now it works
        vm.prank(mitSigner1);
        uint256 credId = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://cred"
        );

        assertTrue(credId > 0);
    }

    /**
     * @notice Flow: QR code generation for verification
     */
    function testQRCodeFlow() public {
        vm.prank(harvardSigner);
        uint256 credId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://cred"
        );

        string memory qrData = credential.getQRCodeData(credId);
        assertTrue(bytes(qrData).length > 0);

        // QR data should contain key information
        console.log("QR Code Data:", qrData);
    }

    /**
     * @notice Flow: Restore revoked credential
     */
    function testCredentialRestorationFlow() public {
        vm.prank(harvardSigner);
        uint256 credId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.BACHELOR,
            "History",
            370,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://history"
        );

        // Revoke
        vm.prank(harvardSigner);
        credential.revokeCredential(credId, "Under investigation");
        assertFalse(verifier.isCredentialValid(credId));

        // Investigation cleared - restore
        vm.prank(harvardSigner);
        credential.restoreCredential(credId);
        assertTrue(verifier.isCredentialValid(credId));
    }

    /**
     * @notice Flow: Soulbound - cannot transfer
     */
    function testSoulboundFlow() public {
        vm.prank(harvardSigner);
        uint256 credId = credential.requestCredential(
            student1,
            harvardId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://cred"
        );

        // Student cannot transfer
        vm.prank(student1);
        vm.expectRevert(AcademicCredential.AcademicCredential__TransferNotAllowed.selector);
        credential.transferFrom(student1, student2, credId);

        // Still owned by student1
        assertEq(credential.ownerOf(credId), student1);
    }

    /**
     * @notice Flow: Complete employer verification workflow
     */
    function testEmployerVerificationWorkflow() public {
        // Student graduates
        vm.prank(mitSigner1);
        uint256 credId = credential.requestCredential(
            student1,
            mitId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            395,
            CredentialMetadata.Honors.SUMMA_CUM_LAUDE,
            block.timestamp - 30 days,
            "ipfs://bs-cs"
        );

        vm.prank(mitSigner2);
        credential.signCredential(credId);

        // Employer receives credential ID from student
        // Employer performs quick validity check
        vm.startPrank(employer);
        assertTrue(verifier.isCredentialValid(credId));

        // Employer gets full details
        CredentialVerifier.VerificationResult memory result = verifier.getCredentialDetails(credId);
        assertEq(result.student, student1);
        assertEq(result.major, "Computer Science");
        assertTrue(result.gpa >= 350); // At least 3.5 GPA

        // Employer gets human-readable summary
        string memory summary = verifier.getVerificationSummary(credId);
        console.log("Verification Summary:", summary);

        // Employer checks if student has required degree
        assertTrue(verifier.hasValidDegree(student1, CredentialMetadata.DegreeType.BACHELOR, "Computer Science"));
        vm.stopPrank();
    }
}
