// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Challenge Description
/// You can mint awesome nfts. The nft contract seems to limits the number of nft accounts can buy at a time.
/// Mint more than 30 nfts and within one transaction.
interface INft {
    function mint(uint256 numberOfNfts) external payable;

    function getNFTPrice() external returns (uint256 price);
}

contract Nft is INft, ERC721("Awesome NFT", "AWESOMENFT") {
    uint256 private constant MAX_NFT_SUPPLY = 1_000;
    uint256 private constant ONE_ETHER = 1e18;

    uint256 public totalSupply;

    address public owner;

    address public pendingOwner;

    constructor() {
        owner = msg.sender;
    }

    function mint(uint256 numberOfNfts) public payable virtual override {
        uint256 _totalSupply = totalSupply;
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(
            numberOfNfts <= 30,
            "You may not buy more than 30 NFTs at once"
        );
        require(
            _totalSupply + numberOfNfts <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );
        require(
            getNFTPrice() * numberOfNfts == msg.value,
            "Ether value sent is not correct"
        );
        for (uint256 i; i < numberOfNfts; i++) {
            uint256 tokenId = totalSupply;
            _safeMint(msg.sender, tokenId);
        }
    }

    function getNFTPrice() public pure override returns (uint256 price) {
        price = ONE_ETHER / MAX_NFT_SUPPLY;
    }

    // transfer ownership to a new address
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);

        pendingOwner = newOwner;
        payable(msg.sender).transfer(address(this).balance);
    }

    // accept the ownership transfer
    function acceptOwnership() public {
        require(msg.sender == pendingOwner);

        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        if (from == address(0)) {
            totalSupply += 1;
        } else if (to == address(0)) {
            totalSupply -= 1;
        }
    }
}

contract NftSale is Nft {
    bool public isSolved;

    function mint(uint256 numberOfNfts) public payable override {
        super.mint(numberOfNfts);
        require(balanceOf(msg.sender) > 30, "rule: mint more than 30 nfts");

        isSolved = true;
    }
}

contract NftSaleChallenge {
    NftSale public immutable token;

    constructor() {
        token = new NftSale();
    }

    function isSolved() external view returns (bool) {
        return token.isSolved();
    }
}
