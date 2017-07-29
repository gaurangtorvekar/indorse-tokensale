pragma solidity ^0.4.11;
import "./StandardToken.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

// note introduced onlyPayloadSize in StandardToken.sol to protect against short address attacks
// Then Deploy IndorseToken and SCRToken
// Then deploy Sale Contract
// Then, using indFundDeposit account call approve(saleContract,<amount of offering>)

contract IndorseSaleContract is  Ownable,SafeMath,Pausable {

    event badCreateSCR(address _beneficiary,uint256 tokens);

    SCRToken        scr;
    IndorseToken    ind;

    // crowdsale parameters
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public totalSupply;
    address public ethFundDeposit;      // deposit address for ETH for Indorse Fund
    address public indFundDeposit;      // deposit address for Indorse reserve

    uint256 public constant decimals = 18;  // #dp in Indorse contract
    uint256 public tokenCreationCap;
    uint256 public constant tokenExchangeRate = 1000;               // 1000 IND tokens per 1 ETH
    uint256 public constant minContribution = 0.05 ether;
 
    function IndorseSaleContract(   address _ethFundDeposit,
                                    address _indFundDeposit,
                                    address _INDtoken, 
                                    address _SCRtoken,
                                    uint256 _fundingStartTime,
                                    uint256 duration    ) { // duration in days
        ethFundDeposit   = _ethFundDeposit;
        indFundDeposit   = _indFundDeposit;
        scr = SCRToken(_SCRtoken);
        ind = IndorseToken(_INDtoken);
        fundingStartTime = _fundingStartTime;
        fundingEndTime   = fundingStartTime + duration * 1 days;

        tokenCreationCap = ind.balanceOf(_indFundDeposit);
    }

    event MintIND(address from, address to, uint256 val);
    event LogRefund(address indexed _to, uint256 _value);

    function CreateIND(address to, uint256 val) internal returns (bool success){
        MintIND(indFundDeposit,to,val);
        return ind.transferFrom(indFundDeposit,to,val);
    }

    function CreateSCR(address to, uint256 val) internal returns (bool success){
        return scr.transferFrom(0x0,to,val);
    }

    function () payable {    
        createTokens(msg.sender,msg.value);
    }

    /// @dev Accepts ether and creates new IND tokens.
    function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
      require (tokenCreationCap > totalSupply);  // CAP reached no more please
      require (now >= fundingStartTime);
      require (now <= fundingEndTime);
      require (_value > minContribution);         // To avoid spam transactions on the network    

      uint256 tokens = safeMult(_value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);
      
      // DA 8/6/2017 to fairly allocate the last few tokens
      if (tokenCreationCap < checkedSupply) {        
        uint256 tokensToAllocate = safeSubtract(tokenCreationCap,totalSupply);
        uint256 tokensToRefund   = safeSubtract(tokens,tokensToAllocate);
        totalSupply = tokenCreationCap;
        uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

        require(CreateIND(_beneficiary,tokensToAllocate));            // Create IDR
        if (!CreateSCR(_beneficiary,(_value - etherToRefund) / 1 ether)) {
            badCreateSCR(_beneficiary,(_value - etherToRefund) / 1 ether);
        }
        msg.sender.transfer(etherToRefund);
        LogRefund(msg.sender,etherToRefund);
        ethFundDeposit.transfer(this.balance);
        return;
      }
      // DA 8/6/2017 end of fair allocation code

      totalSupply = checkedSupply;
      require(CreateIND(_beneficiary, tokens));  // logs token creation
      if (!CreateSCR(_beneficiary, _value / 1 ether)) {
          badCreateSCR(_beneficiary,_value / 1 ether);
      }
      ethFundDeposit.transfer(this.balance);
    }
}