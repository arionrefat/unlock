// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title The PublicLock Interface
 */

interface IPublicLockV15 {
  /**
   * @dev PurchaseArgs struct
   * @param value (ERC20 only) value of the key
   * @param recipient address of the recipient
   * @param referrer the referrer that will be granted the governance tokens
   * @param keyManager the manager of the key (can cancel, transfer, burn the key)
   * @param data additional data to be used by jooks or other 3rd part contracts
   */

  struct PurchaseArgs {
    uint value;
    address recipient;
    address referrer;
    address protocolReferrer;
    address keyManager;
    bytes data;
    uint additionalPeriods;
  }

  /// Functions
  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

  // default role from OpenZeppelin
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32 role);

  /**
   * @notice The version number of the current implementation on this network.
   * @return The current version number.
   */
  function publicLockVersion() external pure returns (uint16);

  /**
   * @dev Called by lock manager to withdraw all funds from the lock
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _recipient specifies the address that will receive the tokens
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   * -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor` use cases.
   */
  function withdraw(
    address _tokenAddress,
    address payable _recipient,
    uint _amount
  ) external;

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing(uint _keyPrice, address _tokenAddress) external;

  /**
   * Update the main key properties for the entire lock:
   *
   * - default duration of each key
   * - the maximum number of keys the lock can edit
   * - the maximum number of keys a single address can hold
   *
   * @notice keys previously bought are unaffected by this changes in expiration duration (i.e.
   * existing keys timestamps are not recalculated/updated)
   * @param _newExpirationDuration the new amount of time for each key purchased or type(uint).max for a non-expiring key
   * @param _maxKeysPerAcccount the maximum amount of key a single user can own
   * @param _maxNumberOfKeys uint the maximum number of keys
   * @dev _maxNumberOfKeys Can't be smaller than the existing supply
   */
  function updateLockConfig(
    uint _newExpirationDuration,
    uint _maxNumberOfKeys,
    uint _maxKeysPerAcccount
  ) external;

  /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(address _user) external view returns (bool);

  /**
   * @dev Returns the key's ExpirationTimestamp field for a given owner.
   * @param _tokenId the id of the key
   * @dev Returns 0 if the owner has never owned a key for this lock
   */
  function keyExpirationTimestampFor(
    uint _tokenId
  ) external view returns (uint timestamp);

  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows the Lock owner to assign
   * @param _lockName a descriptive name for this Lock.
   * @param _lockSymbol a Symbol for this Lock (default to KEY).
   * @param _baseTokenURI the baseTokenURI for this Lock
   */
  function setLockMetadata(
    string calldata _lockName,
    string calldata _lockSymbol,
    string calldata _baseTokenURI
  ) external;

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory);

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(uint256 _tokenId) external view returns (string memory);

  /**
   * Allows a Lock manager to add or remove an event hook
   * @param _onKeyPurchaseHook Hook called when the `purchase` function is called
   * @param _onKeyCancelHook Hook called when the internal `_cancelAndRefund` function is called
   * @param _onValidKeyHook Hook called to determine if the contract should overide the status for a given address
   * @param _onTokenURIHook Hook called to generate a data URI used for NFT metadata
   * @param _onKeyTransferHook Hook called when a key is transfered
   * @param _onKeyExtendHook Hook called when a key is extended or renewed
   * @param _onKeyGrantHook Hook called when a key is granted
   * @param _onHasRoleHook Hook called when checking if an address as a specific role
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook,
    address _onValidKeyHook,
    address _onTokenURIHook,
    address _onKeyTransferHook,
    address _onKeyExtendHook,
    address _onKeyGrantHook,
    address _onHasRoleHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   * @return the ids of the granted tokens
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external returns (uint256[] memory);

  /**
   * Allows the Lock owner to extend an existing keys with no charge.
   * @param _tokenId The id of the token to extend
   * @param _duration The duration in secondes to add ot the key
   * @dev set `_duration` to 0 to use the default duration of the lock
   */
  function grantKeyExtension(uint _tokenId, uint _duration) external;

  /**
   * @dev Purchase function
   * @param purchaseArgs array of PurchaseArg
   * @return tokenIds the ids of the created tokens
   */
  function purchase(
    PurchaseArgs[] memory purchaseArgs
  ) external payable returns (uint256[] memory tokenIds);

  /**
   * @dev Purchase function (legacy)
   * @param _values array of tokens amount to pay for this purchase >= the current keyPrice - any applicable discount
   * (_values is ignored when using ETH)
   * @param _recipients array of addresses of the recipients of the purchased key
   * @param _referrers array of addresses of the users making the referral
   * @param _keyManagers optional array of addresses to grant managing rights to a specific address on creation
   * @param _data array of arbitrary data populated by the front-end which initiated the sale
   * @notice when called for an existing and non-expired key, the `_keyManager` param will be ignored
   * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if the lock owner increases the
   * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
   * than keyPrice is approved for spending).
   * @return tokenIds the ids of the created tokens
   */
  function purchase(
    uint256[] calldata _values,
    address[] calldata _recipients,
    address[] calldata _referrers,
    address[] calldata _keyManagers,
    bytes[] calldata _data
  ) external payable returns (uint256[] memory tokenIds);

  /**
   * @dev Extend function
   * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
   * (_value is ignored when using ETH)
   * @param _tokenId the id of the key to extend
   * @param _referrer address of the user making the referral
   * @param _data arbitrary data populated by the front-end which initiated the sale
   * @dev Throws if lock is disabled or key does not exist for _recipient. Throws if _recipient == address(0).
   */
  function extend(
    uint _value,
    uint _tokenId,
    address _referrer,
    bytes calldata _data
  ) external payable;

  /**
   * Returns the percentage of the keyPrice to be sent to the referrer (in basis points)
   * @param _referrer the address of the referrer
   * @return referrerFee the percentage of the keyPrice to be sent to the referrer (in basis points)
   */
  function referrerFees(
    address _referrer
  ) external view returns (uint referrerFee);

  /**
   * Set a specific percentage of the keyPrice to be sent to the referrer while purchasing,
   * extending or renewing a key.
   * @param _referrer the address of the referrer
   * @param _feeBasisPoint the percentage of the price to be used for this
   * specific referrer (in basis points)
   * @dev To send a fixed percentage of the key price to all referrers, sett a percentage to `address(0)`
   */
  function setReferrerFee(address _referrer, uint _feeBasisPoint) external;

  /**
   * Merge existing keys
   * @param _tokenIdFrom the id of the token to substract time from
   * @param _tokenIdTo the id of the destination token  to add time
   * @param _amount the amount of time to transfer (in seconds)
   */
  function mergeKeys(uint _tokenIdFrom, uint _tokenIdTo, uint _amount) external;

  /**
   * Deactivate an existing key
   * @param _tokenId the id of token to burn
   * @notice the key will be expired and ownership records will be destroyed
   */
  function burn(uint _tokenId) external;

  /**
   * @param _gasRefundValue price in wei or token in smallest price unit
   * @dev Set the value to be refunded to the sender on purchase
   */
  function setGasRefundValue(uint256 _gasRefundValue) external;

  /**
   * _gasRefundValue price in wei or token in smallest price unit
   * @dev Returns the value/price to be refunded to the sender on purchase
   */
  function gasRefundValue() external view returns (uint256 _gasRefundValue);

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view returns (uint);

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(uint _transferFeeBasisPoints) external;

  /**
   * Determines how much of a fee would need to be paid in order to
   * transfer to another account.  This is pro-rated so the fee goes
   * down overtime.
   * @dev Throws if _tokenId does not have a valid key
   * @param _tokenId The id of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    uint _tokenId,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key
   * and perform a refund and cancellation of the key
   * @param _tokenId The key id we wish to refund to
   * @param _amount The amount to refund to the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(uint _tokenId, uint _amount) external;

  /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   * @notice cancel is enabled with a 10% penalty by default on all Locks.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * Allow a Lock manager to change the refund penalty.
   * @dev Throws if called by other than a Lock manager
   * @param _freeTrialLength The new duration of free trials for this lock
   * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _tokenId the id of the token to get the refund value for.
   * @notice Due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   * @return refund the amount of tokens refunded
   */
  function getCancelAndRefundValue(
    uint _tokenId
  ) external view returns (uint refund);

  function isLockManager(address account) external view returns (bool);

  /**
   * Returns the address of the `onKeyPurchaseHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyPurchaseHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onKeyCancelHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyCancelHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onValidKeyHook` hook.
   * @return hookAddress address of the hook
   */
  function onValidKeyHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onTokenURIHook` hook.
   * @return hookAddress address of the hook
   */
  function onTokenURIHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onKeyTransferHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyTransferHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onKeyExtendHook` hook.
   * @return hookAddress the address ok the hook
   */
  function onKeyExtendHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onKeyGrantHook` hook.
   * @return hookAddress the address ok the hook
   */
  function onKeyGrantHook() external view returns (address hookAddress);

  /**
   * Returns the address of the `onHasRoleHook` hook.
   * @return hookAddress the address ok the hook
   */
  function onHasRoleHook() external view returns (address hookAddress);

  /**
   * @return the maximum number of key allowed for a single address
   */
  function maxKeysPerAddress() external view returns (uint);

  function expirationDuration() external view returns (uint256);

  function freeTrialLength() external view returns (uint256);

  function keyPrice() external view returns (uint256);

  function maxNumberOfKeys() external view returns (uint256);

  function refundPenaltyBasisPoints() external view returns (uint256);

  function tokenAddress() external view returns (address);

  function transferFeeBasisPoints() external view returns (uint256);

  function unlockProtocol() external view returns (address);

  function keyManagerOf(uint) external view returns (address);

  ///===================================================================

  /**
   * @notice Allows the key owner to safely share their key (parent key) by
   * transferring a portion of the remaining time to a new key (child key).
   * @dev Throws if key is not valid.
   * @dev Throws if `_to` is the zero address
   * @param _to The recipient of the shared key
   * @param _tokenId the key to share
   * @param _timeShared The amount of time shared
   * checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
   * @dev Emit Transfer event
   */
  function shareKey(address _to, uint _tokenId, uint _timeShared) external;

  /**
   * @notice Update transfer and cancel rights for a given key
   * @param _tokenId The id of the key to assign rights for
   * @param _keyManager The address to assign the rights to for the given key
   */
  function setKeyManagerOf(uint _tokenId, address _keyManager) external;

  /**
   * Check if a certain key is valid
   * @param _tokenId the id of the key to check validity
   * @notice this makes use of the onValidKeyHook if it is set
   */
  function isValidKey(uint _tokenId) external view returns (bool);

  /**
   * Returns the number of keys owned by `_keyOwner` (expired or not)
   * @param _keyOwner address for which we are retrieving the total number of keys
   * @return numberOfKeys total number of keys owned by the address
   */
  function totalKeys(
    address _keyOwner
  ) external view returns (uint numberOfKeys);

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);

  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  ///===================================================================

  /// From ERC-721
  /**
   * In the specific case of a Lock, `balanceOf` returns only the tokens with a valid expiration timerange
   * @return balance The number of valid keys owned by `_keyOwner`
   */
  function balanceOf(address _owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address _owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * `approve`
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * an ERC721-like function to transfer a token from one account to another.
   * @param from the owner of token to transfer
   * @param to the address that will receive the token
   * @param tokenId the id of the token
   * @dev Requirements: if the caller is not `from`, it must be approved to move this token by
   * `approve`
   * The key manager will be reset to address zero after the transfer
   */
  function transferFrom(address from, address to, uint256 tokenId) external;

  /**
   * Lending a key allows you to transfer the token while retaining the
   * ownerships right by setting yourself as a key manager first.
   * @param from the owner of token to transfer
   * @param to the address that will receive the token
   * @param tokenId the id of the token
   * @notice This function can only be called by 1) the key owner when no key manager is set or 2) the key manager.
   * After calling the function, the `_recipent` will be the new owner, and the sender of the tx
   * will become the key manager.
   */
  function lendKey(address from, address to, uint tokenId) external;

  /**
   * Unlend is called when you have lent a key and want to claim its full ownership back.
   * @param _recipient the address that will receive the token ownership
   * @param _tokenId the id of the token
   * @dev Only the key manager of the token can call this function
   */
  function unlendKey(address _recipient, uint _tokenId) external;

  function approve(address to, uint256 tokenId) external;

  /**
   * @notice Get the approved address for a single NFT
   * @dev Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for
   * @return operator The approved address for this NFT, or the zero address if there is none
   */
  function getApproved(
    uint256 _tokenId
  ) external view returns (address operator);

  /**
   * Returns the total number of keys, including non-valid ones
   * @return _totalKeysCreated the total number of keys, valid or not
   */
  function totalSupply() external view returns (uint256 _totalKeysCreated);

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 index
  ) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * Innherited from Open Zeppelin AccessControl.sol
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  /** `owner()` is provided as an helper to mimick the `Ownable` contract ABI.
   * The `Ownable` logic is used by many 3rd party services to determine
   * contract ownership - e.g. who is allowed to edit metadata on Opensea.
   *
   * @notice This logic is NOT used internally by the Unlock Protocol and is made
   * available only as a convenience helper.
   */
  function owner() external view returns (address owner);

  function setOwner(address account) external;

  function isOwner(address account) external view returns (bool isOwner);

  /**
   * Migrate data from the previous single owner => key mapping to
   * the new data structure w multiple tokens.
   * @param _calldata an ABI-encoded representation of the params (v10: the number of records to migrate as `uint`)
   * @dev when all record schemas are sucessfully upgraded, this function will update the `schemaVersion`
   * variable to the latest/current lock version
   */
  function migrate(bytes calldata _calldata) external;

  /**
   * Renew a given token
   * @notice only works for non-free, expiring, ERC20 locks
   * @param _tokenId the ID fo the token to renew
   * @param _referrer the address of the person to be granted UDT
   */
  function renewMembershipFor(uint _tokenId, address _referrer) external;

  /**
   * Set the expiration of a key
   * @notice only a lock manager can call this function
   * @param _tokenId the id of the key
   * @param _newExpiration the new timestamp to use
   */
  function setKeyExpiration(uint _tokenId, uint _newExpiration) external;

  /**
   * @dev helper to check if a key is currently renewable
   * it will revert if the pricing or duration of the lock have been modified
   * unfavorably since the key was bought(price increase or duration decrease).
   * It will also revert if a lock is not renewable or if the key is not ready for renewal yet
   * (at least 90% expired).
   * @param tokenId the id of the token to check
   * @param referrer the address where to send the referrer fee
   * @return true if the terms has changed
   */
  function isRenewable(
    uint256 tokenId,
    address referrer
  ) external view returns (bool);
}
