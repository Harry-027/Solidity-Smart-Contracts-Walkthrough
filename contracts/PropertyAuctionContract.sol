pragma solidity >=0.4.22 <0.6.0;

contract PropertyAuctionContract {

	event reg(address _from, uint _amount);
	event withdrawn(address _from, uint _amount);
	event result(address _from,address _to, uint _amount);

	struct Property {
		string name; // name of Property
		string details; // hash of property details such as property type, property area & address details
	}

	struct Status {
		uint bidders; // will store the number of participants in bidding.
		uint highestBid; // will store the highest bid.
		address payable highestBidder; // address of the highest bidder
		bool biddingCompleted; // will ensure the true status of bidding.
	}

	address payable public owner;
	Property public property;
	Status status;
	mapping(address => uint) isProspect; // storing prospect address & their advance money value in number

	constructor(string memory name, string memory details) public {
		owner = msg.sender;
		property = Property({name: name, details: details});
		status = Status({highestBid: 0, bidders: 0, highestBidder: msg.sender, biddingCompleted: false});
	}

	modifier onlyOwner {
        require(msg.sender == owner, "Only owner is authorized to perform this transaction");
        _;
    }

	modifier nonOwner {
        require(msg.sender != owner, "One who is not an owner is authorized to perform this action");
        _;
    }

	function bid() public payable  nonOwner returns (bool success) {
		require(status.biddingCompleted == false, "Bidding is over.");
		require(isProspect[msg.sender] == 0, "You have already participated in bidding.");
		uint balance = msg.value;
		isProspect[msg.sender] = balance; // setting the mapping value for bidder.
		status.bidders++; // incrementing the bidder count.
		if(balance > status.highestBid) {
			status.highestBid = balance; // setting the highest bid value.
			status.highestBidder = msg.sender; // setting the highest bidder user.
		}
		emit reg(msg.sender, balance);
		return true;
	}

	function bidResult() public onlyOwner returns (bool success) {
		uint balance = isProspect[status.highestBidder];
		address oldOwner = owner;
        // obviously should meet this condition.
		require(balance <= address(this).balance, "Contract balance is not sufficient to complete the transaction");
		owner.transfer(balance); // transferring highest bid amount to contract owner.
		owner = status.highestBidder; // transferring ownership of contract/property to the highest bidder.
		status.bidders--; // Ensuring highest bidder is no more counted under bidders list.
		isProspect[owner] = 0; // Ensuring new owner amount is now set to 0 under prospect mapping.
		status.biddingCompleted = true; // Ensuring bidding is marked as completed after result has been declared.
		emit result(oldOwner, owner, balance); // emitting event confirming bid result.
		return true;
	}

	function withdraw() public nonOwner returns (bool success) {
		if(isProspect[msg.sender] > 0) {
			uint balance = isProspect[msg.sender];
			require(balance <= address(this).balance, "Not enough balance to withdraw from contract");
			msg.sender.transfer(balance); // transferring the required amount back to user.
			isProspect[msg.sender] = 0; // resetting the bidder amount to 0.
			status.bidders--; // decrementing the bidders list.
			emit withdrawn(msg.sender, balance); // event confirming balance is withdrawn.
			return true; // returning true since balance is withdrawn.
		}
		return false; // returning false since balance cannot be withdrawn.
	}

	function restartBidding() external onlyOwner returns (bool success) {
		require(status.bidders == 0, "Bidders haven't withdrawn their ether from previous bidding yet");
		status.highestBid = 0; // resetting the highestbid amount to 0.
		status.highestBidder = owner; // setting highestBidder default to owner.
		status.biddingCompleted = false; // resetting the biddingCompleted flag to false.
		return true;
	}

	function destroy() external onlyOwner {
        require(status.bidders == 0, "Bidders haven't withdrawn their ether yet!");
        selfdestruct(owner);
    }

}