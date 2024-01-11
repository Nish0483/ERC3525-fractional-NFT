// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC3525.sol";

contract FractionalRealEstateNFT is ERC3525 {
    address public realEstateOwner;
    uint256 public totalShares;
    uint256 public sharePrice;
    string public propertyDetails;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address realEstateOwner_,
        uint256 totalShares_,
        uint256 sharePrice_,
        string memory propertyDetails_
    ) ERC3525(name_, symbol_, decimals_) {
        realEstateOwner = realEstateOwner_;
        totalShares = totalShares_;
        sharePrice = sharePrice_;
        propertyDetails = propertyDetails_;
    }

    function fractionalizeRealEstate() external {
        require(msg.sender == realEstateOwner, "Not authorized");
        _mint(realEstateOwner, totalShares, 0);
    }

    function purchaseShares(uint256 _amount) external payable {
        uint256 cost = _amount * sharePrice;
        require(msg.value >= cost, "Insufficient Ether sent");

        _mintValue(totalShares, _amount);
    }

    function redeemShares(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Insufficient shares");

        uint256 refund = _amount * sharePrice;
        _burnValue(totalShares, _amount);
        payable(msg.sender).transfer(refund);
    }

    // function withdrawBalance() external  {
    //     payable(owner()).transfer(address(this).balance);
    // }
}
