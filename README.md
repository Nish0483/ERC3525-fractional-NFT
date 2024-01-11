# About ERC3525

EIP-3525 is a token standard for semi-fungible tokens. It is the first standard where a token takes both the descriptive features of a non-fungible token (NFT) and the quantitative attributes of a fungible token (FT). In other words, ERC-3525 = ERC-20 quantitative operations + ERC-721 compatibility.

ERC-3525 extends the structure of ERC-721. Besides having tokenIds which differentiate each token, ERC-3525 introduces two new values — slot and value. All three attributions enable quantitive operations like dividing, combining, transferring, and comparing NFTs within the same slot.

* tokenId: from ERC-721, represents the nature of non-fungible tokens.

* slot: an attribute that is attached to each token, the same slot represents the same token attributions, allowing tokens with different tokenIds to be identified as identical. For example, if two bonds have the same issuance date, maturity date, and interest rate, then they will be assigned the same slot. So the two bonds can be divided or combined like one.

* value: the amount of the assets. For example, a $100 bond can be divided into two $50 bonds. 100 and 50 can represent the value of the assets being held.
The <ID, SLOT, VALUE> design allows quantitive operations like dividing, combining, transferring, and comparing the tokens within the same slot attribute. It is worth noting that ERC-3525 has backwards compatibility with ERC-721, which means ERC-3525 tokens can be used in all the infra that support ERC-721, and developers can switch to ERC-3525 without additional development.

### Why We Need ERC-3525
To understand why we need ERC-3525, here is a comparison with existing token standards:

* ERC-20: ERC-20 is the first token standard for Ethereum. Every token is fungible so the quantitative nature brings high liquidity and scalability. However, there is no tokenId property, so each contract can only represent one kind of asset.

* ERC-721: adds tokenId property so each token can represent different kinds of assets. But each token cannot be divided, merged, or represent quantitative value, so it is harder to quantify and manage when there is a need to split a token.

* ERC-1155: allows each token to be configurable on top of ERC-721, adding supply, metadata, and other attributes for each tokenId. The main use case of ERC-1155 is to distribute the same NFT with multiple supplies. However, the tokenId and supply of each NFT are fixed when minting, so tokens cannot be combined or merged and there is no backward compatibility with ERC-721.

* ERC-3525: maintains both features like ERC-20 and ERC-721. Tokens are non-fungible through slot and tokenId. And tokens can be very fungible with abilities to divide and merge. ERC-3525 solved the problems of ERC-1155 with trade-offs between ERC-721 and ERC-20.

### Use Cases of ERC-3525

* DeFi: the nature of ERC-3525 is suitable and compatible to be used in financial instruments like bonds, insurance policies, vesting plans, mortgages, etc. The splitting and combining features allow people to quantify tokens and increase flexibility in asset management. Financial instruments usually have various attributes, for example, there are different types of bonds with different issuance dates, maturity dates, interest rates… With ERC-3525, bonds with the same attributes (slot) can be split or combined by value transfer. The same applies to other financial instruments.
  
* GameFi: ERC-3525 can also be used to create and distribute virtual assets in games and metaverses. It can split gaming assets into smaller pieces. For example, a piece of virtual land can be split into pieces and owned by different guild members instead of held by one entity.


# About contract

* _name: The name of the token collection.
* _symbol: The symbol of the token collection.
* _decimals: The number of decimals for the fractional values.
* _tokenIdGenerator: The generator for creating unique token IDs.
* _approvedValues: Mapping of token IDs to approved values for specific addresses.
* _allTokens: An array containing information about all tokens.
* _allTokensIndex: Mapping of token IDs to their index in the _allTokens array.
* _addressData: Mapping of addresses to their owned tokens and approvals.
* metadataDescriptor: Instance of the metadata descriptor contract.

#### Structs

* TokenData: Represents the data associated with each token, including ID, slot, balance, owner, approved address, and value approvals.
* AddressData: Represents data associated with each address, including owned tokens and approvals.


## Functions

# Metadata Functions

* contractURI()
Returns the URI for the entire token collection.

~~~
function contractURI() public view virtual override returns (string memory)
~~~
slotURI(uint256 slot_)
Returns the URI for a specific slot within the token collection.

solidity
Copy code
function slotURI(uint256 slot_) public view virtual override returns (string memory)
tokenURI(uint256 tokenId_)
Returns the URI for a specific token.

solidity
Copy code
function tokenURI(uint256 tokenId_) public view virtual override returns (string memory)
Token Management Functions
balanceOf(uint256 tokenId_)
Returns the balance (fractional value) associated with a specific token.

solidity
Copy code
function balanceOf(uint256 tokenId_) public view virtual override returns (uint256)
ownerOf(uint256 tokenId_)
Returns the owner of a specific token.

solidity
Copy code
function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_)
slotOf(uint256 tokenId_)
Returns the slot associated with a specific token.

solidity
Copy code
function slotOf(uint256 tokenId_) public view virtual override returns (uint256)
transferFrom(uint256 fromTokenId_, address to_, uint256 value_)
Transfers a fractional value from one token to another.

