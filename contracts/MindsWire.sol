pragma solidity ^0.4.13;

import './MindsToken.sol';
import './MindsWireStorage.sol';
import './Whitelist.sol';

contract MindsWire is Whitelist {

  struct Wire {
    uint timestamp;
    uint value;
  }

  MindsToken public token;
  MindsWireStorage public s;

  /**
   * event for wire sending
   * @param sender who sent the wire
   * @param receiver who receive the wire
   * @param amount weis sent
   */
  event WireSent(address sender, address receiver, uint256 amount);

  function MindsWire(address _storage, address _token) {
    s = MindsWireStorage(_storage);
    token = MindsToken(_token);
  }

  function canIWire() public constant returns (bool) {
    uint balance = token.balanceOf(msg.sender);
    uint allowed = token.allowance(msg.sender, address(this));

    if (allowed > 0 && balance > 0) {
      return true;
    }

    return false;
  }

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) public returns (bool) {

    require(msg.sender == address(token));

    address _receiver = 0x0;
    assembly {
      // Load the raw bytes into the respective variables to avoid any sort of costly
      // conversion.
      _receiver := mload(add(_extraData, 0x20))
    }

    require(_receiver != 0x0);

    return wireFrom(_from, _receiver, _value);
  }

  function wire(address receiver, uint amount) public returns (bool) {
    return wireFrom(msg.sender, receiver, amount);
  }

  function wireFrom(address sender, address receiver, uint amount) public returns (bool) {

    require(amount >= 0);

    token.transferFrom(sender, receiver, amount);
    s.insert(sender, receiver, amount);
    WireSent(sender, receiver, amount);
    return true;
  }

  function hasSent(address receiver, uint amount, uint timestamp) public constant returns (bool) {
    uint total;

    Wire memory _wire;

    uint len = s.countWires(receiver, msg.sender);

    for (uint i = 0; i < len; i++) {
      (_wire.timestamp, _wire.value) = s.wires(receiver, msg.sender, i);

      if (_wire.timestamp >= timestamp) {
        total += _wire.value;
      }
    }

    if (total >= amount) {
      return true;
    }

    return false;
  }

}