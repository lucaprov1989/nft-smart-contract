type Network = "development" | "rinkeby" | "mainnet";

module.exports = (artifacts: Truffle.Artifacts, web3: Web3) => {
  return async (
    deployer: Truffle.Deployer,
    network: Network,
    accounts: string[]
  ) => {
    const contract = artifacts.require("NFT");
    const contractLib = artifacts.require("NFTLib");
    await deployer.deploy(contractLib);
    await deployer.link(contractLib, contract);
    await deployer.deploy(contract, "deck");

    const hashGames = await contract.deployed();
    console.log(
      `HashGames deployed at ${hashGames.address} in network: ${network}.`
    );
  };
};
