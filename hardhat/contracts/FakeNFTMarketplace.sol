// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    // maintain a mapping of Fake tokenID to Owner addresses
    mapping(uint256 => address) public tokens;

    // sets the purchase price for each fake NFT
    uint nftPrice = 0.1 ether;

    // accepts ETH and marks the owner of the given tokenID as the caller address
    // _tokenId is the fake nft token id to purchase
    function purchase(uint _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    // returns the price of one NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // chekcs whether the given tokenId has already been  sold or not
    function availbale(uint _tokenId) external view returns (bool) {
        // address(0) = 0x0000000000000000000000000000000000000000
        // This is the default value for addresses in Solidity
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}
