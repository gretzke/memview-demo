// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@summa-tx/memview.sol/contracts/TypedMemView.sol";
import "hardhat/console.sol";

/**
 * This library contains the data structure definitions and parser, validation and encoding functions for every data type
 * The data is always prefixed by a type identifier which is used to determine the type of encoded data, followed by the data in a predefined order
 * Here is an example of a message for an ERC1155 transfer with a 4 byte token id, 32 byte amound and 20 byte recipient address
 *
 * Data                   || Type.Send  ||  tokenId  |  amount  |  recipient  |
 * ====================== || ==================================================
 * Index (using `ref(0)`) || -- ignore - 0 --------- 4 -------- 36 --------- 56
 * ====================== || ==================================================
 * # of bytes             ||   1 byte   ||  4 bytes  | 32 bytes |   20 bytes  |
 */
library BridgeMessageLib {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    /**
     * Identifier for the type of message
     * When upgrading a contract the order of existing types should not be changed, new types should be appended
     */
    enum Types {
        INVALID,
        ERC20_TRANSFER,
        NFT_TRANSFER,
        CONTRACT_CALL
    }

    enum NFTTypes {
        ERC721,
        ERC1155
    }

    // helper constants for data validation
    uint256 private constant IDENTIFIER_LEN = 1;
    uint256 private constant ADDRESS_LEN = 20;
    uint256 private constant TOKEN_ID_LEN = 32;
    uint256 private constant AMOUNT_LEN = 32;
    uint256 private constant SELECTOR_LEN = 4;

    /// @notice Read the message identifer (first byte) of a message
    /// @param _view references the underlying bytes message
    function identifier(bytes29 _view) internal pure returns (uint8) {
        return uint8(_view.indexUint(0, 1));
    }

    /// @notice Returns the type of the message
    function messageType(bytes29 _view) internal pure returns (Types) {
        return Types(uint8(_view.typeOf()));
    }

    /// @notice Checks that the message is of the specified type
    function isType(bytes29 _view, Types _type) internal pure returns (bool) {
        return messageType(_view) == _type;
    }

    /// @notice Checks that the nested message is of the specified nft type
    function isNFTType(bytes29 _view, NFTTypes _type) internal pure returns (bool) {
        return NFTTypes(uint8(_view.typeOf())) == _type;
    }

    /// @notice Casts the view reference to the specified type
    function getTypedView(bytes29 _view) internal pure returns (bytes29) {
        Types _type = Types(identifier(_view));
        return _view.castTo(uint40(_type));
    }

    // ============ Formatters ============

    /// @notice Creates a serialized ERC20 transfer message
    function formatERC20Transfer(address recipient, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.ERC20_TRANSFER), recipient, amount);
    }

    /// @notice Creates a serialized ERC721 transfer message
    function formatERC721Transfer(address recipient, uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.NFT_TRANSFER), uint8(NFTTypes.ERC721), recipient, tokenId);
    }

    /// @notice Creates a serialized ERC1155 transfer message
    function formatERC1155Transfer(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.NFT_TRANSFER), uint8(NFTTypes.ERC1155), recipient, tokenId, amount);
    }

    /// @notice Creates a serialized smart contract call message
    function formatContractCall(bytes4 selector, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(Types.CONTRACT_CALL), selector, data);
    }

    // ============ Validators ============

    /// @notice Checks whether the view reference has the correct type and the data has the correct length
    function isValidERC20Transfer(bytes29 _view) internal pure returns (bool) {
        return isType(_view, Types.ERC20_TRANSFER) && _view.len() == IDENTIFIER_LEN + ADDRESS_LEN + AMOUNT_LEN;
    }

    function isValidNFTTransfer(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        return
            isType(_view, Types.NFT_TRANSFER) &&
            (length == IDENTIFIER_LEN * 2 + ADDRESS_LEN + TOKEN_ID_LEN ||
                length == IDENTIFIER_LEN * 2 + ADDRESS_LEN + TOKEN_ID_LEN + AMOUNT_LEN);
    }

    /// @notice Validates nested view reference
    function isValidERC721Transfer(bytes29 _view) internal pure returns (bool) {
        return isNFTType(_view, NFTTypes.ERC721) && _view.len() == IDENTIFIER_LEN + ADDRESS_LEN + TOKEN_ID_LEN;
    }

    /// @notice Validates nested view reference
    function isValidERC1155Transfer(bytes29 _view) internal pure returns (bool) {
        return
            isNFTType(_view, NFTTypes.ERC1155) &&
            _view.len() == IDENTIFIER_LEN + ADDRESS_LEN + TOKEN_ID_LEN + AMOUNT_LEN;
    }

    function isValidContractCall(bytes29 _view) internal pure returns (bool) {
        return isType(_view, Types.CONTRACT_CALL) && _view.len() >= IDENTIFIER_LEN + SELECTOR_LEN;
    }

    // ============ Parsers ============

    /// @notice Parses recipient and amount from a view reference
    function parseERC20Transfer(bytes29 _view) internal pure returns (address recipient, uint256 amount) {
        recipient = _view.indexAddress(IDENTIFIER_LEN);
        amount = _view.indexUint(IDENTIFIER_LEN + ADDRESS_LEN, uint8(AMOUNT_LEN));
    }

    /// @notice Returns nested data structure
    function parseNFTTransfer(bytes29 _view) internal pure returns (bytes29) {
        return _view.slice(IDENTIFIER_LEN, _view.len() - IDENTIFIER_LEN, 0);
    }

    function parseERC721Transfer(bytes29 _view) internal pure returns (address recipient, uint256 tokenId) {
        recipient = _view.indexAddress(IDENTIFIER_LEN);
        tokenId = _view.indexUint(IDENTIFIER_LEN + ADDRESS_LEN, uint8(TOKEN_ID_LEN));
    }

    function parseERC1155Transfer(
        bytes29 _view
    ) internal pure returns (address recipient, uint256 tokenId, uint256 amount) {
        recipient = _view.indexAddress(IDENTIFIER_LEN);
        tokenId = _view.indexUint(IDENTIFIER_LEN + ADDRESS_LEN, uint8(TOKEN_ID_LEN));
        amount = _view.indexUint(IDENTIFIER_LEN + ADDRESS_LEN + TOKEN_ID_LEN, uint8(AMOUNT_LEN));
    }

    /// @notice Parses arbitrary data from a view reference
    function parseContractCall(bytes29 _view) internal view returns (bytes4 selector, bytes memory data) {
        selector = bytes4(_view.index(IDENTIFIER_LEN, uint8(SELECTOR_LEN)));
        data = _view.slice(IDENTIFIER_LEN + SELECTOR_LEN, _view.len() - IDENTIFIER_LEN - SELECTOR_LEN, 0).clone();
    }
}
