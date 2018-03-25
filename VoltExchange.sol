pragma solidity ^0.4.21;

contract VoltExchange {
    
    //fallback inits
    address[] public allCustomers;
    mapping(address => int) public customerBalance;
    
    address[] public critUsers;
    address[] public noncritUsers;
    uint customerNum;
    
    //misc variables 
    int addedfunds;
    int totalfunds;
    
    function addCustomer(address addr) public { // function by which list of member addresses is set    
        allCustomers.push(addr);    
        customerNum = allCustomers.length;    
    }
    
    //fallback fucntion
    function () public payable {
        addCustomer(msg.sender);
        addedfunds = int(msg.value);
        customerBalance[msg.sender] = addedfunds;    
        totalfunds += addedfunds;   
    }
} 
