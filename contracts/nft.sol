// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import {NFTLib} from "./nftLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract NFT is ERC721, Ownable {
  // Deck 1 => card 1 => HashCard(suit,number)
  mapping(uint256 => mapping(uint256 => NFTLib.Card))
    public hashDeckHistory;
  // token => card
  mapping(uint256 => NFTLib.Card) public hashDeck;
  string private cardIdentifier;

  // Owned or not per deck 1 => "0-0" => true
  mapping(uint256 => mapping(string => bool)) private ownedCards;
  // Is seed already used (seed => true / false)
  mapping(uint256 => bool) internal isSeedUsed;
  // Current card number being processed
  uint256 public currentCard = 0;

  // Current deck number being processed
  uint256 public currentDeck = 1;
  // Max possible cards for deck
  uint256 private constant MAX_DECK_CARDS = 52;
  // ownerAddress => array of tokendIds
  mapping(address => uint256[]) internal ownerToIds;
  // tokenId => address
  mapping(uint256 => address) internal idToOwner;
  // the token id representing the card
  uint256 public tokenId = 0;
  // Id => Deck Description
  mapping(uint256 => string) public deckDescription;
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; //defualt interface that identifes this contract as ERC721
  // Optional mapping for token URIs
  mapping(uint256 => string) public _tokenURIs;
  string private _baseURIextended;

  constructor(
    string memory firstDeckName
  ) ERC721("NFT", "NFT") {
    supportsInterface(_INTERFACE_ID_ERC721);
    _baseURIextended = "";
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function _setTokenURI(uint256 tId, string memory _tUri) internal virtual {
    require(_exists(tId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tUri;
  }

  using Strings for uint256;

  function tokenURI(uint256 tId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tId), "ERC721Metadata: TokenId non existant");

    string memory tURI = _tokenURIs[tId];
    string memory base = _baseURI();
    return string(abi.encodePacked(base, tURI));
  }

  /**
   * @dev Withdraw funds from contract balance to address
   */
  function withdraw(address payable addressTo) external onlyOwner() {
    addressTo.transfer(address(this).balance);
  }

  /**
   * @dev Returns contract balance
   */
  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev Returns total available cards
   */
  function getAvailableCardsLength()
    external
    view
    returns (uint256 availableCardsLength)
  {
    return MAX_DECK_CARDS - currentCard;
  }

  /**
   * @dev Returns current deck
   */
  function getCurrentDeck() external view returns (uint256 deck) {
    return currentDeck;
  }

  /**
   * @dev When there are no more cards to mint, process next deck.
   */
  function nextHashDeck() external onlyOwner() {
    require(currentCard == MAX_DECK_CARDS, "ERC721: Max cards not reached");
    currentCard = 0;
    currentDeck++;
  }

  modifier validateSeed(uint256 seed) {
    require(!isSeedUsed[seed], "ERC721: Seed cannot be used.");
    _;
  }

  modifier validatePrice() {
    require(
      msg.value >= getCurrentPrice(currentDeck),
      "ERC721: insufficent BNB."
    );
    _;
  }

  modifier assureCardsAreAvailable() {
    require(
      currentCard < MAX_DECK_CARDS,
      "ERC721: No cards available, reset deck."
    );
    _;
  }

  function tokensOfOwner(address ownerAddress)
    public
    view
    returns (uint256[] memory)
  {
    return ownerToIds[ownerAddress];
  }

  /**
   * @dev Returns total owned cards by caller
   */
  function getOwnedCardsLength(address ownerAddress)
    external
    view
    returns (uint256 ownedCardsLength)
  {
    return ownerToIds[ownerAddress].length;
  }

  /**
   * @dev Returns tokenId from address and index
   */
  function getOwnedCardAtIndex(address ownerAddress, uint256 index)
    external
    view
    returns (uint256)
  {
    return ownerToIds[ownerAddress][index];
  }

  /**
   * @dev Picks a random card, set it as owned and adds it to the HashDeck
   */
  function pickCard(address to, uint256 seed)
    external
    payable
    // 0. Check if the seed is already used to avoid create the same card
    validateSeed(seed)
    // require that amount sent matches current price.
    validatePrice()
    // assure there still are cards in the deck available
    assureCardsAreAvailable()
    returns (uint256)
  {
    // 1. generate unique identifier
    uint256 rand =
      uint256(
        keccak256(
          abi.encodePacked(seed, block.timestamp, msg.sender, currentCard)
        )
      );
    // 2. pick up a free card
    NFTLib.Card memory cardPickedUp = _generateUniqueRandomCard(rand);
    // 3. safe mint
    _safeMint(to, tokenId);
    // 4. Mark it as owned
    _markCardAsTaken(cardPickedUp, seed);
    // 5. Register tokenid to Address
    _registerToken(to, tokenId);
    return tokenId;
  }

  function _registerToken(address to, uint256 token) internal {
    // 1. mapping Address to tokenIds in order to retrieve tokenId from address and tokenId
    ownerToIds[to].push(token);
    // 2. Set tokenId => address
    idToOwner[tokenId] = to;
    string memory deckName = deckDescription[currentDeck];
    // 3. Set token uri
    _setTokenURI(
      token,
      string(abi.encodePacked(deckName, "/", cardIdentifier, ".png"))
    );
    // 4. increment tokenId
    tokenId++;
    // 5. Increment current card to keep track of how many cards are generated
    currentCard++;
  }

  /**
   * @dev Given a deckNumber and a cardNumber it returns the card minted
   */
  function getHistoryOfDeck(uint256 deckNumber, uint256 cardNumber)
    external
    view
    returns (NFTLib.Card memory)
  {
    return hashDeckHistory[deckNumber][cardNumber];
  }

  function _markCardAsTaken(NFTLib.Card memory card, uint256 seed)
    internal
  {
    // 1. set owned to true
    ownedCards[currentDeck][cardIdentifier] = true;
    // 2. Set seed used to true
    isSeedUsed[seed] = true;
    // Deck 1 => Card 1 => Card Details
    hashDeckHistory[currentDeck][currentCard] = card;
    // tokenId => card
    hashDeck[tokenId] = card;
  }

  /**
   * @dev Function to returns current price listed in gwei in BNB 0.2,0.4,0.6,0.8,1.5 with scale of number of tokens
   */
  function getCurrentPrice(uint256 deck) public pure returns (uint256) {
    uint256 price;
    if (deck == 1) {
      price = 0.2 ether;
    } else if (deck == 2 || deck == 3) {
       price = 0.4 ether;
    } else if (deck == 4 || deck == 5) {
      price = 0.6 ether;
    } else if (deck == 6 || deck == 7) {
      price = 0.8 ether;
    } else {
     price = 1.5 ether;
    }
    return price;
  }

  function _generateUniqueRandomCard(uint256 rand)
    internal
    returns (NFTLib.Card memory)
  {
    NFTLib.Suits s = NFTLib.generateSuit(rand);
    NFTLib.Numbers n = NFTLib.generateNumber(rand);
    cardIdentifier = string(
      abi.encodePacked((uint256(s)).toString(), "-", (uint256(n)).toString())
    );
    bool isDuplicatedCard = ownedCards[currentDeck][cardIdentifier];
    if (isDuplicatedCard == false) {
      return (NFTLib.Card(n, s));
    } else {
      uint256 newRand = uint256(keccak256(abi.encodePacked(rand)));
      return _generateUniqueRandomCard(newRand);
    }
  }
}