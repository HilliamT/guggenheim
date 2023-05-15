// SPDX-License-Identifier: Unlicense

import { IERC721 } from "forge-std/interfaces/IERC721.sol"; 

// interface IERC721 {
//     function safeTransferFrom(address from, address to, uint256 tokenId) external;
// }

/// @title Guggenheim Contract
/// @author Hilliam Tung
/// @notice Using off-chain signatures provided by an API, we rely on this contract for settlement.
/// @dev Explain to a developer any extra details
contract Guggenheim {
    
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct DutchAuctionConfig {
        address addressOfNft;
        uint256 tokenIdOfNft;
        uint256 initialPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 blockDecayRate;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address owner;

    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                               SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    function settleDutchAuction(DutchAuctionConfig calldata config, Signature calldata signature) external payable {
        bytes32 messageHash = keccak256(abi.encode(config));
        address seller = ecrecover(messageHash, signature.v, signature.r, signature.s);

        // Check that the deadline is still valid
        require(block.number <= config.endBlock, "Dutch auction has expired");

        // Ensure that price is paid for
        uint256 currentPrice = config.initialPrice - (block.number - config.startBlock) * config.blockDecayRate;
        require(msg.value >= currentPrice, "Buyer hasn't paid enough");

        // Get nft from owner and send it to msg.sender
        IERC721(config.addressOfNft).safeTransferFrom(seller, msg.sender, config.tokenIdOfNft);

        // Send currentPrice to seller
        (bool sent, bytes memory _data) = payable(seller).call{value: currentPrice}("");
        require(sent, "Failed to send Ether");
    }

    function send(address recipient, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        (bool sent, bytes memory _data) = payable(recipient).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}