// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    // returns the price in Wei of and nft from FakeNFTMarketplace
    function getPrice() external view returns (uint);

    // returns whether or not given tokenID has already been purchsed
    function available(uint256 _tokenId) external view returns (bool);

    // purchases nft of tokenID from marketplace
    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    // returns number of nfts owned by a single address
    // param 'owner' - address to fetch number of nfts for
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {}
