pragma solidity >=0.4.22 <0.6.0;

contract PropertyRentalContract {

	struct Property {
		string name; // name of the property
		string addr; // address of the property
		bool rented; // rent status of the property
		uint rentInterval; // interval in days for the rent amount
		uint rentAmount; // property rent value
		uint tenantWarning; // tracks the count for warning given to tenant
		uint warningLimit; // threshold limit for warning. Once exceeded tenant can be dismissed.
		uint dueDate; // unix timestamp for the dueDate.
		address tenant; // tenant wallet address
	}

	struct MonthlyRentStatus {
		uint amount; // Monthly rent amount to be paid.
		uint validationDate; // unix timestamp at which the rent was paid.
		bool status; // rent status.
	}

	Property property; // instance of Property struct
	address payable public owner; // wallet address of contract/property owner
	uint private warningTime = 0; // unix timestamp when the tenant gets warned.
	mapping(string => bool) months;
	mapping(address => bool) public tenantRegistry; // storage for users other than owner registered as a prospect.
	mapping(string => MonthlyRentStatus) rentInStore; // storage for rental status

	event reg(address _from, bool _val); // event when user regiters as a prospect
	event confirmed(address _from, bool _val); // event when property gets set on rent.
	event rentPaid(string _month, uint _amount); // event when the rent payment transaction is complete.
	event rentWithdrawn(string _month, uint _amount); // event when rent is withdrawn from the contract.
	event tenantWarning(string _month, uint _warning); // event to warn the tenant about pending payment.
	event dismissTenantConfirmed(bool _confirmed); // event to confirm the dismissal of tenant.

	constructor(string memory name, string memory addr, uint rentInterval, uint rentAmount, uint warningLimit) public {
		property = Property({name: name, addr: addr, rented: false, rentInterval: rentInterval, rentAmount: rentAmount,
		warningLimit: warningLimit, tenantWarning: 0, dueDate: 0, tenant: address(0) });
		owner = msg.sender;
		setMonths();
	}

	function setMonths() private {
	    months["Jan"] = true;
	    months["Feb"] = true;
	    months["Mar"] = true;
	    months["Apr"] = true;
	    months["May"] = true;
	    months["Jun"] = true;
	    months["Jul"] = true;
	    months["Aug"] = true;
	    months["Sep"] = true;
	    months["Oct"] = true;
	    months["Nov"] = true;
	    months["Dec"] = true;
	}

	modifier onlyOwner {
        require(msg.sender == owner, "Only owner is authorized to perform this transaction");
        _;
    }

	modifier nonOwner {
        require(msg.sender != owner, "One who is not an owner is authorized to perform this action");
        _;
    }

	modifier nonTenant {
        require(msg.sender == property.tenant, "Only tenant is allowed to carry out the transaction");
        _;
    }

	modifier allowedMonths(string memory month) {
		require(months[month] == true, "Incorrect value of the month");
		_;
	}

	// setting the user as prospect
	function registerAsTenant() external nonOwner returns (bool success) {
		require(property.rented == false, "Property is already on rent");
		tenantRegistry[msg.sender] = true;
		emit reg(msg.sender, true);
		return true;
	}

	// setting the property on rent by confirming the tenant from given list of prospects
	function confirmTenant(address tenantAddress) external onlyOwner returns(bool success) {
		require(tenantRegistry[tenantAddress] == true, "Given tenant has not been registered yet.");
			property.tenant = tenantAddress;
			property.rented = true;
			property.dueDate = (now + (property.rentInterval * 1 days));
			emit confirmed(tenantAddress, true);
			return true;
	}

	// rent payment payable method which also sets the next due date
	function payRent(string calldata  month) external payable nonTenant allowedMonths(month) returns (bool success) {
		require(rentInStore[month].status == false,
        "Rent already paid for the given month"); // use require & not if statement, since function is payable & transaction should get reverted in invalid case.
		require(msg.value == property.rentAmount,
        "Reverting transaction since given amount is not equal to actual amount");
		rentInStore[month].amount = msg.value;
		rentInStore[month].status = true;
		rentInStore[month].validationDate = now;
		property.dueDate = (now + (property.rentInterval * 1 days));
		property.tenantWarning = 0;
		emit rentPaid(month, msg.value);
		return true;
	}

	// provides the rent status based on given month
	function getRentStatus(string calldata month) external allowedMonths(month) view returns(uint amount, uint date, bool status) {
		MonthlyRentStatus memory rentStatus = rentInStore[month];
		return (
			rentStatus.amount,
			rentStatus.validationDate,
			rentStatus.status
		);

	}

	// an api for property owner to withdraw the rent amount from smart contract.
	function withdrawRent(string calldata month) external onlyOwner allowedMonths(month) returns (bool success) {
		require(rentInStore[month].amount <= address(this).balance,
         "Insufficient contract balance to suffice the transaction"); // This is a must condition.
		uint balance = rentInStore[month].amount;
		if(balance == property.rentAmount) {
			owner.transfer(balance);
			rentInStore[month].amount = 0;
		}
		emit rentWithdrawn(month, property.rentAmount); // confirming the rent withdraw transaction.
		return true;
	}

	// when owner wants to warn the tenant about pending rent payment.
	function warnTenant(string calldata month) external onlyOwner allowedMonths(month) returns (bool success) {
		require(property.rented == true, "Tenant doesn't exists");
		if((rentInStore[month].status == false) && (now > property.dueDate) && ((now - warningTime) > 172800000)) {
			property.tenantWarning++;
			warningTime = now;
			emit tenantWarning(month, property.tenantWarning);
			return true;
		}
		return false;
	}

	// when warning limit has been crossed & owner wants to dismiss the tenant
	function dismissTenant() external onlyOwner returns (bool success) {
		require(property.tenantWarning > property.warningLimit,"Cannot dismiss tenant as warning limit is below threshold");
		property.tenant = address(0);
		property.rented = false;
		property.tenantWarning = 0;
		property.dueDate = 0;
		emit dismissTenantConfirmed(true);
		return true;
	}
}
