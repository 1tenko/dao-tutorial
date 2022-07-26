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

contract CryptoDevsDAO is Ownable {}
