// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library NFTLib {
  uint256 private constant SUITS_COUNT = 4;
  uint256 private constant NUMBERS_COUNT = 13;

  enum Numbers {
    Ace,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King
  }

  enum Suits {Spades, Diamonds, Hearts, Clubs}

  struct Card {
    Numbers number;
    Suits suit;
  }

  function generateNumber(uint256 rand) public pure returns (Numbers) {
    uint256 numberid = rand % NUMBERS_COUNT;
    Numbers number = Numbers(numberid);
    return number;
  }

  function generateSuit(uint256 rand) public pure returns (Suits) {
    uint256 suitsId = rand % SUITS_COUNT;
    Suits randomSuit = Suits(suitsId);
    return randomSuit;
  }

}
