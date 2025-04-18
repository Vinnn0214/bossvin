pragma solidity ^0.8.7;

contract EnhancedERC20 {
   uint256 private totalSupply;
   uint256 public _maxTotalSuppl = 10000000; // Maximum total supply

   event Transfer(address indexed from, address indexed to, uint256 value);

   // Modifier to ensure total supply does not exceed maximum limit
   modifier maxSupply(uint256 _value) {
       require(totalSupply + _value <= _maxTotalSuppl, "Maximum Supply Exceeded");
       _;
   }

   // Transfer function to send tokens
   function transfer(address recipient, uint256 _value) public maxSupply(_value) {
       require(_value > 0, "Transfer amount must be greater than 0");

       // Simulate transferring tokens (e.g., subtract from sender balance, etc.)
       totalSupply += _value; // Increase the total supply

       emit Transfer(msg.sender, recipient, _value);
   }

   // Function to get the current total supply
   function getTotalSupply() public view returns (uint256) {
       return totalSupply;
   }
}
