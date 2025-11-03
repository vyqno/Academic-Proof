// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AcademicCredential} from "../../src/AcademicCredential.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {CredentialMetadata} from "../../src/libraries/CredentialMetadata.sol";

contract AcademicCredentialTest is Test {
    AcademicCredential public credential;
    UniversityRegistry public registry;

    address public owner;
    address public uniAdmin;
    address public signer1;
    address public signer2;
    address public student;
    address public unauthorized;

    uint256 public universityId;

    event CredentialRequested(uint256 indexed credentialId, address indexed student, uint256 indexed universityId);
    event CredentialSigned(uint256 indexed credentialId, address indexed signer, uint256 signatureCount);
    event CredentialIssued(
        uint256 indexed credentialId,
        address indexed student,
        uint256 indexed universityId,
        CredentialMetadata.DegreeType degreeType
    );
    event CredentialRevoked(uint256 indexed credentialId, string reason);

    function setUp() public {
        owner = makeAddr("owner");
        uniAdmin = makeAddr("uniAdmin");
        signer1 = makeAddr("signer1");
        signer2 = makeAddr("signer2");
        student = makeAddr("student");
        unauthorized = makeAddr("unauthorized");

        vm.startPrank(owner);
        registry = new UniversityRegistry();

        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        credential = new AcademicCredential(address(registry));
        vm.stopPrank();
    }

    function testCredentialDeployment() public view {
        assertEq(credential.name(), "Academic Credential");
        assertEq(credential.symbol(), "ACADEM");
        assertEq(credential.getUniversityRegistry(), address(registry));
        assertEq(credential.getTotalCredentials(), 0);
    }

    function testRequestCredential() public {
        vm.prank(signer1);
        vm.expectEmit(true, true, true, false);
        emit CredentialRequested(1, student, universityId);

        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385, // 3.85 GPA
            CredentialMetadata.Honors.MAGNA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential"
        );

        assertEq(credentialId, 1);
        assertEq(credential.getTotalCredentials(), 1);

        CredentialMetadata.Credential memory cred = credential.getCredential(1);
        assertEq(cred.student, student);
        assertEq(cred.universityId, universityId);
        assertEq(uint256(cred.degreeType), uint256(CredentialMetadata.DegreeType.BACHELOR));
        assertEq(cred.major, "Computer Science");
        assertEq(cred.gpa, 385);
        assertEq(uint256(cred.honors), uint256(CredentialMetadata.Honors.MAGNA_CUM_LAUDE));
        assertFalse(cred.isRevoked);
    }

    function testRequestCredentialRevertsInvalidStudent() public {
        vm.prank(signer1);
        vm.expectRevert(AcademicCredential.AcademicCredential__InvalidStudent.selector);
        credential.requestCredential(
            address(0),
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );
    }

    function testRequestCredentialRevertsUnauthorizedSigner() public {
        vm.prank(unauthorized);
        vm.expectRevert(AcademicCredential.AcademicCredential__NotAuthorizedSigner.selector);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );
    }

    function testRequestCredentialRevertsInvalidGPA() public {
        vm.prank(signer1);
        vm.expectRevert(AcademicCredential.AcademicCredential__InvalidGPA.selector);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            500, // Invalid GPA > 4.00
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );
    }

    function testRequestCredentialRevertsInvalidGraduationDate() public {
        vm.prank(signer1);
        vm.expectRevert(AcademicCredential.AcademicCredential__InvalidGraduationDate.selector);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp + 1 days,
            "ipfs://credential"
        );
    }

    function testRequestCredentialRevertsDuplicate() public {
        vm.startPrank(signer1);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.expectRevert(AcademicCredential.AcademicCredential__CredentialAlreadyIssued.selector);
        credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential2"
        );
        vm.stopPrank();
    }

    function testSignCredential() public {
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

        (uint256 sigCount, uint256 required, bool issued) = credential.getApprovalStatus(credentialId);
        assertEq(sigCount, 1);
        assertEq(required, 2);
        assertFalse(issued);

        vm.prank(signer2);
        vm.expectEmit(true, true, false, true);
        emit CredentialSigned(credentialId, signer2, 2);
        credential.signCredential(credentialId);

        (sigCount, required, issued) = credential.getApprovalStatus(credentialId);
        assertEq(sigCount, 2);
        assertTrue(issued);
    }

    function testCredentialIssuedAfterEnoughSignatures() public {
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            universityId,
            CredentialMetadata.DegreeType.MASTER,
            "Artificial Intelligence",
            395,
            CredentialMetadata.Honors.SUMMA_CUM_LAUDE,
            block.timestamp,
            "ipfs://credential"
        );

        vm.prank(signer2);
        vm.expectEmit(true, true, true, true);
        emit CredentialIssued(credentialId, student, universityId, CredentialMetadata.DegreeType.MASTER);
        credential.signCredential(credentialId);

        // Verify NFT was minted
        assertEq(credential.ownerOf(credentialId), student);
        assertEq(credential.balanceOf(student), 1);

        uint256[] memory studentCreds = credential.getStudentCredentials(student);
        assertEq(studentCreds.length, 1);
        assertEq(studentCreds[0], credentialId);
    }

    function testSignCredentialRevertsAlreadySigned() public {
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

        vm.prank(signer1);
        vm.expectRevert(AcademicCredential.AcademicCredential__AlreadySigned.selector);
        credential.signCredential(credentialId);
    }

    function testRevokeCredential() public {
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
        vm.expectEmit(true, false, false, true);
        emit CredentialRevoked(credentialId, "Fraud detected");
        credential.revokeCredential(credentialId, "Fraud detected");

        CredentialMetadata.Credential memory cred = credential.getCredential(credentialId);
        assertTrue(cred.isRevoked);
        assertFalse(credential.isCredentialValid(credentialId));
    }

    function testRevokeCredentialRevertsAlreadyRevoked() public {
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
        credential.revokeCredential(credentialId, "Fraud detected");

        vm.prank(signer1);
        vm.expectRevert(AcademicCredential.AcademicCredential__AlreadyRevoked.selector);
        credential.revokeCredential(credentialId, "Fraud detected");
    }

    function testRestoreCredential() public {
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
        credential.revokeCredential(credentialId, "Fraud detected");

        vm.prank(signer2);
        credential.restoreCredential(credentialId);

        CredentialMetadata.Credential memory cred = credential.getCredential(credentialId);
        assertFalse(cred.isRevoked);
        assertTrue(credential.isCredentialValid(credentialId));
    }

    function testTransferNotAllowed() public {
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

        vm.prank(student);
        vm.expectRevert(AcademicCredential.AcademicCredential__TransferNotAllowed.selector);
        credential.transferFrom(student, unauthorized, credentialId);
    }

    function testGetQRCodeData() public {
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

        string memory qrData = credential.getQRCodeData(credentialId);
        assertTrue(bytes(qrData).length > 0);
    }

    function testAutoIssueWithSingleSigner() public {
        // Create university with only 1 required signer
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        uint256 singleSignerUniId =
            registry.registerUniversity(makeAddr("singleAdmin"), "Stanford", "USA", "ipfs://metadata", signers, 1);

        // Should auto-issue with first signature
        vm.prank(signer1);
        uint256 credentialId = credential.requestCredential(
            student,
            singleSignerUniId,
            CredentialMetadata.DegreeType.BACHELOR,
            "Computer Science",
            385,
            CredentialMetadata.Honors.NONE,
            block.timestamp,
            "ipfs://credential"
        );

        (,, bool issued) = credential.getApprovalStatus(credentialId);
        assertTrue(issued);
        assertEq(credential.ownerOf(credentialId), student);
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

        // Not valid yet (not enough signatures)
        assertFalse(credential.isCredentialValid(credentialId));

        vm.prank(signer2);
        credential.signCredential(credentialId);

        // Now valid
        assertTrue(credential.isCredentialValid(credentialId));
    }

    function testHasSigned() public {
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

        assertTrue(credential.hasSigned(credentialId, signer1));
        assertFalse(credential.hasSigned(credentialId, signer2));

        vm.prank(signer2);
        credential.signCredential(credentialId);

        assertTrue(credential.hasSigned(credentialId, signer2));
    }
}
