// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./IERC721.sol";
import "./IERC3525.sol";
import "./IERC721Receiver.sol";
import "./IERC3525Receiver.sol";
import "./extensions/IERC721Enumerable.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC3525Metadata.sol";
import "./periphery/interface/IERC3525MetadataDescriptor.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ERC3525 is Context, IERC3525Metadata, IERC721Enumerable {
    using Strings for address;
    using Strings for uint256;

    event SetMetadataDescriptor(address indexed metadataDescriptor);

    struct AssetData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tokenIdGenerator;
    mapping(uint256 => uint256) private _slotTotalValue;
    mapping(uint256 => uint256) private _slotValueCap;
    uint256[] private _allSlots;
    mapping(uint256 => string) private _slotURIs;
    mapping (address=>bool) public  KYC;
    address public OWNER;

    



    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within AssetData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    mapping(uint256 => uint256) public assetFractionalPriceUSD;

    AssetData[] public _allTokens;

    // key: id
    mapping(uint256 => uint256) public _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    IERC3525MetadataDescriptor public metadataDescriptor;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyKYC {
     require (KYC[msg.sender],"only KYC'd address can do this transaction");
     _;
    
    }
    modifier onlyOwner{
        require(msg.sender==OWNER,"only owner can do this transaction");
        _;
    }

    constructor() {
        _tokenIdGenerator = 1;
        _name = "RWA Token";
        _symbol = "RWT";
        _decimals = 18;
        OWNER=msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC3525).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC3525Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        _requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "ERC3525: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _setSlotURI(uint256 slot, string memory uri) internal {
    _slotURIs[slot] = uri;
    }


    function contractURI() public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructContractURI() :
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, "contract/", Strings.toHexString(address(this)))) : 
                    "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructSlotURI(slot_) : 
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, "slot/", slot_.toString())) : 
                    "";
    }

     function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC3525: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

  /*  function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC3525: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }*/

/*
function setTokenURI(uint256 tokenId_) public view returns (string memory) {
    return string(
        abi.encodePacked(
            '<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">',
            '<g>',
            // Black background on the left half
            '<rect width="300" height="600" fill="#000000"/>',

            // Solid green background on the right half
            '<rect x="300" width="300" height="600" fill="#00FF00"/>',

            // Token details on the black background
            '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="24" id="svg_2" y="340" x="350" stroke-width="0" stroke="#ffffff" fill="#ffffff">TokenId: ',
            tokenId_.toString(),
            '</text>',
            '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="24" id="svg_3" y="430" x="350" stroke-width="0" stroke="#ffffff" fill="#ffffff">Balance: ',
            balanceOf(tokenId_).toString(),
            '</text>',
            '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="24" id="svg_3" y="270" x="350" stroke-width="0" stroke="#ffffff" fill="#ffffff">Slot: ',
            slotOf(tokenId_).toString(),
            '</text>',
            '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="24" id="svg_4" y="160" x="300" stroke-width="0" stroke="#ffffff" fill="#ffffff">CHECK NFT</text>',
            '</g></svg>'
        )
    );
}
*/






