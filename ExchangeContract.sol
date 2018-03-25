pragma solidity ^0.4.21;

contract VoltExchange {
    
    // Customer info struct
    struct Customer {
        int customerBalance;
        bool userStatus; // true for critical, false for noncritical
        bool isCust;
        
    }
    
    // Customer index mapping
    mapping(address => Customer) public customers;
    
    //misc variables 
    int addedfunds;
    int totalfunds;
    //Customer cust;
    
    // Creates new Customer object, default noncritical 
    function addCustomer(address addr, int bal) public returns (bool success){     
        customers[addr].customerBalance = bal;    
        customers[addr].userStatus = false;
        customers[addr].isCust = true;
        return true;
    }
    
    // Updates the status of customer to Critical ****NONE REVERSABLE
    function updateCrit(address addr) public {
        customers[addr].userStatus = true;
    }
    
    // Check the status of the customer
    function isCritical(address addr) public constant returns (bool status){
        return customers[addr].userStatus;
    }
    
    // Check to see if customer exists
    function isCustomer(address addr) public constant returns (bool customer){
        return customers[addr].isCust;
    }
    
    // Test to see if balance holds
    function getBalance(address addr) public constant returns (int bal){
        return customers[addr].customerBalance;
    }
    
    //fallback function
    function () public payable {
        addedfunds = int(msg.value);
        if(!isCustomer(msg.sender)){
            addCustomer(msg.sender,addedfunds);
        }
        else{
            customers[msg.sender].customerBalance += addedfunds;
        }
        totalfunds += addedfunds;   
    }
    
    // Process for negotiation phase
    
    
    // Process for settlement phase
} 
