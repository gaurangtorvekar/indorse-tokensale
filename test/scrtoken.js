var SCRToken = artifacts.require("SCRToken");

contract('SCRToken', function(accounts){
  it("should have a zero balance to begin with", function(){
    return SCRToken.deployed().then(function(instance){
      return instance.balanceOf.call(accounts[0], {from: accounts[0]});
    }).then(function(balance){
      assert.equal(balance.toNumber(), 0, "Balance wasn't zero");
    });
  });

  it("should reject setHost() requests from any address", function(){
    return SCRToken.deployed().then(function(instance){
      return instance.setHost(accounts[0]);
    }).then(function(){
      assert.equal(SCRToken.indorsePlatform, undefined);
    });
  });

  it("should have accounts[0] listed as the owner", function(){
    return SCRToken.deployed().then(function(instance){
      return instance.owner();
    }).then(function(owner){
      assert.equal(owner, accounts[0]);
    });
  });
});