function setTokenURI(uint256 tokenId) public view returns (bytes memory) {
    uint256 slot = slotOf(tokenId);
    uint256 bal = balanceOf(tokenId);

    // SVG content
    string memory svgContent = string(
        abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" style="background-color: #EAEAEA; border: 1px solid transparent; border-radius: 50px;">',
            
            '<text x="30" y="140" font-size="55" fill="#555">', bal.toString(), ' </text>',
            '<text x="30" y="200" font-size="30" fill="#555">#</text>',
            '<text x="50" y="200" font-size="30" fill="#555">', tokenId.toString(), '</text>',
            '<text x="30" y="310" font-size="20" fill="#555">Slot: ', slot.toString(), '</text>',
            '<text x="30" y="340" font-size="15" fill="#555">VIMAN NFT</text>',
            '</svg>'
        )
    );

    // Convert to bytes
    bytes memory svgBytes = bytes(svgContent);

    // Prefix with data URI scheme
    bytes memory svgData = abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svgBytes));

    return svgData;
}






  function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
            return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "VMANNFT #',
                                 tokenId_.toString(),
                                '", "description": "VMANNFT", "attributes": "", "image":"',
                                setTokenURI(tokenId_),
                            '"}'
                            )
                        )
                    )
                )
            );
}





    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        address owner = ERC3525.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: approve caller is not owner nor approved");

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function _addSlot(uint256 slot) private {
    if (_slotTotalValue[slot] == 0) {
        _allSlots.push(slot);
    }
    }

    function getAllSlots() public view returns (uint256[] memory) {
    return _allSlots;
    }

        // Function to set the price of a given assetId in USD by admin.
    function setAssetFractionalPriceUSD(uint256 _slotId, uint256 priceUSD) public {
        require(
            _slotExists(_slotId),
            "Asset doesn't exist"
        );

        assetFractionalPriceUSD[_slotId] = priceUSD;
    }

    // Function to get the price of a given assetId in USD.
    function getAssetFractionalPriceUSD(uint256 _slotId) public view returns (uint256) {
        require(
            _slotExists(_slotId),
            "LeasingContract: Nonexistent token"
        );

        return assetFractionalPriceUSD[_slotId];
    }



    function transferFrom (
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable onlyKYC virtual override returns (uint256 newTokenId)  {
        require(KYC[ERC3525.ownerOf(fromTokenId_)],"from token id owner is not kyc passed");
         require(KYC[to_],"the sender address is not kyc passed!");
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, ERC3525.slotOf(fromTokenId_), 0);
        _transferValue(fromTokenId_, newTokenId, value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable onlyKYC virtual override {
         require(KYC[ERC3525.ownerOf(fromTokenId_)]&&KYC[ERC3525.ownerOf(toTokenId_)],"from token id owner is not kyc passed");
        _spendAllowance(_msgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "ERC3525: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable onlyKYC virtual override {
        require(KYC[to_],"the sender address is not kyc passed!");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable onlyKYC virtual override {
        require(KYC[to_],"the sender address is not kyc passed!");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable onlyKYC virtual override {
        require(KYC[to_],"the sender address is not kyc passed!");
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override {
        address owner = ERC3525.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || ERC3525
.isApprovedForAll(owner, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525.totalSupply(), "ERC3525: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525.balanceOf(owner_), "ERC3525: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "ERC3525: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual returns (bool) {
        address owner = ERC3525.ownerOf(tokenId_);
        return (
            operator_ == owner ||
            ERC3525
.isApprovedForAll(owner, operator_) ||
            ERC3525
.getApproved(tokenId_) == operator_
        );
    }

    function _spendAllowance(address operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _slotExists(uint256 slot_) private view returns (bool) {
    for (uint i = 0; i < _allSlots.length; i++) {
        if (_allSlots[i] == slot_) {
            return true;
        }
    }
    return false;
}


    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "ERC3525: invalid token ID");
    }

    function registerAsset(address to_, uint256 slot_,string memory uri) public virtual returns (uint256 tokenId) {
        require(!_slotExists(slot_), "ERC3525: Asset already registered");
         if (bytes(_slotURIs[slot_]).length == 0) {
        _setSlotURI(slot_, uri);
    }
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_,0);  
        _addSlot(slot_);
        _setTokenURI(tokenId, _slotURIs[slot_]);
    }

    // function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual override {
    // super._mint(to_, tokenId_, value_);

    // // Set the URI for the newly minted token
    // _setTokenURI(tokenId_, _slotURIs[slot_]);
    // }

    function fractionalizeAsset(uint256 slot_, uint256 totalSupply_) public virtual  {
        require(_slotExists(slot_), "ERC3525: Asset not registered yet");
        // tokenId = _createOriginalTokenId();
        _slotValueCap[slot_] = totalSupply_;
    }

    function mintAsset(address to_, uint256 slot_, uint256 value_) public virtual returns (uint256 tokenId) {
        require(_slotExists(slot_), "ERC3525: Asset not registered yet");
        require(_slotTotalValue[slot_] + value_ <= _slotValueCap[slot_], "ERC3525: Tokens sold out");
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, value_); 
        _setTokenURI(tokenId, _slotURIs[slot_]);
        _slotTotalValue[slot_] += value_;
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal  virtual {
        require(to_ != address(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_)  internal  virtual {
        address owner = ERC3525.ownerOf(tokenId_);
        uint256 slot = ERC3525.slotOf(tokenId_);
        _beforeValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
    }

    function __mintValue(uint256 tokenId_, uint256 value_) private {
        _allTokens[_allTokensIndex[tokenId_]].balance += value_;
        emit TransferValue(0, tokenId_, value_);
    }

    function __mintToken(address to_, uint256 tokenId_, uint256 slot_) private {
         require(KYC[to_],"the sender address is not kyc passed!");
        
        AssetData memory assetData = AssetData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(assetData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        _requireMinted(tokenId_);

        AssetData storage assetData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = assetData.owner;
        uint256 slot = assetData.slot;
        uint256 value = assetData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, address(0), tokenId_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        _requireMinted(tokenId_);

        AssetData storage assetData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = assetData.owner;
        uint256 slot = assetData.slot;
        uint256 value = assetData.balance;

        require(value >= burnValue_, "ERC3525: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
        
        assetData.balance -= burnValue_;
        emit TransferValue(tokenId_, 0, burnValue_);
        
        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
    }

    function _addTokenToOwnerEnumeration(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function _addTokenToAllTokensEnumeration(AssetData memory assetData_) private {
        _allTokensIndex[assetData_.id] = _allTokens.length;
        _allTokens.push(assetData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        AssetData memory lastassetData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastassetData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastassetData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(address to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(ERC3525.ownerOf(tokenId_), to_, tokenId_);
    }

    function _approveValue(
        uint256 tokenId_,
        address to_,
        uint256 value_
    ) internal virtual {
        require(to_ != address(0), "ERC3525: approve value to the zero address");
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        AssetData storage assetData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = assetData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = assetData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
        delete assetData.valueApprovals;
    }

    function _existApproveValue(address to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal virtual {
        require(_exists(fromTokenId_), "ERC3525: transfer from invalid token ID");
        require(_exists(toTokenId_), "ERC3525: transfer to invalid token ID");

        AssetData storage fromAssetData = _allTokens[_allTokensIndex[fromTokenId_]];
        AssetData storage toAssetData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromAssetData.balance >= value_, "ERC3525: insufficient balance for transfer");
        require(fromAssetData.slot == toAssetData.slot, "ERC3525: transfer to token with different slot");

        _beforeValueTransfer(
            fromAssetData.owner,
            toAssetData.owner,
            fromTokenId_,
            toTokenId_,
            fromAssetData.slot,
            value_
        );

        fromAssetData.balance -= value_;
        toAssetData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromAssetData.owner,
            toAssetData.owner,
            fromTokenId_,
            toTokenId_,
            fromAssetData.slot,
            value_
        );

        require(
            _checkOnERC3525Received(fromTokenId_, toTokenId_, value_, ""),
            "ERC3525: transfer rejected by ERC3525Receiver"
        );
    }

    function _transferTokenId(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(ERC3525.ownerOf(tokenId_) == from_, "ERC3525: transfer from invalid owner");
        require(to_ != address(0), "ERC3525: transfer to the zero address");

        uint256 slot = ERC3525.slotOf(tokenId_);
        uint256 value = ERC3525.balanceOf(tokenId_);

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function _safeTransferTokenId(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transferTokenId(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "ERC3525: transfer to non ERC721Receiver"
        );
    }

    function _checkOnERC3525Received( 
        uint256 fromTokenId_, 
        uint256 toTokenId_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual returns (bool) {
        address to = ERC3525.ownerOf(toTokenId_);
        if (_isContract(to)) {
            try IERC165(to).supportsInterface(type(IERC3525Receiver).interfaceId) returns (bool retval) {
                if (retval) {
                    bytes4 receivedVal = IERC3525Receiver(to).onERC3525Received(_msgSender(), fromTokenId_, toTokenId_, value_, data_);
                    return receivedVal == IERC3525Receiver.onERC3525Received.selector;
                } else {
                    return true;
                }
            } catch (bytes memory /** reason */) {
                return true;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (_isContract(to_)) {
            try 
                IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /* solhint-disable */
    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}
    /* solhint-enable */

    function _setMetadataDescriptor(address metadataDescriptor_) internal virtual {
        metadataDescriptor = IERC3525MetadataDescriptor(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

    function _createOriginalTokenId() internal virtual returns (uint256) {
        return _tokenIdGenerator++;
    }

    function _createDerivedTokenId(uint256 fromTokenId_) internal virtual returns (uint256) {
        fromTokenId_;
        return _createOriginalTokenId();
    }

    function _isContract(address addr_) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr_)
        }
        return (size > 0);
    }

    function approveKYC(address user)public onlyOwner{
        require(!KYC[user],"users is alredy kyc aproved");
        KYC[user]=true;
    }
     function removeKYC(address user)public onlyOwner{
        require(KYC[user],"users  have no KYC yet");
        KYC[user]=false;
    }
}