solidity
Copy code
function transferFrom(uint256 fromTokenId_, address to_, uint256 value_) public payable virtual override returns (uint256 newTokenId)
transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_)
Transfers a fractional value from one token to another.

solidity
Copy code
function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override
balanceOf(address owner_)
Returns the balance (number of owned tokens) of a specific address.

solidity
Copy code
function balanceOf(address owner_) public view virtual override returns (uint256 balance)
transferFrom(address from_, address to_, uint256 tokenId_)
Transfers ownership of a specific token from one address to another.

solidity
Copy code
function transferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override
safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_)
Safely transfers ownership of a specific token from one address to another.

solidity
Copy code
function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public payable virtual override
safeTransferFrom(address from_, address to_, uint256 tokenId_)
Safely transfers ownership of a specific token from one address to another.

solidity
Copy code
function safeTransferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override
approve(address to_, uint256 tokenId_)
Approves another address to spend the fractional value of a specific token.

solidity
Copy code
function approve(address to_, uint256 tokenId_) public payable virtual override
getApproved(uint256 tokenId_)
Returns the address approved to spend the fractional value of a specific token.

solidity
Copy code
function getApproved(uint256 tokenId_) public view virtual override returns (address)
setApprovalForAll(address operator_, bool approved_)
Sets or unsets the approval of a specific address to spend the fractional values of all tokens owned by the sender.

solidity
Copy code
function setApprovalForAll(address operator_, bool approved_) public virtual override
isApprovedForAll(address owner_, address operator_)
Returns true if the specific address is approved to spend the fractional values of all tokens owned by the owner.

solidity
Copy code
function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool)
totalSupply()
Returns the total number of tokens in existence.

solidity
Copy code
function totalSupply() public view virtual override returns (uint256)
tokenByIndex(uint256 index_)
Returns the token ID at a specific index in the global tokens list.

solidity
Copy code
function tokenByIndex(uint256 index_) public view virtual override returns (uint256)
tokenOfOwnerByIndex(address owner_, uint256 index_)
Returns the token ID at a specific index in the tokens list of a specific owner.

solidity
Copy code
function tokenOfOwnerByIndex(address owner_, uint256 index_) public view virtual override returns (uint256)
Approval Functions
_approve(address to_, uint256 tokenId_)
Internal function to approve another address to spend the fractional value of a specific token.

solidity
Copy code
function _approve(address to_, uint256 tokenId_) public virtual
_approveValue(uint256 tokenId_, address to_, uint256 value_)
Internal function to approve another address to spend a specific fractional value of a specific token.

solidity
Copy code
function _approveValue(uint256 tokenId_, address to_, uint256 value_) public virtual
_clearApprovedValues(uint256 tokenId_)
Internal function to clear all approved values for a specific token.

solidity
Copy code
function _clearApprovedValues(uint256 tokenId_) public virtual
_existApproveValue(address to_, uint256 tokenId_)
Internal function to check if a specific address is approved to spend a specific fractional value of a token.

solidity
Copy code
function _existApproveValue(address to_, uint256 tokenId_) public view virtual returns (bool)
Value and Ownership Functions
_transferValue(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_)
Internal function to transfer a fractional value from one token to another.

solidity
Copy code
function _transferValue(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public virtual
_transferTokenId(address from_, address to_, uint256 tokenId_)
Internal function to transfer ownership of a specific token from one address to another.

solidity
Copy code
function _transferTokenId(address from_, address to_, uint256 tokenId_) public virtual
_safeTransferTokenId(address from_, address to_, uint256 tokenId_, bytes memory data_)
Internal function to safely transfer ownership of a specific token from one address to another.

solidity
Copy code
function _safeTransferTokenId(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual
_checkOnERC3525Received(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_, bytes memory data_)
Internal function to check if the receiving contract supports ERC3525Receiver and invoke its onERC3525Received function.

solidity
Copy code
function _checkOnERC3525Received(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_, bytes memory data_) public virtual returns (bool)
_checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_)
Internal function to check if the receiving contract supports ERC721Receiver and invoke its onERC721Received function.

solidity
Copy code
function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_) private returns (bool)
Hooks
Before Transfer Hooks
_beforeValueTransfer(address from_, address to_, uint256 fromTokenId_, uint256 toTokenId_, uint256 slot_, uint256 value_)
After Transfer Hooks
_afterValueTransfer(address from_, address to_, uint256 fromTokenId_, uint256 toTokenId_, uint256 slot_, uint256 value_)
Internal Functions
_mint(address to_, uint256 slot_, uint256 value_)
Internal function to mint a new token with a specific slot and value.

solidity
Copy code
function _mint(address to_, uint256 slot_, uint256 value_) public virtual returns (uint256 tokenId)
_mintValue(uint256 tokenId_, uint256 value_)
Internal function to update the fractional value of a specific token.

solidity
Copy code
function _mintValue(uint256 tokenId_, uint256 value_) public virtual
_mintToken(address to_, uint256 tokenId_, uint256 slot_)
Internal function to mint a new token with specific ID and slot.
