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
    
    address[] private AcceptedDemOff;
    address[] private AcceptedGenOff;
    
    //****************************************************************
    //misc variables 
    int totalfunds = 0;              // Total ether added to the contract
    int totalEstUsage = 0;           // Total usage in wh from critical users
    uint demandoffers = 0;            // Total demand offers from noncritical users
    uint generationoffers = 0;        // Total generation offers from noncritical users
    int netOpWhLosses = 0;
    int netUsage = 0;
    int MarketPrice = 0;
    
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
    // IMPORTANT! To save computation and gas DemOffAddrs is appended without deletion.
    //            The list of current sorted offers is indexed from its length minus the demandoffers.
    function sortDemoffers(address addr) private returns (bool success) {
        uint i;
        int placed = 0;
        if(demandoffers == 0){
            DemOffAddrs.push(addr);
        }
        else{
            for(i = DemOffAddrs.length - demandoffers ; i < DemOffAddrs.length; i++){
                if(offdemands[addr].price < offdemands[DemOffAddrs[i]].price && placed == 0){
                    placed = 1;
                    DemOffAddrs.push(addr);
                    DemOffAddrs.push(DemOffAddrs[i]);
                }
                else{
                    DemOffAddrs.push(DemOffAddrs[i]);
                }
            }
            if(placed == 0){
                DemOffAddrs.push(addr);
            }
        }
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
    // IMPORTANT! To save computation and gas GenOffAddrs is appended without deletion.
    //            The list of current sorted offers is indexed from its length minus the generationoffers.
    function sortGenoffers(address addr) private returns (bool success) {
        uint i;
        int placed = 0;
        if(generationoffers == 0){
            GenOffAddrs.push(addr);
        }
        else{
            for(i = GenOffAddrs.length - generationoffers; i < GenOffAddrs.length; i++){
                if(offgenerations[addr].price < offgenerations[GenOffAddrs[i]].price && placed == 0){
                    placed = 1;
                    GenOffAddrs.push(addr);
                    GenOffAddrs.push(GenOffAddrs[i]);
                }
                else{
                    GenOffAddrs.push(GenOffAddrs[i]);
                }
            }
            if(placed == 0){
                GenOffAddrs.push(addr);
            }
        }
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
    // Deposit function
    function depositETH() public payable {                //Changed to deposit function from fallback
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
    // Critical users submit estimated demand or generation, the difference between the two being overall usage.
    function estUsage(int Wh) public {
        if(isCustomer(msg.sender) == false){              //If they are not a customer they have no balance and can not submit usage
            revert();                                     //Revert to save the cost of gas
        }
        if(!isCritical(msg.sender)){                      //If they are not a current critical user they are updated to one.
            updateCrit(msg.sender);                       //This can not be undone and may need to be changed to ask users in another function
        }
        EstUsageWh[msg.sender] = Wh;                   //A postive Wh is a demand and a negative Wh is a generation from critical user.
        totalEstUsage += Wh;                           //Total usage is kept tract of for now
    } 
    
    //****************************************************************
    // Non-critical users offer demand/price
     function offerDemand(int demand, int price) public{
        if(isCritical(msg.sender)){
            revert();
        }
        addOffDem(msg.sender,demand,price);               //Struct created for demand offers
        sortDemoffers(msg.sender);
        demandoffers++;                                   //Running total of demand offers
     }    
        
    //****************************************************************
    // Non-critical users offer generation/price    
    function offerGeneration(int generation, int price) public{
        if(isCritical(msg.sender)){
            revert();
        }
        addOffGen(msg.sender,generation,price);           //Struct created for generation offers
        sortGenoffers(msg.sender);                     //Array to hold open genreation offers    
        generationoffers++;                               //Running total of demand offers
    }    
    
    //****************************************************************
    // Network operator uses this function to input Losses.
    function recieveLossesEst(int losses) private {
        netOpWhLosses = losses;
        netUsage = totalEstUsage + netOpWhLosses;
    }
    
    //****************************************************************
    // Function to send Network Operator usage imbalance.
    //function sendUsageImbalance() private returns (int imbal){
    //    return netUsage;
    //}
    
    //****************************************************************
    // Function to balance out the excess demand/generation and set market price for critical users.
    function defineMarketPrice() public {
        int acceptGenTotal = 0;
        int genPrice = 0;
        int acceptDemTotal = 0;
        int demPrice = 0;
        
        //Excess Demand, accept generation offers.
        if(netUsage > 0) {
            while(netUsage > 0 && generationoffers > 0){
                if((offgenerations[GenOffAddrs[GenOffAddrs.length - generationoffers]].gen + acceptGenTotal) <= netUsage){
                    AcceptedGenOff.push(GenOffAddrs[GenOffAddrs.length - generationoffers]);
                    acceptGenTotal += offgenerations[GenOffAddrs[GenOffAddrs.length - generationoffers]].gen;
                     //Assuming the price is per Wh. It could be the total price for all Wh as well.
                    genPrice += offgenerations[GenOffAddrs[GenOffAddrs.length - generationoffers]].gen * offgenerations[GenOffAddrs[GenOffAddrs.length - generationoffers]].price;    
                    generationoffers--;
                    netUsage -= offgenerations[GenOffAddrs[GenOffAddrs.length - generationoffers]].gen;
                }
            }
        }
        
        //Excess Generation, accept demand offers.
        else {
            while(netUsage < 0 && demandoffers > 0){
                if((offdemands[DemOffAddrs[DemOffAddrs.length - demandoffers]].dem + acceptDemTotal) <= (netUsage * -1)){
                    AcceptedDemOff.push(DemOffAddrs[DemOffAddrs.length - demandoffers]);
                    acceptDemTotal += offdemands[DemOffAddrs[DemOffAddrs.length - demandoffers]].dem;
                    //Assuming the price is per Wh. It could be the total price for all Wh as well.
                    demPrice += offdemands[DemOffAddrs[DemOffAddrs.length - demandoffers]].dem * offdemands[DemOffAddrs[DemOffAddrs.length - demandoffers]].price;
                    demandoffers--;
                    netUsage += offdemands[DemOffAddrs[DemOffAddrs.length - demandoffers]].dem;
                }
            }
        }
        
        //sendUsageImbalance();               // Here when it is needed.
         
        //IMPORTANT!!
        //Depending on how the price is defined this calculation will need to be changed as needed. As for now I am calcuationg Sum of the price in Ether and Sum of the electricity in Wh.
        MarketPrice = (genPrice + demPrice) / (acceptGenTotal + acceptDemTotal);
    }

    //****************************************************************
    // Process for settlement phase
    //****************************************************************
} 
