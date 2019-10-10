const Auction = artifacts.require("PropertyAuctionContract");

module.exports = function(deployer) {
  deployer.deploy(Auction, "Villa", "#3zYYuBBBPOlMNMN");
};
