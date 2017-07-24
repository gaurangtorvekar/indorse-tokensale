pragma solidity ^0.4.11;

// ================= Ownable Contract start =============================
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
// ================= Ownable Contract end ===============================

// ================= Safemath Contract start ============================
/* taking ideas from FirstBlood token */
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
}
// ================= Safemath Contract end ==============================

// ================= ERC20 Token Contract start =========================
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
// ================= ERC20 Token Contract end ===========================

// ================= Standard Token Contract start ======================
/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
/*  ERC 20 token */
contract StandardToken is ERC20 {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
// ================= Standard Token Contract end ========================

// ================= Pausable Token Contract start ======================
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}
// ================= Pausable Token Contract end ========================

// ================= SCR Token Contract start ===========================
contract SCRToken is ERC20, SafeMath, Ownable {

   // metadata
    string  public constant name = "Indorse SCR Token";
    string  public constant symbol = "SCR";
    uint256 public constant decimals = 1;
    string  public version = "1.0";

    uint256 public totalSupply;

    mapping(address => uint256) balances;

    address public crowdSale;
    address public indorsePlatform;


    function setHost(address _indorsePlatform) onlyOwner {
        indorsePlatform = _indorsePlatform;
    }

    // @dev hijack this function to set crowdsale address
    // 
    function allowance(address, address ) constant returns (uint) {
        return 0;
    }
    
    
    function approve(address _crowdSale , uint) onlyOwner returns (bool)  {
       
        crowdSale       = _crowdSale;
    }

    function transfer(address, uint) returns (bool) {
        assert(false);
    }
    
    function transferFrom(address from, address to, uint value) returns (bool ok) {
        if (from==0x0) mintToken(to,value);
        else if (to == 0x0) burnToken(from,value);
        else return false;
        return true;
    }


    function mintToken(address who, uint256 value) internal {
        require((msg.sender==crowdSale) || (msg.sender == indorsePlatform));
        require(who != 0x0);
        balances[who] = safeAdd(balances[who],value);
        totalSupply   = safeAdd(totalSupply,value);
        Transfer(0x0,who,value);
    }

    function burnToken(address who, uint256 value) internal{
        require(msg.sender == indorsePlatform);
        require (who != 0x0);
        uint256 limitedVal  = (value > balances[who]) ?  balances[who] : value;
        balances[who] = safeSubtract( balances[who],limitedVal);
        totalSupply = safeSubtract(totalSupply,limitedVal);
        Transfer(who,0x0,limitedVal);
    }

    function balanceOf(address who) constant returns (uint256) {
        return balances[who];
    }
}
// ================= SCR Token Contract end =============================

// ================= Indorse Token Contract start =======================

// note introduced onlyPayloadSize in StandardToken.sol to protect against short address attacks
// Then Deploy IndorseToken and SCRToken
// Then deploy Sale Contract
// Then, using indFundDeposit account call approve(saleContract,<amount of offering>)

contract IndorseToken is SafeMath, StandardToken, Pausable {
    // metadata
    string public constant name = "Indorse Token";
    string public constant symbol = "IND";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public indFundDeposit;                                          // deposit address for Indorse reserve
    address public indFutureDeposit;                                        // deposit address for Indorse Future reserve
    address public indPresaleDeposit;                                       // deposit address for Indorse Future reserve
    address public indInflationDeposit;                                     // deposit address for Indorse Inflation pool
    
    uint256 public constant indFund    = 301 * (10 ** 5) * 10**decimals;    // 30.1 million IND reserved for Indorse use
    uint256 public constant indPreSale =  17 * (10 ** 6) * 10**decimals;    
    uint256 public constant indFuture  = 692 * (10**5) * 10**decimals;      // 69.2 million IND for future token sale
    uint256 public constant indInflation  = 100 * (10**6) * 10**decimals;   // 69.2 million IND for future token sale
   
    // constructor
    function IndorseToken(
        address _indFundDeposit,
        address _indFutureDeposit,
        address _indPresaleDeposit,
        address _indInflationDeposit
        )
    {
      indFundDeposit    = _indFundDeposit;
      indFutureDeposit  = _indFutureDeposit ;
      indPresaleDeposit = _indPresaleDeposit;
      indInflationDeposit = _indInflationDeposit;
      totalSupply       = indFund;

      balances[indFundDeposit]    = indFund;                                 // Deposit IND share
      balances[indFutureDeposit]  = indFuture;                               // Deposit IND share
      balances[indPresaleDeposit] = indPreSale;                              // Deposit IND future share
      balances[indInflationDeposit] = indInflation;                          // Deposit for inflation

      Transfer(0x0,indFundDeposit,indFund);
      Transfer(0x0,indFutureDeposit,indFuture);
      Transfer(0x0,indPresaleDeposit,indPreSale);
      Transfer(0x0,indInflationDeposit,indInflation);
   }

  function transfer(address _to, uint _value) whenNotPaused returns (bool success)  {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) whenNotPaused returns (bool success)  {
    return super.approve(_spender,_value);
  }
}
// ================= Indorse Token Contract end =======================

