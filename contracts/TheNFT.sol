pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheNFT is ERC721, Ownable {
  using Counters for Counters.Counter;

  struct Offer {
    uint minValue;          // in ether
    bool isForSale;
  }

  struct Bid {
    address bidder;
    uint value;
  }

  Counters.Counter private _tokenIds;
  string private baseURI;

  // tokenid -> Offer
  mapping (uint => Offer) public offers;

  // tokenid -> highest bid
  mapping (uint => Bid) public bids;

  // events
  event OfferCreated(uint indexed tokenID, uint minValue);
  event OfferWithdrawed(uint indexed tokenID);
  event DealMade(uint indexed tokenID, uint value, address indexed fromAddress, address indexed toAddress);
  event BidEntered(uint indexed tokenID, uint value, address indexed fromAddress);
  event BidWithdrawed(uint indexed tokenID);

  constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
    baseURI = _baseURI;
  }

  function mint(address to) external onlyOwner { 
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();
    _safeMint(to, newTokenId);
  }

  function makeOffer(uint256 tokenId, uint256 minPrice) external {
    require(_owners[tokenId] == msg.sender, "TheNFT: not_owner");
    require(minPrice > 0, "TheNFT: not_valid_price");
    offers[tokenId] = Offer(minPrice, true);
    emit OfferCreated(tokenId, minPrice);
  }

  function acceptOffer(uint256 tokenID) external payable {
    Offer storage offer = offers[tokenID];

    require(offer.isForSale == true, 'TheNFT: non_existing_offer');
    require(msg.value >= offer.minPrice, 'TheNFT: not_enough_fund');

    payable address seller = payable(_owners[tokenId]);
    seller.transfer(msg.value);

    // remove offer
    offer = Offer(0, false);

    _transfer(seller, msg.sender, tokenID);

    emit DealMade(tokenID, msg.value, seller, msg.sender);
  }

  function withdrawOffer(uint256 tokenId) external {
    require(_owners[tokenId] == msg.sender, "TheNFT: not_owner");
    offer = Offer(0, false);
    emit OfferWithdrawed(tokenId);
  }

  function makeBid(uint256 tokenId, uint256 price) external payable{
    require(!_exists(tokenId), "TheNFT: not_exist_token");

    Bid storage oldBid = bids[tokenId];

    require(msg.value > oldBid.value, 'TheNFT: not_acceptable');

    // refund to the old bidder
    _refundBid(tokenId);

    oldBid = Bid(msg.sender, msg.value);

    emit BidEntered(tokenID, msg.value, msg.address);
  }

  function acceptBid(uint256 tokenId) external {
    require(_owners[tokenId] == msg.sender, "TheNFT: not_owner");

    Bid storage bid = bids[tokenId];
    require(bid.bidder != address(0), "TheNFT: not_exist_bid");

    _transfer(msg.sender, bid.bidder, tokenId);
    // transfer fund
    msg.sender.transfer(bid.value);

    emit DealMade(tokenID, bid.value, msg.sender, bid.bidder);

    // remove bid
    bid = Bid(address(0), 0);
  }

  function withdrawBid(uint256 tokenId) external {
    Bid storage bid = bids[tokenId];

    require(bid.bidder == msg.sender, "TheNFT: not_bidder");

    _refundBid(tokenID);

    bid = Bid(address(0), 0);

    emit BidWithdrawed(tokenId);
  }

  function _refundBid(uint256 tokenId) internal {
    Bid storage bid = bids[tokenId];
    if (bid.bidder != address(0) && bid.value > 0) {
      payable(bid.bidder).transfer(bid.value);
    }
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  receive() external payable {}
}