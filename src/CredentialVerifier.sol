// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AcademicCredential} from "./AcademicCredential.sol";
import {UniversityRegistry} from "./UniversityRegistry.sol";
import {CredentialMetadata} from "./libraries/CredentialMetadata.sol";

/**
 * @title CredentialVerifier
 * @notice Helper contract for verifying academic credentials
 * @dev Provides optimized verification interfaces and batch operations
 */
contract CredentialVerifier {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CredentialVerifier__InvalidCredentialContract();
    error CredentialVerifier__InvalidRegistryContract();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredentialVerified(uint256 indexed credentialId, address indexed verifier, bool isValid);
    event BatchVerificationCompleted(uint256 credentialCount, address indexed verifier);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Struct containing verification result
     */
    struct VerificationResult {
        bool exists;
        bool isIssued;
        bool isRevoked;
        bool isValid;
        address student;
        uint256 universityId;
        string universityName;
        CredentialMetadata.DegreeType degreeType;
        string major;
        uint16 gpa;
        CredentialMetadata.Honors honors;
        uint256 graduationDate;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    AcademicCredential private immutable i_credentialContract;
    UniversityRegistry private immutable i_universityRegistry;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address credentialContract, address universityRegistry) {
        if (credentialContract == address(0)) {
            revert CredentialVerifier__InvalidCredentialContract();
        }
        if (universityRegistry == address(0)) {
            revert CredentialVerifier__InvalidRegistryContract();
        }

        i_credentialContract = AcademicCredential(credentialContract);
        i_universityRegistry = UniversityRegistry(universityRegistry);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies a single credential
     * @param credentialId ID of the credential to verify
     * @return result Verification result struct
     */
    function verifyCredential(uint256 credentialId) external returns (VerificationResult memory result) {
        result = _verifyCredential(credentialId);

        emit CredentialVerified(credentialId, msg.sender, result.isValid);

        return result;
    }

    /**
     * @notice Verifies multiple credentials in batch
     * @param credentialIds Array of credential IDs to verify
     * @return results Array of verification results
     */
    function batchVerifyCredentials(uint256[] calldata credentialIds)
        external
        returns (VerificationResult[] memory results)
    {
        results = new VerificationResult[](credentialIds.length);

        for (uint256 i = 0; i < credentialIds.length; i++) {
            results[i] = _verifyCredential(credentialIds[i]);
        }

        emit BatchVerificationCompleted(credentialIds.length, msg.sender);

        return results;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Quick check if credential is valid
     * @param credentialId ID of the credential
     * @return bool True if credential is valid
     */
    function isCredentialValid(uint256 credentialId) external view returns (bool) {
        return i_credentialContract.isCredentialValid(credentialId);
    }

    /**
     * @notice Gets detailed credential information
     * @param credentialId ID of the credential
     * @return result Verification result with full details
     */
    function getCredentialDetails(uint256 credentialId) external view returns (VerificationResult memory result) {
        return _verifyCredential(credentialId);
    }

    /**
     * @notice Verifies all credentials for a student
     * @param student Address of the student
     * @return results Array of verification results
     */
    function verifyStudentCredentials(address student) external view returns (VerificationResult[] memory results) {
        uint256[] memory credentialIds = i_credentialContract.getStudentCredentials(student);
        results = new VerificationResult[](credentialIds.length);

        for (uint256 i = 0; i < credentialIds.length; i++) {
            results[i] = _verifyCredential(credentialIds[i]);
        }

        return results;
    }

    /**
     * @notice Gets verification summary for display
     * @param credentialId ID of the credential
     * @return summary Human-readable verification summary
     */
    function getVerificationSummary(uint256 credentialId) external view returns (string memory) {
        VerificationResult memory result = _verifyCredential(credentialId);

        if (!result.exists) {
            return "INVALID: Credential does not exist";
        }

        if (!result.isIssued) {
            return "PENDING: Credential is awaiting approval";
        }

        if (result.isRevoked) {
            return "REVOKED: Credential has been revoked";
        }

        return string(
            abi.encodePacked(
                "VALID: ",
                CredentialMetadata.degreeTypeToString(result.degreeType),
                " in ",
                result.major,
                " from ",
                result.universityName
            )
        );
    }

    /**
     * @notice Checks if a student has a specific degree
     * @param student Address of the student
     * @param degreeType Type of degree to check
     * @param major Major to check (empty string to check any major)
     * @return bool True if student has the degree
     */
    function hasValidDegree(address student, CredentialMetadata.DegreeType degreeType, string calldata major)
        external
        view
        returns (bool)
    {
        uint256[] memory credentialIds = i_credentialContract.getStudentCredentials(student);

        bool checkMajor = bytes(major).length > 0;

        for (uint256 i = 0; i < credentialIds.length; i++) {
            try i_credentialContract.getCredential(credentialIds[i]) returns (CredentialMetadata.Credential memory cred)
            {
                if (
                    !cred.isRevoked && cred.degreeType == degreeType
                        && (!checkMajor || keccak256(bytes(cred.major)) == keccak256(bytes(major)))
                ) {
                    return true;
                }
            } catch {
                continue;
            }
        }

        return false;
    }

    /**
     * @notice Gets contract addresses
     * @return credentialContract Address of credential contract
     * @return universityRegistry Address of university registry
     */
    function getContracts() external view returns (address credentialContract, address universityRegistry) {
        return (address(i_credentialContract), address(i_universityRegistry));
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to verify a credential
     * @param credentialId ID of the credential
     * @return result Verification result
     */
    function _verifyCredential(uint256 credentialId) internal view returns (VerificationResult memory result) {
        // Check if credential exists
        uint256 totalCredentials = i_credentialContract.getTotalCredentials();
        if (credentialId == 0 || credentialId > totalCredentials) {
            return result; // Returns struct with exists = false
        }

        result.exists = true;

        // Get credential data
        try i_credentialContract.getCredential(credentialId) returns (CredentialMetadata.Credential memory cred) {
            result.student = cred.student;
            result.universityId = cred.universityId;
            result.degreeType = cred.degreeType;
            result.major = cred.major;
            result.gpa = cred.gpa;
            result.honors = cred.honors;
            result.graduationDate = cred.graduationDate;
            result.isRevoked = cred.isRevoked;

            // Get issuance status
            (,, bool issued) = i_credentialContract.getApprovalStatus(credentialId);
            result.isIssued = issued;

            // Get university name
            try i_universityRegistry.getUniversity(cred.universityId) returns (UniversityRegistry.University memory uni)
            {
                result.universityName = uni.name;
            } catch {
                result.universityName = "Unknown University";
            }

            // Determine validity
            result.isValid = result.isIssued && !result.isRevoked;
        } catch {
            result.exists = false;
        }

        return result;
    }
}
