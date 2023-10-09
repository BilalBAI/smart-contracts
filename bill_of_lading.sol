// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BillsOfLading {
    address private owner;
    struct Bol {
        address seller;
        address buyer;
        address carrier;
        uint256 amount; // in currency
        string goodsDescription;
        uint256 creationTimestamp;
        uint256 deliveryTimestamp;
        bool carrierSignOff; // Lock/release the fund from buyer withdraw. true: funds will be locked, false: funds is withdrawable by buyer
        bool buyerSignOff; // Lock/release the fund from seller withdraw. true: funds is withdrawable by seller, false: seller cannot withdraw funds
        bool sellerSignOff; // Carrier can only start delivering goods when this is true
        bool isDelivered;
        bool isAccepted;
    }
    Bol[] public allBols;

    event NewBolLaunched(
        uint id,
        address seller,
        address buyer,
        address carrier
    );
    event SellerWithdrawn(uint256 id, address seller, uint256 amount);
    event BuyerWithdrawn(uint256 id, address buyer, uint256 amount);
    event BuyerDeposite(uint256 id, address buyer, uint256 amount);
    event CarrierSignOff(uint256 id, address carrier);
    event BuyerSignOff(uint256 id, address buyer);
    event SellerSignOff(uint256 id, address seller);

    function sellerLaunchBol(
        address buyer,
        address carrier,
        string memory goodsDescription
    ) external {
        address seller = msg.sender;
        require(buyer != address(0), "Invalid buyer address");
        require(carrier != address(0), "Invalid carrier address");
        uint256 creationTimestamp = block.timestamp;
        uint256 deliveryTimestamp = 0;

        allBols.push(
            Bol(
                seller,
                buyer,
                carrier,
                0,
                goodsDescription,
                creationTimestamp,
                deliveryTimestamp,
                false,
                false,
                false,
                false,
                false
            )
        );
        emit NewBolLaunched(allBols.length, seller, buyer, carrier);
    }

    function sellerWithdraw(uint id) external payable {
        require(
            msg.sender == allBols[id].seller,
            "Only the seller can perform this action"
        );
        require(
            allBols[id].buyerSignOff == true,
            "Cannot withdraw: buyer hasn't signed off"
        );
        require(allBols[id].amount > 0, "No balance to withdraw");
        payable(msg.sender).transfer(allBols[id].amount);

        emit SellerWithdrawn(id, msg.sender, allBols[id].amount);
        allBols[id].amount = 0;
    }

    function buyerWithdraw(uint id) external payable {
        require(
            msg.sender == allBols[id].buyer,
            "Only the buyer can perform this action"
        );
        require(
            allBols[id].carrierSignOff == false,
            "Cannot withdraw: carrier has signed off for shipping, the fund is locked"
        );
        require(allBols[id].amount > 0, "No balance to withdraw");

        payable(msg.sender).transfer(allBols[id].amount);
        emit BuyerWithdrawn(id, msg.sender, allBols[id].amount);
        allBols[id].amount = 0;
    }

    function buyerDeposite(uint id) external payable {
        // Buyer deposite funds to the contract for exchange of goods
        require(
            msg.sender == allBols[id].buyer,
            "Only the buyer can perform this action"
        );
        allBols[id].amount = msg.value + allBols[id].amount;
        emit BuyerDeposite(id, msg.sender, allBols[id].amount);
    }

    function carrierSignOff(uint id) external {
        // Carrier signoff the contract to confirm the goods are ready for ship and
        // match those on the goods description
        require(
            msg.sender == allBols[id].carrier,
            "Only the carrier can perform this action"
        );
        allBols[id].carrierSignOff = true;
        emit CarrierSignOff(id, msg.sender);
    }

    function carrierUnSign(uint id) external {
        // In case of deal cancle or return, carrier unsign the contract,
        // so that the funds can be withdraw by buyer
        require(
            msg.sender == allBols[id].carrier,
            "Only the carrier can perform this action"
        );
        allBols[id].carrierSignOff = false;
        emit CarrierSignOff(id, msg.sender);
    }

    function buyerSignOff(uint id) external {
        // Buyer sign off the contract to confirm the goods are received and
        // accepted, which allows the seller to withdraw funds
        require(
            msg.sender == allBols[id].buyer,
            "Only the buyer can perform this action"
        );
        allBols[id].buyerSignOff = true;
        emit BuyerSignOff(id, msg.sender);
    }

    function sellerSignOff(uint id) external {
        // Seller sign off the contract to agree that the funds locked
        // are sufficient and the goods can be shipped to the buyer
        // Seller can only sign off after carrier
        require(
            msg.sender == allBols[id].seller,
            "Only the buyer can perform this action"
        );
        require(
            allBols[id].carrierSignOff == true,
            "Cannot sign off: carrier hasn't signed off yet"
        );
        allBols[id].sellerSignOff = true;
        emit SellerSignOff(id, msg.sender);
    }
}
