// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UniversityRegistry
 * @notice Manages registration and verification of universities
 * @dev Implements multi-signature approval system for university registration
 */
contract UniversityRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error UniversityRegistry__AlreadyRegistered();
    error UniversityRegistry__NotRegistered();
    error UniversityRegistry__InvalidAddress();
    error UniversityRegistry__InvalidName();
    error UniversityRegistry__InvalidSigners();
    error UniversityRegistry__NotAuthorized();
    error UniversityRegistry__SignerAlreadyExists();
    error UniversityRegistry__SignerDoesNotExist();
    error UniversityRegistry__InsufficientSigners();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UniversityRegistered(uint256 indexed universityId, address indexed admin, string name);
    event UniversityDeactivated(uint256 indexed universityId);
    event UniversityReactivated(uint256 indexed universityId);
    event SignerAdded(uint256 indexed universityId, address indexed signer);
    event SignerRemoved(uint256 indexed universityId, address indexed signer);
    event RequiredSignersUpdated(uint256 indexed universityId, uint256 requiredSigners);
    event UniversityMetadataUpdated(uint256 indexed universityId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Struct containing university information
     * @param admin Primary administrator address
     * @param name University name
     * @param country Country where university is located
     * @param metadataURI IPFS URI for additional metadata
     * @param isActive Whether the university is currently active
     * @param requiredSigners Number of signatures required for credential issuance
     * @param registeredAt Timestamp of registration
     */
    struct University {
        address admin;
        string name;
        string country;
        string metadataURI;
        bool isActive;
        uint256 requiredSigners;
        uint256 registeredAt;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 private s_universityCounter;
    mapping(uint256 => University) private s_universities;
    mapping(address => uint256) private s_adminToUniversityId;
    mapping(uint256 => mapping(address => bool)) private s_authorizedSigners;
    mapping(uint256 => address[]) private s_signersList;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyUniversityAdmin(uint256 universityId) {
        if (s_universities[universityId].admin != msg.sender) {
            revert UniversityRegistry__NotAuthorized();
        }
        _;
    }

    modifier universityExists(uint256 universityId) {
        if (universityId == 0 || universityId > s_universityCounter) {
            revert UniversityRegistry__NotRegistered();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
        s_universityCounter = 0;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new university
     * @param admin Address of the university administrator
     * @param name Name of the university
     * @param country Country of the university
     * @param metadataURI IPFS URI for additional metadata
     * @param initialSigners Array of initial authorized signers
     * @param requiredSigners Number of signatures required for credentials
     * @return universityId The ID of the newly registered university
     */
    function registerUniversity(
        address admin,
        string calldata name,
        string calldata country,
        string calldata metadataURI,
        address[] calldata initialSigners,
        uint256 requiredSigners
    ) external onlyOwner returns (uint256) {
        if (admin == address(0)) revert UniversityRegistry__InvalidAddress();
        if (bytes(name).length == 0) revert UniversityRegistry__InvalidName();
        if (s_adminToUniversityId[admin] != 0) revert UniversityRegistry__AlreadyRegistered();
        if (initialSigners.length == 0 || requiredSigners == 0) {
            revert UniversityRegistry__InvalidSigners();
        }
        if (requiredSigners > initialSigners.length) {
            revert UniversityRegistry__InvalidSigners();
        }

        s_universityCounter++;
        uint256 universityId = s_universityCounter;

        s_universities[universityId] = University({
            admin: admin,
            name: name,
            country: country,
            metadataURI: metadataURI,
            isActive: true,
            requiredSigners: requiredSigners,
            registeredAt: block.timestamp
        });

        s_adminToUniversityId[admin] = universityId;

        // Add initial signers
        for (uint256 i = 0; i < initialSigners.length; i++) {
            if (initialSigners[i] == address(0)) revert UniversityRegistry__InvalidAddress();
            s_authorizedSigners[universityId][initialSigners[i]] = true;
            s_signersList[universityId].push(initialSigners[i]);
        }

        emit UniversityRegistered(universityId, admin, name);

        return universityId;
    }

    /**
     * @notice Deactivates a university
     * @param universityId ID of the university to deactivate
     */
    function deactivateUniversity(uint256 universityId) external onlyOwner universityExists(universityId) {
        s_universities[universityId].isActive = false;
        emit UniversityDeactivated(universityId);
    }

    /**
     * @notice Reactivates a university
     * @param universityId ID of the university to reactivate
     */
    function reactivateUniversity(uint256 universityId) external onlyOwner universityExists(universityId) {
        s_universities[universityId].isActive = true;
        emit UniversityReactivated(universityId);
    }

    /**
     * @notice Adds an authorized signer to a university
     * @param universityId ID of the university
     * @param signer Address to add as authorized signer
     */
    function addSigner(uint256 universityId, address signer)
        external
        onlyUniversityAdmin(universityId)
        universityExists(universityId)
    {
        if (signer == address(0)) revert UniversityRegistry__InvalidAddress();
        if (s_authorizedSigners[universityId][signer]) {
            revert UniversityRegistry__SignerAlreadyExists();
        }

        s_authorizedSigners[universityId][signer] = true;
        s_signersList[universityId].push(signer);

        emit SignerAdded(universityId, signer);
    }

    /**
     * @notice Removes an authorized signer from a university
     * @param universityId ID of the university
     * @param signer Address to remove as authorized signer
     */
    function removeSigner(uint256 universityId, address signer)
        external
        onlyUniversityAdmin(universityId)
        universityExists(universityId)
    {
        if (!s_authorizedSigners[universityId][signer]) {
            revert UniversityRegistry__SignerDoesNotExist();
        }

        // Ensure we maintain minimum signers
        if (s_signersList[universityId].length <= s_universities[universityId].requiredSigners) {
            revert UniversityRegistry__InsufficientSigners();
        }

        s_authorizedSigners[universityId][signer] = false;

        // Remove from signers list
        address[] storage signers = s_signersList[universityId];
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(universityId, signer);
    }

    /**
     * @notice Updates the required number of signers
     * @param universityId ID of the university
     * @param requiredSigners New number of required signers
     */
    function updateRequiredSigners(uint256 universityId, uint256 requiredSigners)
        external
        onlyUniversityAdmin(universityId)
        universityExists(universityId)
    {
        if (requiredSigners == 0 || requiredSigners > s_signersList[universityId].length) {
            revert UniversityRegistry__InvalidSigners();
        }

        s_universities[universityId].requiredSigners = requiredSigners;

        emit RequiredSignersUpdated(universityId, requiredSigners);
    }

    /**
     * @notice Updates university metadata URI
     * @param universityId ID of the university
     * @param metadataURI New metadata URI
     */
    function updateMetadata(uint256 universityId, string calldata metadataURI)
        external
        onlyUniversityAdmin(universityId)
        universityExists(universityId)
    {
        s_universities[universityId].metadataURI = metadataURI;
        emit UniversityMetadataUpdated(universityId);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a university is registered and active
     * @param universityId ID of the university
     * @return bool True if university is registered and active
     */
    function isUniversityActive(uint256 universityId) external view returns (bool) {
        return universityId > 0 && universityId <= s_universityCounter && s_universities[universityId].isActive;
    }

    /**
     * @notice Checks if an address is an authorized signer for a university
     * @param universityId ID of the university
     * @param signer Address to check
     * @return bool True if address is authorized signer
     */
    function isAuthorizedSigner(uint256 universityId, address signer) external view returns (bool) {
        return s_authorizedSigners[universityId][signer];
    }

    /**
     * @notice Gets university information
     * @param universityId ID of the university
     * @return university University struct
     */
    function getUniversity(uint256 universityId)
        external
        view
        universityExists(universityId)
        returns (University memory)
    {
        return s_universities[universityId];
    }

    /**
     * @notice Gets the university ID for an admin address
     * @param admin Admin address
     * @return universityId ID of the university
     */
    function getUniversityByAdmin(address admin) external view returns (uint256) {
        return s_adminToUniversityId[admin];
    }

    /**
     * @notice Gets all authorized signers for a university
     * @param universityId ID of the university
     * @return signers Array of authorized signer addresses
     */
    function getSigners(uint256 universityId) external view universityExists(universityId) returns (address[] memory) {
        return s_signersList[universityId];
    }

    /**
     * @notice Gets the total number of registered universities
     * @return count Total university count
     */
    function getUniversityCount() external view returns (uint256) {
        return s_universityCounter;
    }

    /**
     * @notice Gets the required number of signers for a university
     * @param universityId ID of the university
     * @return requiredSigners Number of required signers
     */
    function getRequiredSigners(uint256 universityId) external view universityExists(universityId) returns (uint256) {
        return s_universities[universityId].requiredSigners;
    }
}
