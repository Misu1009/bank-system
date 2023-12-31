// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Bank{
    address private owner_address;
    string public owner_name;

    // create owner this bank
    constructor(string memory name) {
        owner_address = msg.sender;
        owner_name = name;
    }

    uint private customer_total;
    address[] private customer_list;

    enum Status{DEPOSIT, RECEIVE, TRANSFER, WITHDRAW, ACCOUNT_CREATED}

    struct Transaction_history{
        uint date;
        Status status;
    }
    struct Customer_data{
        string name;
        uint balance;
        bool active;   
    }

    mapping(address => Customer_data) customer;
    mapping(address => Transaction_history[]) history;

    // is customer exist or not
    modifier exist(address alamat){
        require(customer[alamat].active, "CUSTOMER DOESN'T EXIST");
        _;
    }

    // is owner or not
    modifier ownership(){
        require(msg.sender == owner_address, "YOU ARE NOT AN OWNER OF THIS BANK");
        _;
    }

    // check total customer, only owner can do 
    function get_customer_total() public view ownership() returns(uint){
        return customer_total;
    }

    // check all customer data, only owner can do
    function check_all_customer() public view ownership() returns(string[] memory) {
        string[] memory list_of_customer = new string[](customer_total);
        for(uint i=0; i<customer_total; i++){
            list_of_customer[i] = string.concat("No. ", toString(i+1), " -> ", customer[customer_list[i]].name, ", ", toString(customer[customer_list[i]].balance));
        }
        return list_of_customer;
    }

    // register new customer
    function register_customer(string memory name)public {
        customer[msg.sender] = Customer_data(name, 0, true);
        history[msg.sender].push(Transaction_history(block.timestamp, Status.ACCOUNT_CREATED));

        customer_list.push(msg.sender);
        customer_total++;
    }

    // deposit / add balance
    function deposit()public payable exist(msg.sender){
        customer[msg.sender].balance += msg.value;

        history[msg.sender].push(Transaction_history(block.timestamp, Status.DEPOSIT));
    }

    // transfer to another account
    function transfer(address target_address, uint amount) 
                public payable exist(msg.sender) exist(target_address){
        
        require(amount <= customer[msg.sender].balance, "BALANCE ISN'T ENOUGH");

        customer[msg.sender].balance -= amount;
        customer[target_address].balance += amount;

        history[msg.sender].push(Transaction_history(block.timestamp, Status.TRANSFER));
        history[target_address].push(Transaction_history(block.timestamp, Status.RECEIVE));
    }

    // check customer data
    function check_data()public view returns(string memory, uint){
        return (customer[msg.sender].name, customer[msg.sender].balance);
    }
    
    // check history of customer like account created, deposit, withdraw ...
    function check_history() public view returns(string[] memory){
        string[] memory list_of_history = new string[](history[msg.sender].length);
        for(uint i=0; i<history[msg.sender].length; i++){
            list_of_history[i] = 
                string.concat
                    (
                    "No. ", toString(i+1), 
                    " -> ", toString(history[msg.sender][i].date),
                     ", ", status_to_string(history[msg.sender][i].status)
                );
        }

        return list_of_history;
    }

    // withdraw the balance 
    function withdraw(uint amount)public exist(msg.sender){
        customer[msg.sender].balance -= amount;

        payable(msg.sender).transfer(amount); 

        history[msg.sender].push(Transaction_history(block.timestamp, Status.WITHDRAW));
    }

    // convert enum member to string
    function status_to_string(Status status) private pure returns(string memory){
        if(status == Status.ACCOUNT_CREATED) return "Account Created";
        if(status == Status.DEPOSIT) return "Deposit";
        if(status == Status.RECEIVE) return "Recieve";
        if(status == Status.TRANSFER) return "Transfer";
        if(status == Status.WITHDRAW) return "Withdraw";
    }

    // function code from GeeksForGeeks https://www.geeksforgeeks.org/type-conversion-in-solidity/
    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

