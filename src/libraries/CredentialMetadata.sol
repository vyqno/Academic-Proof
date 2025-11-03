// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title CredentialMetadata
 * @notice Library for managing academic credential metadata structures
 * @dev Provides data structures and helpers for credential information
 */
library CredentialMetadata {
    /**
     * @dev Enum representing different degree types
     */
    enum DegreeType {
        ASSOCIATE,
        BACHELOR,
        MASTER,
        DOCTORATE,
        CERTIFICATE,
        DIPLOMA
    }

    /**
     * @dev Enum representing honors classifications
     */
    enum Honors {
        NONE,
        CUM_LAUDE,
        MAGNA_CUM_LAUDE,
        SUMMA_CUM_LAUDE,
        WITH_DISTINCTION,
        WITH_HIGH_DISTINCTION
    }

    /**
     * @dev Struct containing all credential information
     * @param student Address of the student receiving the credential
     * @param universityId ID of the issuing university
     * @param degreeType Type of degree being awarded
     * @param major Field of study
     * @param gpa Grade point average (scaled by 100, e.g., 385 = 3.85)
     * @param honors Honors classification
     * @param graduationDate Timestamp of graduation
     * @param issuanceDate Timestamp when credential was issued
     * @param metadataURI IPFS URI for additional metadata
     * @param isRevoked Whether the credential has been revoked
     */
    struct Credential {
        address student;
        uint256 universityId;
        DegreeType degreeType;
        string major;
        uint16 gpa; // GPA * 100 (e.g., 3.85 = 385)
        Honors honors;
        uint256 graduationDate;
        uint256 issuanceDate;
        string metadataURI;
        bool isRevoked;
    }

    /**
     * @dev Validates that GPA is within acceptable range (0-4.00)
     * @param gpa The GPA value to validate (scaled by 100)
     * @return bool True if GPA is valid
     */
    function isValidGPA(uint16 gpa) internal pure returns (bool) {
        return gpa <= 400; // Max 4.00 GPA
    }

    /**
     * @dev Validates that graduation date is not in the future
     * @param graduationDate The graduation date timestamp
     * @return bool True if date is valid
     */
    function isValidGraduationDate(uint256 graduationDate) internal view returns (bool) {
        return graduationDate <= block.timestamp;
    }

    /**
     * @dev Validates that major string is not empty
     * @param major The major field to validate
     * @return bool True if major is valid
     */
    function isValidMajor(string memory major) internal pure returns (bool) {
        return bytes(major).length > 0 && bytes(major).length <= 100;
    }

    /**
     * @dev Converts degree type to string representation
     * @param degreeType The degree type enum
     * @return string String representation of the degree type
     */
    function degreeTypeToString(DegreeType degreeType) internal pure returns (string memory) {
        if (degreeType == DegreeType.ASSOCIATE) return "Associate";
        if (degreeType == DegreeType.BACHELOR) return "Bachelor";
        if (degreeType == DegreeType.MASTER) return "Master";
        if (degreeType == DegreeType.DOCTORATE) return "Doctorate";
        if (degreeType == DegreeType.CERTIFICATE) return "Certificate";
        if (degreeType == DegreeType.DIPLOMA) return "Diploma";
        return "Unknown";
    }

    /**
     * @dev Converts honors to string representation
     * @param honors The honors enum
     * @return string String representation of the honors
     */
    function honorsToString(Honors honors) internal pure returns (string memory) {
        if (honors == Honors.NONE) return "None";
        if (honors == Honors.CUM_LAUDE) return "Cum Laude";
        if (honors == Honors.MAGNA_CUM_LAUDE) return "Magna Cum Laude";
        if (honors == Honors.SUMMA_CUM_LAUDE) return "Summa Cum Laude";
        if (honors == Honors.WITH_DISTINCTION) return "With Distinction";
        if (honors == Honors.WITH_HIGH_DISTINCTION) return "With High Distinction";
        return "Unknown";
    }
}
