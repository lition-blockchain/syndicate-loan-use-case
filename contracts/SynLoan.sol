pragma solidity ^0.5.2;

// necessary because some functions return structs
pragma experimental ABIEncoderV2;

/*
Contract for Syndicate Loan MVP by Lition Technologie AG - www.lition.io
version 0.1.8
creator: Marcel Jackisch
*/


contract SynLoanData {
    
    uint public loanId;     // supposed to be a unique number

    LoanData[] public loans;
    
    struct LoanData {
        string name;                        // Name of  the Loan
        uint id;                            // Loan ID
        uint revisionNumber;                // Shall increment with every update to the loan
        address registeringParty;           // to record in struct who created the loan --> make array 
        string purpose;             
        uint regTime;                           // UNIX Timestamp
        mapping (address => uint) userToId;     // Gets local user id belonging (mapped to) an address in loan
        uint[] loanAmounts;                     // corresponding to participants
        bool[] approvalStatus;                  // Array to store approvals
        address[] userList; 
        uint8 numOfUsers; 
    }

/*
Struct user defines key data of participants such as banks and businesses -
*/
    struct userData {
        string name;
        string role;        // Borrower or Lender
        address account;    
    }

    // Public array of all participants in dApp/Smart Contract (maybe unnecessary)
    userData[] public users;      
    
    // Dictionary to find account data
    mapping (address => userData) addressToUserData; 

    // Map a loan id to an account address of user
    mapping (uint => address) loanToRegistrar; 

    // counts the amount of loans belonging to the address
    mapping (address => uint) userLoanCount;


    /*
    Modifier to make sure only registrar of loan can update
    */
    modifier onlyRegistrar(uint _loanId) {
      require(msg.sender == loanToRegistrar[_loanId]);
      _;
    }

    /*
    Function to add new users to a loan, checks if user has been added before
    */
    function addUserToLoan (uint _loanId, address _account) public onlyRegistrar(_loanId) returns (uint){
        //  Require should work as follows: Check if uint mapped to account address is zero, if e.g. 1, an address can't be added twice
        // Problem: First user (Registrar has userId 0, therefore, could be added twice 
        require(loans[_loanId].userToId[_account] == 0, "User already exists in loan");
        uint userNum = loans[_loanId].numOfUsers++;
        // Adds user to mapping
        loans[_loanId].userToId[_account] = userNum;
        // Pushes address to userList array (to retrieve all users, iterate)
        loans[_loanId].userList.push(_account);
        
        // Let size of arrays that correspond with users grow in size
        loans[_loanId].approvalStatus.length++;
        loans[_loanId].loanAmounts.length++;
        return userNum;
    }

    /*
    Registration of User Accounts
    */
    function registerUser (string memory _name, string memory _role) public {

        // Require arguments, otherwise ghost users possible
        
        // Self-registration: adds Userdata to user array
        // users.push(userData(_name, _role, msg.sender));
        
         // Self-registration: Mapping
        addressToUserData[msg.sender] = userData(_name, _role, msg.sender);

    }


    function createLoan (string memory _name, string memory _purpose) public {

        loanToRegistrar[loanId] = msg.sender;   // Store the address of the user in mapping
        userLoanCount[msg.sender]++;            // necessary for array to count loans registered by user
        
        // create LoanData instance in memory, later populate array
        LoanData memory ln;
        ln.name = _name;
        ln.id = loanId;
        ln.revisionNumber = 0;
        ln.registeringParty = msg.sender;
        ln.purpose = _purpose;
        ln.regTime = now;
        
        loans.push(ln);
        
        // Add loan creator himself
        addUserToLoan(loanId, msg.sender);
        loanId++;
    }


/*
Update Loan Data, increment version / revision number
Here, all the other data like loan amount, start date and other conditions shall be filled
*/
    function updateLoan(string memory _name, uint _id, string memory _purpose) 
        public onlyRegistrar(_id)
    {
        loans[_id].name = _name;
        loans[_id].revisionNumber++;
        loans[_id].purpose = _purpose;
    }

 /*
Possibility to delete loan
 */   

    function deleteLoan(uint _id) public onlyRegistrar(_id) {
        delete loans[_id];
    }


/*
Approves Loan: each participant of Loan can give his approval
*/

    function approveLoan(uint _id) public  {
        uint userId = loans[_id].userToId[msg.sender];
        loans[_id].approvalStatus[userId] = true;
    }

/*
Helper function to retrieve UserId from mapping inside struct
 */
    function getUserToId(uint256 _id, address _address) public view returns (uint256) {
        return loans[_id].userToId[_address];
    }
    
 /*
Helper function to retrieve List of all registered Addresses in Loan 
Add: Their position / id
 */   
    function getUsersInLoan (uint256 _loanId) public view returns (address[] memory, uint) {
        address[] memory addrArr = loans[_loanId].userList;
        uint userCount = loans[_loanId].numOfUsers;
        return (addrArr, userCount);
    }
    
    
    function getAddressToUser(address _address) public view returns (userData memory) {
        return addressToUserData[_address];
    }
    
 /*
Helper function to retrieve approval status array
 */   
    function getApprovalStatus(uint256 _id) public view returns (bool[] memory) {
        bool[] memory array = loans[_id].approvalStatus; // approvalStatus is a bool array in a struct array 
        return array;
    }
    


/*
Get the length of the loan array
*/
    function getArrLength() public view returns (uint256)
    {
        return (loans.length) ;
    }


/*
The function should return an array with all the loans the user is involved in, disregarding any other permissioning like read-write requests
As of now, only the registrar mapping is applied, a loan belonging to multiple users cannot be created yet
*/
    function getLoansByUser(address _user) external view returns(uint[] memory) {
        // Create a new array with as many entries as Loans belong to the user
        uint[] memory result = new uint[](userLoanCount[_user]);
        uint counter = 0;
        // Iterate through loanToRegistrar mapping and check if equals address, then sum up
        for (uint i = 0; i < loans.length; i++) {
            if (loanToRegistrar[i] == _user) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }



}