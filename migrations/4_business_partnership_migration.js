const BusinessPartnership = artifacts.require("BusinessPartnershipContract");

module.exports = function(deployer) {
  deployer.deploy(BusinessPartnership, "Partner one account", "Partner two account");
};
