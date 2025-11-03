// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {CredentialMetadata} from "./libraries/CredentialMetadata.sol";
import {UniversityRegistry} from "./UniversityRegistry.sol";

/**
 * @title AcademicCredential
 * @notice Soulbound NFT for academic credentials
 * @dev Implements non-transferable academic diplomas with multi-signature issuance
 */
contract AcademicCredential is ERC721 {
    using CredentialMetadata for CredentialMetadata.Credential;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error AcademicCredential__TransferNotAllowed();
    error AcademicCredential__UniversityNotActive();
    error AcademicCredential__NotAuthorizedSigner();
    error AcademicCredential__AlreadySigned();
    error AcademicCredential__InsufficientSignatures();
    error AcademicCredential__InvalidStudent();
    error AcademicCredential__InvalidGPA();
    error AcademicCredential__InvalidGraduationDate();
    error AcademicCredential__InvalidMajor();
    error AcademicCredential__CredentialNotFound();
    error AcademicCredential__AlreadyRevoked();
    error AcademicCredential__NotRevoked();
    error AcademicCredential__CredentialAlreadyIssued();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CredentialRequested(uint256 indexed credentialId, address indexed student, uint256 indexed universityId);
    event CredentialSigned(uint256 indexed credentialId, address indexed signer, uint256 signatureCount);
    event CredentialIssued(
        uint256 indexed credentialId,
        address indexed student,
        uint256 indexed universityId,
        CredentialMetadata.DegreeType degreeType
    );
    event CredentialRevoked(uint256 indexed credentialId, string reason);
    event CredentialRestored(uint256 indexed credentialId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Struct for managing credential issuance approval
     */
    struct IssuanceApproval {
        mapping(address => bool) signatures;
        uint256 signatureCount;
        bool issued;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    UniversityRegistry private immutable i_universityRegistry;
    uint256 private s_credentialCounter;

    mapping(uint256 => CredentialMetadata.Credential) private s_credentials;
    mapping(uint256 => IssuanceApproval) private s_approvals;
    mapping(bytes32 => bool) private s_credentialHashes; // Prevent duplicates
    mapping(address => uint256[]) private s_studentCredentials;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address universityRegistry) ERC721("Academic Credential", "ACADEM") {
        i_universityRegistry = UniversityRegistry(universityRegistry);
        s_credentialCounter = 0;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Requests a new credential to be issued
     * @param student Address of the student
     * @param universityId ID of the issuing university
     * @param degreeType Type of degree
     * @param major Field of study
     * @param gpa Grade point average (scaled by 100)
     * @param honors Honors classification
     * @param graduationDate Date of graduation
     * @param metadataURI IPFS URI for metadata
     * @return credentialId ID of the requested credential
     */
    function requestCredential(
        address student,
        uint256 universityId,
        CredentialMetadata.DegreeType degreeType,
        string calldata major,
        uint16 gpa,
        CredentialMetadata.Honors honors,
        uint256 graduationDate,
        string calldata metadataURI
    ) external returns (uint256) {
        // Validate inputs
        if (student == address(0)) revert AcademicCredential__InvalidStudent();
        if (!i_universityRegistry.isUniversityActive(universityId)) {
            revert AcademicCredential__UniversityNotActive();
        }
        if (!i_universityRegistry.isAuthorizedSigner(universityId, msg.sender)) {
            revert AcademicCredential__NotAuthorizedSigner();
        }
        if (!CredentialMetadata.isValidGPA(gpa)) revert AcademicCredential__InvalidGPA();
        if (!CredentialMetadata.isValidGraduationDate(graduationDate)) {
            revert AcademicCredential__InvalidGraduationDate();
        }
        if (!CredentialMetadata.isValidMajor(major)) revert AcademicCredential__InvalidMajor();

        // Check for duplicate credentials
        bytes32 credentialHash = keccak256(abi.encodePacked(student, universityId, degreeType, major, graduationDate));
        if (s_credentialHashes[credentialHash]) {
            revert AcademicCredential__CredentialAlreadyIssued();
        }

        s_credentialCounter++;
        uint256 credentialId = s_credentialCounter;

        // Create credential
        s_credentials[credentialId] = CredentialMetadata.Credential({
            student: student,
            universityId: universityId,
            degreeType: degreeType,
            major: major,
            gpa: gpa,
            honors: honors,
            graduationDate: graduationDate,
            issuanceDate: block.timestamp,
            metadataURI: metadataURI,
            isRevoked: false
        });

        s_credentialHashes[credentialHash] = true;

        // First signature from requester
        s_approvals[credentialId].signatures[msg.sender] = true;
        s_approvals[credentialId].signatureCount = 1;

        emit CredentialRequested(credentialId, student, universityId);
        emit CredentialSigned(credentialId, msg.sender, 1);

        // Auto-issue if only 1 signature required
        if (i_universityRegistry.getRequiredSigners(universityId) == 1) {
            _issueCredential(credentialId);
        }

        return credentialId;
    }

    /**
     * @notice Signs a credential request
     * @param credentialId ID of the credential to sign
     */
    function signCredential(uint256 credentialId) external {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }

        CredentialMetadata.Credential storage credential = s_credentials[credentialId];
        uint256 universityId = credential.universityId;

        if (!i_universityRegistry.isAuthorizedSigner(universityId, msg.sender)) {
            revert AcademicCredential__NotAuthorizedSigner();
        }

        IssuanceApproval storage approval = s_approvals[credentialId];

        if (approval.issued) revert AcademicCredential__CredentialAlreadyIssued();
        if (approval.signatures[msg.sender]) revert AcademicCredential__AlreadySigned();

        approval.signatures[msg.sender] = true;
        approval.signatureCount++;

        emit CredentialSigned(credentialId, msg.sender, approval.signatureCount);

        // Issue if we have enough signatures
        if (approval.signatureCount >= i_universityRegistry.getRequiredSigners(universityId)) {
            _issueCredential(credentialId);
        }
    }

    /**
     * @notice Revokes a credential
     * @param credentialId ID of the credential to revoke
     * @param reason Reason for revocation
     */
    function revokeCredential(uint256 credentialId, string calldata reason) external {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }

        CredentialMetadata.Credential storage credential = s_credentials[credentialId];

        if (!i_universityRegistry.isAuthorizedSigner(credential.universityId, msg.sender)) {
            revert AcademicCredential__NotAuthorizedSigner();
        }
        if (credential.isRevoked) revert AcademicCredential__AlreadyRevoked();

        credential.isRevoked = true;

        emit CredentialRevoked(credentialId, reason);
    }

    /**
     * @notice Restores a revoked credential
     * @param credentialId ID of the credential to restore
     */
    function restoreCredential(uint256 credentialId) external {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }

        CredentialMetadata.Credential storage credential = s_credentials[credentialId];

        if (!i_universityRegistry.isAuthorizedSigner(credential.universityId, msg.sender)) {
            revert AcademicCredential__NotAuthorizedSigner();
        }
        if (!credential.isRevoked) revert AcademicCredential__NotRevoked();

        credential.isRevoked = false;

        emit CredentialRestored(credentialId);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to issue credential after approval
     * @param credentialId ID of the credential to issue
     */
    function _issueCredential(uint256 credentialId) internal {
        IssuanceApproval storage approval = s_approvals[credentialId];
        CredentialMetadata.Credential storage credential = s_credentials[credentialId];

        approval.issued = true;
        s_studentCredentials[credential.student].push(credentialId);

        _safeMint(credential.student, credentialId);

        emit CredentialIssued(credentialId, credential.student, credential.universityId, credential.degreeType);
    }

    /**
     * @dev Override transfer functions to make NFT soulbound
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0)) but not transfers
        if (from != address(0) && to != address(0)) {
            revert AcademicCredential__TransferNotAllowed();
        }

        return super._update(to, tokenId, auth);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets credential information
     * @param credentialId ID of the credential
     * @return credential Credential struct
     */
    function getCredential(uint256 credentialId) external view returns (CredentialMetadata.Credential memory) {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }
        return s_credentials[credentialId];
    }

    /**
     * @notice Gets all credentials for a student
     * @param student Address of the student
     * @return credentialIds Array of credential IDs
     */
    function getStudentCredentials(address student) external view returns (uint256[] memory) {
        return s_studentCredentials[student];
    }

    /**
     * @notice Gets credential approval status
     * @param credentialId ID of the credential
     * @return signatureCount Number of signatures received
     * @return requiredSignatures Number of signatures required
     * @return issued Whether credential has been issued
     */
    function getApprovalStatus(uint256 credentialId)
        external
        view
        returns (uint256 signatureCount, uint256 requiredSignatures, bool issued)
    {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }

        CredentialMetadata.Credential storage credential = s_credentials[credentialId];
        IssuanceApproval storage approval = s_approvals[credentialId];

        return
            (approval.signatureCount, i_universityRegistry.getRequiredSigners(credential.universityId), approval.issued);
    }

    /**
     * @notice Checks if an address has signed a credential
     * @param credentialId ID of the credential
     * @param signer Address to check
     * @return bool True if address has signed
     */
    function hasSigned(uint256 credentialId, address signer) external view returns (bool) {
        return s_approvals[credentialId].signatures[signer];
    }

    /**
     * @notice Checks if a credential is valid (issued and not revoked)
     * @param credentialId ID of the credential
     * @return bool True if credential is valid
     */
    function isCredentialValid(uint256 credentialId) external view returns (bool) {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            return false;
        }

        IssuanceApproval storage approval = s_approvals[credentialId];
        CredentialMetadata.Credential storage credential = s_credentials[credentialId];

        return approval.issued && !credential.isRevoked;
    }

    /**
     * @notice Gets total number of credentials issued
     * @return count Total credential count
     */
    function getTotalCredentials() external view returns (uint256) {
        return s_credentialCounter;
    }

    /**
     * @notice Gets the university registry address
     * @return address Address of the university registry
     */
    function getUniversityRegistry() external view returns (address) {
        return address(i_universityRegistry);
    }

    /**
     * @notice Gets formatted credential data for QR code generation
     * @param credentialId ID of the credential
     * @return qrData Formatted string for QR code
     */
    function getQRCodeData(uint256 credentialId) external view returns (string memory) {
        if (credentialId == 0 || credentialId > s_credentialCounter) {
            revert AcademicCredential__CredentialNotFound();
        }

        CredentialMetadata.Credential storage cred = s_credentials[credentialId];

        return string(
            abi.encodePacked(
                "ID:",
                _toString(credentialId),
                "|Student:",
                _toHexString(cred.student),
                "|University:",
                _toString(cred.universityId),
                "|Degree:",
                CredentialMetadata.degreeTypeToString(cred.degreeType),
                "|Major:",
                cred.major
            )
        );
    }

    /**
     * @dev Converts uint256 to string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts address to hex string
     */
    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(addr)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            buffer[2 * i + 2] = _char(hi);
            buffer[2 * i + 3] = _char(lo);
        }
        return string(buffer);
    }

    /**
     * @dev Converts byte to hex character
     */
    function _char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
