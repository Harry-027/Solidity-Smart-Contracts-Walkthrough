const Rental = artifacts.require("PropertyRentalContract");

module.exports = function(deployer) {
  deployer.deploy(Rental, "Villa", "Nagar", 30, 500, 3);
};
