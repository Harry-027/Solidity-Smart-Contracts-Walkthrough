pragma solidity >=0.4.22 <0.6.0;

	contract BusinessPartnershipContract {

		address payable public partnerOne; // First Business partner address
		address payable public partnerTwo; // Second Business partner address
		bool public signed = false;
		bool public separated = false;

		mapping(address => bool) private hasSeparated; // mapping to track end of partnership
		mapping(address => bool) private hasSigned; // mapping to track if contract signed for partnership by both the partners

		struct Item {
			string data; // item details
			uint partnerOneShare; // percentage share of partner one
			uint partnerTwoShare; // percentage share of partner two
			bool added;
			bool removed;
			mapping (address => bool) hasApprovedAdd; // mapping to track approval of partners
			mapping (address => bool) hasApprovedRemove; // mapping to track approval of partners
		}

		Item[] public items; // array to store the item structs.
		uint[] public itemIds; // array to track the item index in items array

		event FundsAdded(uint _timestamp, address _wallet, uint _amount);
		event FundsSent(uint _timestamp, address _wallet, uint _amount);
		event SeparationApproved(uint _timestamp, address _wallet);
		event Separated(uint _timestamp);
		event InPartnership(uint _timestamp);
		event Signed(uint _timestamp, address _wallet);
		event ItemProposed(uint _timestamp,string _data, address _wallet);
		event ItemAddApproved(uint _timestamp,string _data, address _wallet);
		event ItemAdded(uint _timestamp,string _data);
		event ItemRemoved(uint _timestamp,string _data);

		constructor(address payable _partnerOne, address payable _partnerTwo) public {
			require(_partnerOne != address(0), "Partner address must not be zero!");
			require(_partnerTwo != address(0), "Partner address must not be zero!");
			require(_partnerOne != _partnerTwo, "Partner address should not be equal!");

			partnerOne = _partnerOne;
			partnerTwo = _partnerTwo;
		}

		modifier onlyPartner() {
			require(msg.sender == partnerOne || msg.sender == partnerTwo, "Only business partners are allowed to perform this transaction!");
			_;
		}

		modifier isSigned() {
			require(signed == true, "Contract has not been signed by both partners yet!");
			_;
		}

		modifier areNotSeparated() {
			require(separated == false, "Transaction cannot be done as partners are separated!");
			_;
		}

		// Before carrying out any transaction partnership agreement needs to be signed by both the partners.
		function signContract() external onlyPartner {
			require(hasSigned[msg.sender] == false, "Partner has already signed the contract!");
			hasSigned[msg.sender] = true;
			emit Signed(now, msg.sender);
			if (hasSigned[partnerOne] && hasSigned[partnerTwo]) {
				signed = true;
				emit InPartnership(now);
			}
		}

		// propose an item required to be added
		function proposeItem(string calldata  _data, uint _partnerOneShare, uint _partnerTwoShare) external onlyPartner isSigned areNotSeparated {
			require(_partnerOneShare >= 0, "PartnerOne share invalid!");
			require(_partnerTwoShare >= 0, "PartnerTwo share invalid!");
			require((_partnerOneShare + _partnerTwoShare) == 100, "Total share must be equal to 100%!");

			// Adding new item
			Item memory newItem = Item({
				data: _data,
				partnerOneShare: _partnerOneShare,
				partnerTwoShare: _partnerTwoShare,
				added: false,
				removed: false
			});

			uint newItemId = items.push(newItem);
			emit ItemProposed(now, _data, msg.sender);
			itemIds.push(newItemId - 1);
			Item storage item = items[newItemId - 1];

			//approve it by the sender
			item.hasApprovedAdd[msg.sender] = true;
			emit ItemAddApproved(now, _data, msg.sender);
		}

		// approve an item so that it gets added
		function approveItem(uint _itemId) external onlyPartner isSigned areNotSeparated {
			require(_itemId > 0 && _itemId <= items.length, "Invalid Item id!");
			Item storage item = items[_itemId];
			require(item.added == false, "Item has already been added!");
			require(item.removed == false, "Item has already been removed!");
			require(item.hasApprovedAdd[msg.sender] == false, "Item is already approved by sender!");
			item.hasApprovedAdd[msg.sender] = true;
			if (item.hasApprovedAdd[partnerOne] && item.hasApprovedAdd[partnerTwo]) {
				item.added = true;
				emit ItemAdded(now, item.data);
			}
		}

		// approve the removal of an item
		function removeItem(uint _itemId) external onlyPartner isSigned areNotSeparated {
			require(_itemId > 0 && _itemId <= items.length, "Invalid item id!");
			Item storage item = items[_itemId];
			require(item.added, "Item has not been added yet!");
			require(item.removed == false, "Item has already been removed!");
			require(item.hasApprovedRemove[msg.sender] == false, "Removing the item has already been approved by the sender!");
			item.hasApprovedRemove[msg.sender] = true;

			if (item.hasApprovedRemove[partnerOne] && item.hasApprovedRemove[partnerTwo]) {
				item.removed = true;
				emit ItemRemoved(now, item.data);
			}
		}

		// adding funds to the contract
		function() external payable isSigned areNotSeparated {
			emit FundsAdded(now, msg.sender, msg.value);
		}

		// payment to any external account by either of partners
		function pay(address payable _to, uint _amount) external onlyPartner isSigned areNotSeparated {
			require(_amount <= address(this).balance, "Not enough balance available!");
			_to.transfer(_amount);
			emit FundsSent(now, _to, _amount);
		}

		// end the partnership & divide the contract stored fund equally.
		function getSeparated() external onlyPartner isSigned areNotSeparated {
			require(hasSeparated[msg.sender] == false, "Sender has already approved to end partnership!");
			hasSeparated[msg.sender] = true;
			emit SeparationApproved(now, msg.sender);

			// Check if both partners have approved to end the partnership
			if (hasSeparated[partnerOne] && hasSeparated[partnerTwo]) {
				separated = true;
				emit Separated(now);
				uint balance = address(this).balance;

				// Split the remaining balance half-half
				if (balance != 0) {
					uint balancePerPartner = balance / 2;
					partnerOne.transfer(balancePerPartner);
					emit FundsSent(now, partnerOne, balancePerPartner);
					partnerTwo.transfer(balancePerPartner);
					emit FundsSent(now, partnerTwo, balancePerPartner);
				}
			}
		}

		// returns the array of item indexes.
		function getItemIds() external view returns (uint[] memory) {
			return itemIds;
		}
	}