const LotteryNFT = artifacts.require('LotteryNFT');
const Lottery = artifacts.require('Lottery');

module.exports = function(deployer) {
  deployer.deploy(LotteryNFT).then(function() {
    console.log(LotteryNFT.address);
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
