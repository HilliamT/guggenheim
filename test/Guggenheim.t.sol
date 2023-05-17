// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {Guggenheim} from "../src/Guggenheim.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import { IERC721 } from "forge-std/interfaces/IERC721.sol"; 

contract SimpleMockNFT is ERC721 {
    constructor() ERC721("Mock", "MOCK") {}

    function mint(uint256 id) public {
        _mint(msg.sender, id);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}

contract MaliciousReentrantActor {

    Guggenheim _guggenheim;
    Guggenheim.DutchAuctionConfig _config;
    Guggenheim.Signature _userSignature;
    Guggenheim.Signature _serverSignature;

    constructor(Guggenheim guggenheim, Guggenheim.DutchAuctionConfig memory config, Guggenheim.Signature memory userSignature, Guggenheim.Signature memory serverSignature) {
        _guggenheim = guggenheim;
        _config = config;
        _userSignature = userSignature;
        _serverSignature = serverSignature;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public returns (bytes4) {
        _guggenheim.settleDutchAuction(_config, _userSignature, _serverSignature);
        return 0x150b7a02;
    }

    // Reentrant fallback
    fallback() external {
        _guggenheim.settleDutchAuction(_config, _userSignature, _serverSignature);
    }
}

contract MaliciousDOSActor {

    Guggenheim _guggenheim;
    Guggenheim.DutchAuctionConfig _config;
    Guggenheim.Signature _signature;
    bool _failOnFallback;

    constructor(Guggenheim guggenheim, Guggenheim.DutchAuctionConfig memory config, Guggenheim.Signature memory signature, bool failOnFallback) {
        _guggenheim = guggenheim;
        _config = config;
        _signature = signature;
        _failOnFallback = failOnFallback;
    }
    
    // On ERC721 received
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public returns (bytes4) {
        assert(!_failOnFallback);
        return 0x150b7a02;
    }

    // Reentrant fallback
    fallback() external {
        assert(!_failOnFallback);
    }
}

contract GuggenheimTest is Test {

    Guggenheim guggenheim;

    // Actors
    uint256 REAL_SELLER_PRIVATE_KEY = 1;
    address REAL_SELLER = vm.addr(REAL_SELLER_PRIVATE_KEY);

    uint256 REAL_SERVER_PRIVATE_KEY = 2;

    address REAL_BUYER = address(0x1);
    
    SimpleMockNFT SIMPLE_MOCK_NFT;

    function setUp() public {
        vm.startPrank(vm.addr(REAL_SERVER_PRIVATE_KEY));
        guggenheim = new Guggenheim();
        vm.stopPrank();
        vm.deal(REAL_BUYER, 10 ether);

        SIMPLE_MOCK_NFT = new SimpleMockNFT();
    }

    function testSettleDutchAuction_fail_badServerPrivateKey() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(0x0),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number - 1,
            endBlock: block.number - 1,
            blockDecayRate: 0
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(42069, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.expectRevert("Signature is not signed by contract deployer");

        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_usingOldSignature() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(0x0),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number - 1,
            endBlock: block.number - 1,
            blockDecayRate: 0
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number - 1
        }))));

        vm.expectRevert("Signature is not signed by contract deployer");

        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedDutchAuctionExpired() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(0x0),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number - 1,
            endBlock: block.number - 1,
            blockDecayRate: 0
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.expectRevert("Dutch auction has expired");

        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedCurrentPriceUnderflow() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(0x0),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number - 1,
            endBlock: block.number + 1,
            blockDecayRate: 12
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));


        vm.expectRevert();
        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedMessageValueTooLittle() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(0x0),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.expectRevert("Buyer hasn't paid enough");
        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedTokenIdDoesntExist() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(SIMPLE_MOCK_NFT),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });



        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.startPrank(REAL_BUYER);
        vm.expectRevert("WRONG_FROM");
        guggenheim.settleDutchAuction{value: 10 ether}(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedSellerDoesntOwnNFT() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(SIMPLE_MOCK_NFT),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        SIMPLE_MOCK_NFT.mint(1);

        vm.startPrank(REAL_BUYER);
        vm.expectRevert("WRONG_FROM");
        guggenheim.settleDutchAuction{value: 10 ether}(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedNFTTransferCallbackReentrancy() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(SIMPLE_MOCK_NFT),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        SIMPLE_MOCK_NFT.mint(1);

        vm.startPrank(REAL_BUYER);
        vm.expectRevert("WRONG_FROM");
        guggenheim.settleDutchAuction{value: 10 ether}(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_fail_unverifiedNFTTransferCallbackDOS() public {
        // TODO: 
    }

    function testSettleDutchAuction_fail_unverifiedSCWCallCallbackReentrancy() public {
        // TODO: 
    }

    /// @dev We expect to fail on a callback DOS on purpose, relying on off-chain verification and
    ///      removal of signature.
    function testSettleDutchAuction_fail_unverifiedSCWCallCallbackDOS() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(SIMPLE_MOCK_NFT),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.startPrank(REAL_SELLER);
        SIMPLE_MOCK_NFT.mint(1);
        SIMPLE_MOCK_NFT.approve(address(guggenheim), 1);
        vm.stopPrank();

        uint256 buyerBalanceBefore = REAL_BUYER.balance;
        uint256 sellerBalanceBefore = REAL_SELLER.balance;

        vm.etch(REAL_SELLER, type(MaliciousDOSActor).creationCode);

        vm.startPrank(REAL_BUYER);
        vm.expectRevert("Failed to send Ether");
        guggenheim.settleDutchAuction{value: 1 ether}(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();
    }

    function testSettleDutchAuction_success_simple() public {
        Guggenheim.DutchAuctionConfig memory config = Guggenheim.DutchAuctionConfig({
            addressOfNft: address(SIMPLE_MOCK_NFT),
            tokenIdOfNft: 1,
            initialPrice: 10,
            startBlock: block.number,
            endBlock: block.number + 1,
            blockDecayRate: 1
        });

        bytes32 dataToSign = keccak256(abi.encode(config));
        (uint8 userV, bytes32 userR, bytes32 userS) = vm.sign(REAL_SELLER_PRIVATE_KEY, dataToSign);
        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(REAL_SERVER_PRIVATE_KEY, keccak256(abi.encode(Guggenheim.ServerSignedMessage({
            v: userV,
            r: userR,
            s: userS,
            blockNumber: block.number
        }))));

        vm.startPrank(REAL_SELLER);
        SIMPLE_MOCK_NFT.mint(1);
        SIMPLE_MOCK_NFT.approve(address(guggenheim), 1);
        vm.stopPrank();

        uint256 buyerBalanceBefore = REAL_BUYER.balance;
        uint256 sellerBalanceBefore = REAL_SELLER.balance;

        vm.startPrank(REAL_BUYER);
        guggenheim.settleDutchAuction{value: 1 ether}(config, Guggenheim.Signature({ v: userV, r: userR, s: userS }), Guggenheim.Signature({ v: serverV, r: serverR, s: serverS}));
        vm.stopPrank();

        assertTrue(buyerBalanceBefore > REAL_BUYER.balance);
        assertTrue(sellerBalanceBefore < REAL_SELLER.balance);
    }
}