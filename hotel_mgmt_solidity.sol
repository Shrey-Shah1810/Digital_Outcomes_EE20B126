// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

contract hotel_reservation{
    
    uint public registrationfee;
    uint refund7;//percentage fee returned for cancellation done 7 or more days before booking
    uint refund2;//percentage fee returned for cancellation done 2 or more days before booking
    address payable public beneficiary;
    event registration(address guest, uint day, uint month, uint year);
    event cancellation(address guest, uint day, uint month, uint year);
    
    mapping (uint=>uint) private perday; //Mapping the address that have been booked on a particular date to the unit containing the date 
    mapping (address=>uint) private has_cancelled;//Mapping the address to an int(0/1) that stores if the guest has cancelled his/her reservation or not
    mapping (address=>uint) private balance;//Mapping the address of the guest to the amount paid by them
    
    constructor(uint _registrationfee, address payable _beneficiary)
    {   // run only once during time of deployment to store the fixed(permanent variables)
        
        registrationfee = _registrationfee;
        refund7 = 50;
        refund2 = 0;
        beneficiary = _beneficiary;
    }
    
    
    function is_leap(uint year) pure private returns (bool){
        //function which takes the year to check for leap year and returns boolean stating if a year is leap year or not
        //Condition of leap year is no. should be divisible by 4 and not be divisible by unless it is divisible by 400 as well 
        if(year%4==0){
            if(year%100==0 && year%400!=0){
                return false;  
            }
            return true;
        }
        return false;
    }
    
    function daysinmonth(uint month, uint year) pure private returns (uint){
        // function that returns the number of days in a particular month based on the month and year value entered
        uint[13] memory day;
        day[1] = 31;
        day[2] = 28;
        day[3] = 31;
        day[4] = 30;
        day[5] = 31;
        day[6] = 30;
        day[7] = 31;
        day[8] = 31;
        day[9] = 30;
        day[10] = 31;
        day[11] = 30;
        day[12] = 31;
        if(is_leap(year)==true)
            day[2] = 29;
        return day[month];
    }
    
    function num_of_days(uint year, uint month, uint date) pure private returns (uint){
        //returns the number of days from epoch till the input date
        uint sum;
        sum = (year-1970)*365 + (year-1972)/4 + 1; //Since after epoch(1 Jan 1970) there hasn't been a century year not divisible by 400 thus ignoring the condition test here
        for(uint i = 1; i< month; i++)
        {
            sum = sum + daysinmonth(i,year);
        }
        sum = sum + date;
        return sum;
    }
    
    
    function timestamp_to_days(uint y) pure private returns (uint){
        //function that converts timestamp(entered as parameter) to return number of days from epoch
        return y/(24*60*60) + 1;
    } 
    
       function threetoone(uint day, uint month, uint year) pure private returns (uint){
           //function that changes format of date from dd,mm,yyyy(as received from parameter) to return yyyymmdd
        return (year*10000 + month*100 + day);
    }
    
    function vacancy(uint day, uint month, uint year) view public returns (bool){ 
        //function that returns true/false depending on if there are vacant rooms availabe on a particular date   
        uint _datetobook = threetoone(day,month,year);
        if (perday[_datetobook]<5)//Taking the number of booking possible in a day to be 5
            return true;
        else
            return false;
    }
    
    function between(uint day, uint month, uint year) view private returns (uint){ 
        //Function that returns number of days between input date(as received in the parameters) and  registered date for hotel
         uint current = block.timestamp;
         uint currentday = timestamp_to_days(current);
         uint futureday = num_of_days(year,month,day);
         return futureday - currentday;
    }
    
    
    function bookandpay(uint day, uint month, uint year) public payable{   
        //Function that books a room for the guest after taking the date they are looking for as a parameter
        require(has_cancelled[msg.sender]==0, "You can only book one room in your name");
        uint _datetobook = threetoone(day,month,year);
        require(vacancy(day,month,year)==true,"There are no vacant rooms"); //can book only if vacancy available
        require(msg.value==registrationfee,"You didnt pay the required amount"); //if required amount not paid then don't proceed
        balance[msg.sender]=registrationfee; // add the value paid into the accounts
        perday[_datetobook]++; // add the no. of bookings done on that day by 1
        has_cancelled[msg.sender]=1; // to make sure that same person doesn't book 2 rooms in his name
        emit registration(msg.sender,day,month,year);
    }
    
    function cancel(uint day, uint month, uint year) public{ 
        //cancels the room for the guest
        require(has_cancelled[msg.sender]==1,"You have already cancelled you registration"); // to make sure that the guest has an uncancelled booking
        uint daysbwt = between(day,month,year);
        if(daysbwt>7)
            payable(msg.sender).transfer(balance[msg.sender]);
        else if(daysbwt>2)
            payable(msg.sender).transfer(balance[msg.sender]*refund7/100);
        else if(daysbwt<=2)
            payable(msg.sender).transfer(balance[msg.sender]*refund2/100);
        perday[threetoone(day,month,year)]--;
        balance[msg.sender] = 0;
        emit cancellation(msg.sender,day,month,year);
        has_cancelled[msg.sender]=0;
    }
    
    function change_registrationfee(uint x) public{ 
        // function that allows the owner to change the registration fee
        require(msg.sender==beneficiary,"You cannot change the registrationfee");
        registrationfee = x;
    }
    
    function change_refund7(uint y) public{
        //function allows the owner to change the cancellation fee less than a week before the registered date
        require(msg.sender==beneficiary,"You cannot change the cancellation fee");
        refund7 = y;
    }
    
    function change_refund2(uint z) public{ 
        // function that alllows the owner to change the cancellation fee less than 2 days before the registered date
        require(msg.sender==beneficiary,"You cannot change the cancellation fee");
        refund2 = z;
    }

}