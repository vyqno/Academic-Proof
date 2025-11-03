// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {UniversityRegistry} from "../../src/UniversityRegistry.sol";

contract UniversityRegistryTest is Test {
    UniversityRegistry public registry;

    address public owner;
    address public uniAdmin;
    address public signer1;
    address public signer2;
    address public signer3;
    address public unauthorized;

    event UniversityRegistered(uint256 indexed universityId, address indexed admin, string name);
    event UniversityDeactivated(uint256 indexed universityId);
    event UniversityReactivated(uint256 indexed universityId);
    event SignerAdded(uint256 indexed universityId, address indexed signer);
    event SignerRemoved(uint256 indexed universityId, address indexed signer);
    event RequiredSignersUpdated(uint256 indexed universityId, uint256 requiredSigners);

    function setUp() public {
        owner = makeAddr("owner");
        uniAdmin = makeAddr("uniAdmin");
        signer1 = makeAddr("signer1");
        signer2 = makeAddr("signer2");
        signer3 = makeAddr("signer3");
        unauthorized = makeAddr("unauthorized");

        vm.prank(owner);
        registry = new UniversityRegistry();
    }

    function testRegistryDeployment() public view {
        assertEq(registry.owner(), owner);
        assertEq(registry.getUniversityCount(), 0);
    }

    function testRegisterUniversity() public {
        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit UniversityRegistered(1, uniAdmin, "MIT");

        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        assertEq(universityId, 1);
        assertEq(registry.getUniversityCount(), 1);

        UniversityRegistry.University memory uni = registry.getUniversity(1);
        assertEq(uni.admin, uniAdmin);
        assertEq(uni.name, "MIT");
        assertEq(uni.country, "USA");
        assertEq(uni.isActive, true);
        assertEq(uni.requiredSigners, 2);

        assertTrue(registry.isAuthorizedSigner(1, signer1));
        assertTrue(registry.isAuthorizedSigner(1, signer2));
    }

    function testRegisterUniversityRevertsIfNotOwner() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(unauthorized);
        vm.expectRevert();
        registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);
    }

    function testRegisterUniversityRevertsInvalidAdmin() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__InvalidAddress.selector);
        registry.registerUniversity(address(0), "MIT", "USA", "ipfs://metadata", signers, 1);
    }

    function testRegisterUniversityRevertsInvalidName() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__InvalidName.selector);
        registry.registerUniversity(uniAdmin, "", "USA", "ipfs://metadata", signers, 1);
    }

    function testRegisterUniversityRevertsDuplicateAdmin() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.startPrank(owner);
        registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        vm.expectRevert(UniversityRegistry.UniversityRegistry__AlreadyRegistered.selector);
        registry.registerUniversity(uniAdmin, "Harvard", "USA", "ipfs://metadata", signers, 1);
        vm.stopPrank();
    }

    function testRegisterUniversityRevertsInvalidSigners() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__InvalidSigners.selector);
        registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);
    }

    function testDeactivateUniversity() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.startPrank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        vm.expectEmit(true, false, false, false);
        emit UniversityDeactivated(universityId);
        registry.deactivateUniversity(universityId);
        vm.stopPrank();

        assertFalse(registry.isUniversityActive(universityId));
    }

    function testReactivateUniversity() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.startPrank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        registry.deactivateUniversity(universityId);

        vm.expectEmit(true, false, false, false);
        emit UniversityReactivated(universityId);
        registry.reactivateUniversity(universityId);
        vm.stopPrank();

        assertTrue(registry.isUniversityActive(universityId));
    }

    function testAddSigner() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        vm.prank(uniAdmin);
        vm.expectEmit(true, true, false, false);
        emit SignerAdded(universityId, signer2);
        registry.addSigner(universityId, signer2);

        assertTrue(registry.isAuthorizedSigner(universityId, signer2));

        address[] memory allSigners = registry.getSigners(universityId);
        assertEq(allSigners.length, 2);
    }

    function testAddSignerRevertsIfNotAdmin() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        vm.prank(unauthorized);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__NotAuthorized.selector);
        registry.addSigner(universityId, signer2);
    }

    function testAddSignerRevertsDuplicate() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        vm.prank(uniAdmin);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__SignerAlreadyExists.selector);
        registry.addSigner(universityId, signer1);
    }

    function testRemoveSigner() public {
        address[] memory signers = new address[](3);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        vm.prank(uniAdmin);
        vm.expectEmit(true, true, false, false);
        emit SignerRemoved(universityId, signer3);
        registry.removeSigner(universityId, signer3);

        assertFalse(registry.isAuthorizedSigner(universityId, signer3));

        address[] memory allSigners = registry.getSigners(universityId);
        assertEq(allSigners.length, 2);
    }

    function testRemoveSignerRevertsInsufficientSigners() public {
        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        vm.prank(uniAdmin);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__InsufficientSigners.selector);
        registry.removeSigner(universityId, signer1);
    }

    function testUpdateRequiredSigners() public {
        address[] memory signers = new address[](3);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        vm.prank(uniAdmin);
        vm.expectEmit(true, false, false, true);
        emit RequiredSignersUpdated(universityId, 3);
        registry.updateRequiredSigners(universityId, 3);

        assertEq(registry.getRequiredSigners(universityId), 3);
    }

    function testUpdateRequiredSignersRevertsInvalid() public {
        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 2);

        vm.prank(uniAdmin);
        vm.expectRevert(UniversityRegistry.UniversityRegistry__InvalidSigners.selector);
        registry.updateRequiredSigners(universityId, 3);
    }

    function testGetUniversityByAdmin() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.prank(owner);
        uint256 universityId = registry.registerUniversity(uniAdmin, "MIT", "USA", "ipfs://metadata", signers, 1);

        assertEq(registry.getUniversityByAdmin(uniAdmin), universityId);
    }

    function testMultipleUniversities() public {
        address[] memory signers = new address[](1);
        signers[0] = signer1;

        vm.startPrank(owner);
        uint256 id1 = registry.registerUniversity(makeAddr("admin1"), "MIT", "USA", "ipfs://metadata1", signers, 1);
        uint256 id2 = registry.registerUniversity(makeAddr("admin2"), "Harvard", "USA", "ipfs://metadata2", signers, 1);
        vm.stopPrank();

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(registry.getUniversityCount(), 2);

        UniversityRegistry.University memory uni1 = registry.getUniversity(1);
        UniversityRegistry.University memory uni2 = registry.getUniversity(2);

        assertEq(uni1.name, "MIT");
        assertEq(uni2.name, "Harvard");
    }
}
