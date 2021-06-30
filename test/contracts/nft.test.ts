import { NFTInstance, NFTLibInstance } from "types/truffle-contracts";
import web3 from "web3";
import _ from "lodash";
const NFT = artifacts.require("NFT");
const NFTLib = artifacts.require("NFTLib");

contract("NFT", function(accounts) {
  console.log("lets go!");
  let contractInstance: NFTInstance;
  let libInstance: NFTLibInstance;
  const currentAddresss = accounts[0];
  let web3Ins = new web3("ws://localhost:8545");
  let CURRENT_PRICE = 0;
  let currentDeck: BN;
  const deckMapPrice: { [key: number]: number } = {
    1: 200000000,
    2: 400000000,
    3: 400000000,
  };

  before(async () => {
    contractInstance = await NFT.deployed();
    libInstance = await NFTLib.deployed();
    console.log("lets go!");
  });

  beforeEach(async () => {
    currentDeck = await contractInstance.getCurrentDeck();
    const currentCard = await contractInstance.currentCard();
    if (Number(currentCard) === 52) {
      await contractInstance.nextHashDeck();
    }
    CURRENT_PRICE = deckMapPrice[Number(currentDeck)];
  });
  it("PickCard should increment the cards owner length", async () => {
    const ownedCardsLengthBefore = await contractInstance.getOwnedCardsLength(
      currentAddresss
    );
    await contractInstance.pickCard.sendTransaction(
      currentAddresss,
      new Date().getTime(),
      {
        from: currentAddresss,
        value: web3.utils.toBN(200000000),
      }
    );
    const ownedCardsLengthAfter = await contractInstance.getOwnedCardsLength(
      currentAddresss
    );
    assert.equal(
      Number(ownedCardsLengthBefore) < Number(ownedCardsLengthAfter),
      true
    );
  });
  it("Pick card should throw error if same seed is used twice", async () => {
    try {
      await contractInstance.pickCard.call(currentAddresss, 1234567, {
        from: currentAddresss,
        value: web3.utils.toBN(CURRENT_PRICE),
      });
      await contractInstance.pickCard.call(currentAddresss, 1234567, {
        from: currentAddresss,
        value: web3.utils.toBN(CURRENT_PRICE),
      });
    } catch (err) {
      assert.equal(
        err.message,
        "Returned error: VM Exception while processing transaction: revert ERC721: seed already used"
      );
    }
  });
  it("PickCard cannot pick more than 52 cards", async () => {
    let error;

    try {
      for (let i = 0; i < 55; i++) {
        const price = await contractInstance.getCurrentPrice(currentDeck);
        await contractInstance.pickCard.sendTransaction(
          currentAddresss,
          new Date().getTime(),
          {
            from: currentAddresss,
            value: price,
          }
        );
      }
    } catch (err) {
      error = err;
    }

    assert.equal(error.reason, "ERC721: No cards available, reset deck.");
  });
  it("Cards should be unique", async () => {
    const uniqueCards = [];
    const ownedCardsLength = Number(
      await contractInstance.getOwnedCardsLength(currentAddresss)
    );
    for (let i = 0; i <= ownedCardsLength - 1; i++) {
      const tokenCard = await contractInstance.getOwnedCardAtIndex(
        currentAddresss,
        i
      );
      const card = await contractInstance.hashDeck(Number(tokenCard));
      const number = Number(card[0]);
      const suit = Number(card[1]);
      uniqueCards.push({
        number,
        suit,
      });
    }

    const uniqueElementsLength = _.uniqWith(uniqueCards, _.isEqual).length;
    assert.equal(52, uniqueElementsLength);
  });
  it("Should throw ERC721: Max cards not reached.", async () => {
    let error;
    try {
      await contractInstance.nextHashDeck();
      await contractInstance.nextHashDeck();
    } catch (err) {
      error = err.reason;
    }

    assert.equal(error, "ERC721: Max cards not reached");
  });
  it("PickCard if amount sent not equal to CURRENT_PRICE requested throw error", async () => {
    let error;
    try {
      await contractInstance.pickCard.sendTransaction(
        currentAddresss,
        new Date().getTime(),
        {
          from: currentAddresss,
          value: web3.utils.toBN(1122),
        }
      );
    } catch (err) {
      error = err;
    }
    assert.equal(error.reason, "ERC721: insufficent BNB.");
  });
  it("Withdraw should fill the balance in the landing contract", async () => {
    web3Ins.eth.defaultAccount = currentAddresss;
    const account = web3Ins.eth.defaultAccount as string;
    const balanceBefore = await web3Ins.eth.getBalance(account);
    await contractInstance.withdraw(account);
    const balanceAfter = await web3Ins.eth.getBalance(account);
    assert.notEqual(balanceBefore, balanceAfter);
  });
  it("Token uri should return the token uri with default base uri set", async () => {
    const price = await contractInstance.getCurrentPrice(currentDeck);
    await contractInstance.pickCard.sendTransaction(
      currentAddresss,
      new Date().getTime(),
      {
        from: currentAddresss,
        value: price,
      }
    );
    const ownedCardsLength = await contractInstance.getOwnedCardsLength(
      currentAddresss
    );
    const tokenCard = await contractInstance.getOwnedCardAtIndex(
      currentAddresss,
      Number(ownedCardsLength) - 1
    );
    const card = await contractInstance.hashDeck(Number(tokenCard));
    const number = Number(card[0]);
    const suit = Number(card[1]);

    const tokenUrl = await contractInstance.tokenURI(Number(tokenCard));
    assert.equal(tokenUrl, `/${suit}-${number}.png`);
  });
  it("GetBalance should return contract balance", async () => {
    const price = await contractInstance.getCurrentPrice(currentDeck);
    currentDeck = await contractInstance.getCurrentDeck();
    await contractInstance.pickCard.sendTransaction(
      currentAddresss,
      new Date().getTime(),
      {
        from: currentAddresss,
        value: price,
      }
    );
    const balance = await contractInstance.getContractBalance();
    assert.equal(!!Number(balance), true);
  });
});
