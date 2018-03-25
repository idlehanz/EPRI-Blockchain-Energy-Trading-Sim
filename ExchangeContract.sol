pragma solidity ^0.4.21;

contract VoltExchange {
    
    //****************************************************************
    // Customer Info Struct *** Mostly Static
    struct Customer {
        int customerBalance;
        bool userStatus; // true for critical, false for noncritical
        bool isCust;
    }
    
    //****************************************************************
    // Offered Demand Struct
    struct OffDem {
        address addr;
        int dem;
        int price;
    }
        
    //****************************************************************
    // Offered Generation Struct
    struct OffGen {
        address addr;
        int gen;
        int price;
    }
    
    //****************************************************************
    // Mappings
    mapping(address => Customer) private customers;
    mapping(address => int) private EstUsageWh;
    mapping(address => OffDem) private offdemands;
    mapping(address => OffGen) private offgenerations;
    
    //****************************************************************
    // Arrays
    address[] private DemOffAddrs;
    address[] private GenOffAddrs;
    
    //****************************************************************
    //misc variables 
    int totalfunds = 0;              // Total ether added to the contract
    int totalEstUsage = 0;           // Total usage in wh from critical users
    int demandoffers = 0;            // Total demand offers from noncritical users
    int generationoffers = 0;        // Total generation offers from noncritical users
    
    //****************************************************************
    // Creates new Customer object, default noncritical 
    function addCustomer(address addr, int bal) private returns (bool success){     
        customers[addr].customerBalance = bal;    
        customers[addr].userStatus = false;
        customers[addr].isCust = true;
        return true;
    }
    
    //****************************************************************
    // Creates new Offered Demand object
    function addOffDem(address addr, int demand, int price) private returns (bool success){
        offdemands[addr].addr = addr;
        offdemands[addr].dem = demand;
        offdemands[addr].price = price;
        return true;
    }
    
    //****************************************************************
    // Creates new Offered Generation object
    function addOffGen(address addr, int generation, int price) private returns (bool success){
        offgenerations[addr].addr = addr;
        offgenerations[addr].gen = generation;
        offgenerations[addr].price = price;
        return true;
    }
    
    //****************************************************************
    // Updates the status of customer to Critical ****NONE REVERSABLE
    function updateCrit(address addr) private {
        customers[addr].userStatus = true;
    }
    
    //****************************************************************
    // Check the status of the customer
    function isCritical(address addr) private constant returns (bool status){
        return customers[addr].userStatus;
    }
    
    //****************************************************************
    // Check to see if customer exists
    function isCustomer(address addr) private constant returns (bool customer){
        return customers[addr].isCust;
    }
    
    //****************************************************************
    // Test to see check customer balance
    function getBalance(address addr) public constant returns (int bal){
        return customers[addr].customerBalance;
    }
    
    //CUSTOMER FUNCTIONS
    //****************************************************************
    //fallback function
    function () public payable {
        int addedfunds = int(msg.value);
        if(!isCustomer(msg.sender)){                      //If the sender is not a custmer they get added to customers
            addCustomer(msg.sender,addedfunds);           //along with their funds submitted
        }
        else{
            customers[msg.sender].customerBalance += addedfunds;   //If sender is customer the balance gets added to their current balance
        }
        totalfunds += addedfunds;                         //total funds added is kept tract of for now   
    }
    
    //****************************************************************
    // Process for negotiation phase
    //****************************************************************
    
    //****************************************************************
    // Critical users submit estimated usage
    function estUsage(int usage) public constant returns (int){
        if(isCustomer(msg.sender) == false){                      //If they are not a customer they have no balance and can not submit usage
            revert();                                     //Revert to save the cost of gas
        }
        if(!isCritical(msg.sender)){                      //If they are not a current critical user they are updated to one.
            updateCrit(msg.sender);                       //This can not be undone and may need to be changed to ask users in the fallback function
        }
        EstUsageWh[msg.sender] = usage;                   //Usage is mapped to customer but not set in static struct because this is subject to change I believe
        totalEstUsage += usage;                           //Total usage is kept tract of for now
        return totalEstUsage;
    } 
    
    //****************************************************************
    // Non-critical users offer demand/price
     function offerDemand(int demand, int price) public constant returns (int){
        if(isCritical(msg.sender)){
            revert();
        }
        addOffDem(msg.sender,demand,price);               //Struct created for demand offers
        DemOffAddrs.push(msg.sender);                     //Array to hold open demand offers
        demandoffers++;                                   //Running total of demand offers
        return offdemands[msg.sender].price;
    }    
        
    //****************************************************************
    // Non-critical users offer generation/price    
    function offerGeneration(int generation, int price) public constant returns (int){
        if(isCritical(msg.sender)){
            revert();
        }
        addOffGen(msg.sender,generation,price);           //Struct created for generation offers
        GenOffAddrs.push(msg.sender);                     //Array to hold open genreation offers    
        generationoffers++;                               //Running total of demand offers
        return offgenerations[msg.sender].price;
    }    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //****************************************************************
    // Process for settlement phase
    //****************************************************************
} 
