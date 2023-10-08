// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BillOfLading {
    address public sender;
    address public receiver;
    address public carrier;
    uint256 public amount;
    string public goodsDescription;
    uint256 public creationTimestamp;
    uint256 public deliveryTimestamp;
    bool public isDelivered;
    bool public isAccepted;

    enum State {
        Created,
        Shipped,
        Delivered,
        Accepted,
        Disputed,
        Closed
    }
    State public currentState;

    event Shipped(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        string goodsDescription,
        uint256 timestamp
    );
    event Delivered(address indexed sender, uint256 timestamp);
    event Accepted(address indexed receiver, uint256 timestamp);
    event Disputed(
        address indexed sender,
        address indexed receiver,
        string reason
    );
    event Closed(
        address indexed sender,
        address indexed receiver,
        string reason
    );

    modifier onlySender() {
        require(
            msg.sender == sender,
            "Only the sender can perform this action"
        );
        _;
    }

    modifier onlyReceiver() {
        require(
            msg.sender == receiver,
            "Only the receiver can perform this action"
        );
        _;
    }

    modifier onlyCarrier() {
        require(
            msg.sender == carrier,
            "Only the carrier can perform this action"
        );
        _;
    }

    modifier inState(State expectedState) {
        require(currentState == expectedState, "Invalid state for this action");
        _;
    }

    constructor(
        address _receiver,
        address _carrier,
        uint256 _amount,
        string memory _goodsDescription
    ) {
        sender = msg.sender;
        carrier = _carrier;
        receiver = _receiver;
        amount = _amount;
        goodsDescription = _goodsDescription;
        creationTimestamp = block.timestamp;
        currentState = State.Created;
    }

    function ship() public onlyCarrier inState(State.Created) {
        currentState = State.Shipped;
        emit Shipped(
            sender,
            receiver,
            amount,
            goodsDescription,
            block.timestamp
        );
    }

    function deliver() public onlyReceiver inState(State.Shipped) {
        currentState = State.Delivered;
        deliveryTimestamp = block.timestamp;
        emit Delivered(sender, deliveryTimestamp);
    }

    function accept() public onlyReceiver inState(State.Delivered) {
        currentState = State.Accepted;
        emit Accepted(receiver, block.timestamp);
    }

    function dispute(
        string memory reason
    ) public onlySender inState(State.Delivered) {
        currentState = State.Disputed;
        emit Disputed(sender, receiver, reason);
    }

    function closeDispute(
        string memory reason
    ) public onlySender inState(State.Disputed) {
        currentState = State.Closed;
        emit Closed(sender, receiver, reason);
    }
}