// ================= Actual Sale Contract Start ====================
contract mockToken {
    uint256 public indFund;

    function balanceOf(address who) constant returns (uint256);

    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}



contract IndorseSaleContract is  Ownable,SafeMath {

    event badCreateSCR(address _beneficiary,uint256 tokens);

    address SCRtoken;
    address INDtoken;

    // crowdsale parameters
    bool    public isFinalized;              // switched to true in operational state
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public totalSupply;
    address public ethFundDeposit;      // deposit address for ETH for Indorse Fund
    address public indFundDeposit;      // deposit address for Indorse reserve


    uint256 public constant decimals = 18;  // #dp in Indorse contract
    uint256 public tokenCreationCap;
    uint256 public constant tokenCreationMin = 1 * (10**6) * 10**decimals;  // 1,000,000 tokens minimum
    uint256 public constant tokenExchangeRate = 1000;               // 1000 IND tokens per 1 ETH
 
 
    mapping (address => uint256) deposits;

    event LogRefund(address indexed _to, uint256 _value);

    function IndorseSaleContract(   address _ethFundDeposit,
                                    address  _indFundDeposit,
                                    address _INDtoken, 
                                    address _SCRtoken,
                                    uint256 _fundingStartTime,
                                    uint256 duration    ) { // duration in days
        ethFundDeposit   = _ethFundDeposit;
        indFundDeposit   = _indFundDeposit;
        SCRtoken = _SCRtoken;
        INDtoken = _INDtoken;
        fundingStartTime = _fundingStartTime;
        fundingEndTime   = fundingStartTime + duration * 1 minutes;

        mockToken tok = mockToken(INDtoken);
        tokenCreationCap = tok.balanceOf(_indFundDeposit);
    }

    event MintIND(address from, address to, uint256 val);

    function CreateIND(address to, uint256 val) internal returns (bool success){
        MintIND(indFundDeposit,to,val);
        mockToken ind = mockToken(INDtoken);
        return ind.transferFrom(indFundDeposit,to,val);
    }

    function CreateSCR(address to, uint256 val) internal returns (bool success){
        mockToken scr = mockToken(SCRtoken);
        return scr.transferFrom(0x0,to,val);
    }

    function () payable {    
        createTokens(msg.sender,msg.value);
    }

/// @dev Accepts ether and creates new IND tokens.
    function createTokens(address _beneficiary, uint256 _value) internal {
      require (!isFinalized);
      require (now >= fundingStartTime);
      require (now <= fundingEndTime);
      require (_value > 0);

      uint256 tokens = safeMult(_value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);
      
      // DA 8/6/2017 to fairly allocate the last few tokens
      if (tokenCreationCap < checkedSupply) {
        require (tokenCreationCap > totalSupply);  // CAP reached no more please
        uint256 tokensToAllocate = safeSubtract(tokenCreationCap,totalSupply);
        uint256 tokensToRefund   = safeSubtract(tokens,tokensToAllocate);
        totalSupply = tokenCreationCap;
        uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

        require(CreateIND(_beneficiary,tokensToAllocate));            // Create IDR
        if (!CreateSCR(_beneficiary,tokensToAllocate / 1 ether)) {
            badCreateSCR(_beneficiary,tokensToAllocate / 1 ether);
        }
        msg.sender.transfer(etherToRefund);
        LogRefund(msg.sender,etherToRefund);
        ethFundDeposit.transfer(this.balance);
        return;
      }
      // DA 8/6/2017 end of fair allocation code

      totalSupply = checkedSupply;
      deposits[_beneficiary] = safeAdd(deposits[_beneficiary],_value);
      require(CreateIND(_beneficiary, tokens));  // logs token creation
      if (!CreateSCR(_beneficiary, tokens / 1 ether)) {
          badCreateSCR(_beneficiary,tokens / 1 ether);
      }
      if (totalSupply > tokenCreationMin) {
          ethFundDeposit.transfer(this.balance);
      }
    }


    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      require (!isFinalized) ;
      require (msg.sender == ethFundDeposit) ; // locks finalize to the ultimate ETH owner
      // if(totalSupply < tokenCreationMin) throw;      // have to sell minimum to move to operational
      require (now > fundingEndTime || totalSupply == tokenCreationCap) ;
      // move to operational
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);  // send the eth to Indorse
    }

    // Might not need this if we hit the pre-sale cap 

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      require(!isFinalized);                       // prevents refund if operational
      require (now > fundingEndTime); // prevents refund until sale period is over
      require(totalSupply < tokenCreationMin);  // no refunds if we sold enough
      require(deposits[msg.sender] > 0);    // Brave Intl not entitled to a refund
      uint256 refund = deposits[msg.sender];
      deposits[msg.sender] = 0;
      LogRefund(msg.sender, refund);               // log it 
      msg.sender.transfer(refund); 
    }




}