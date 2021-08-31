pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheNFT is ERC721, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  string private baseURI;

  constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
    baseURI = _baseURI;
  }

  function mint(address to) public onlyOwner { 
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();
    _safeMint(to, newTokenId);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
      return baseURI;
  }
}