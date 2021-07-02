const LotteryNFT = artifacts.require('LotteryNFT');
const Lottery = artifacts.require('Lottery');
const IndexKeyGenerator = artifacts.require('IndexKeyGenerator');

// module.exports = function(deployer) {
//   deployer.deploy(IndexKeyGenerator);
//   deployer.deploy(LotteryNFT).then(function() {
//     console.log(LotteryNFT.address);
//     deployer.link(IndexKeyGenerator, Lottery);
//     return deployer.deploy(
//       Lottery,
//       '0xADA2270B0CB5b6254d3d48A6fEE55b72693B746A',
//       LotteryNFT.address,
//       '1000000000000000000',
//       14,
//       '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06',
//       '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06'
//     );
//   });
// };

module.exports = function(deployer) {
  deployer.deploy(IndexKeyGenerator);
  deployer.deploy(LotteryNFT).then(function() {
    console.log(LotteryNFT.address);
    deployer.link(IndexKeyGenerator, Lottery);
    return deployer.deploy(
      Lottery,
      '0x9eAB0a93b0cd5d904493694F041BdCedb97b88C6',
      LotteryNFT.address,
      '1000000000000000000',
      14,
      '0xD2B904b1cbA5436FE504Da9afB721AD41BE251b7',
      '0xD2B904b1cbA5436FE504Da9afB721AD41BE251b7'
    );
  });
};
