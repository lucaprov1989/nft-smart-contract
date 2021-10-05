type Network = "development" | "rinkeby" | "mainnet";

module.exports = (artifacts: Truffle.Artifacts, web3: Web3) => {
  return async (deployer: Truffle.Deployer, network: Network) => {
    const contract = artifacts.require("NFT");
    const contractLib = artifacts.require("NFTLib");
    await deployer.deploy(contractLib);
    await deployer.link(contractLib, contract);
    await deployer.deploy(contract, "deckName");

    const contractDeployed = await contract.deployed();
    console.log(
      `Deployed at ${contractDeployed.address} in network: ${network}.`
    );
  };
};
