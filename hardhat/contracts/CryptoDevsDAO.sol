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

    // returns a tokenID at given index for owner
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        // tokenId of the nft to purchase from marketplace if the proposal passes
        uint nftTokenId;
        // UNIX timestamp until which this proposal is active
        // proposal can be executed after the deadline has been exceeded
        uint deadline;
        // number of yay votes for this proposal
        uint yayVotes;
        // number of nayVotes for this proposal
        uint nayVotes;
        // whether or not proposal has been executes
        // cannot be executed before deadline has been exceeded
        bool executed;
        // mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint => bool) voters;
    }

    // mapping of proposal ID to proposal
    mapping(uint => Proposal) public proposals;
    // number of proposals created
    uint public numProposals;

    // initialization
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    // payable here accepts an eth deposit when it is being deployed
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    // only allows functions to be called by our nft holders
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    // allows our nft holder to create new proposal
    // _nftTokenId - token of nft to be purchased from the mrketplace
    // returns proposal index for new created proposal
    function createProposal(uint _nftTokenId)
        external
        nftHolderOnly
        returns (uint)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        // set voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals - 1;
    }

    // allows function to be called if deadline not exceeded
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // possible options for a vote
    enum Vote {
        YAY, // = 0
        NAY // = 1
    }

    // allows an nft holder to cast their vote on an active proposal
    // param proposalindex - index of proposal to vote on in proposals array
    // param vote - type of vote they  want to cast
    function voteOnProposal(uint proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint numVotes = 0;

        // calculate how many nfts are owned by voter
        // that havent been used for voting on this proposal
        for (uint i = 0; i < voterNFTBalance; i++) {
            uint tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // allows function to be called if given proposals' deadline HAS been exceeded
    // and if proposal has not yet been executed
    modifier inactiveProposalOnly(uint proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    // allows nft holder to execute a proposal after its deadline has been exceeded
    // param proposalIndex - index of proposal to execute in proposals array
    function executeProposal(uint proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // if proposal has more yay votes than nay votes
        // purchase nft from marketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    // allows contract owner (deployer) to withdraw the eth from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // contract allows eth deposits directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
