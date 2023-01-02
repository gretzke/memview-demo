// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import "@summa-tx/memview.sol/contracts/TypedMemView.sol";
import "./BridgeMessage.sol";

contract BridgeContract {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using BridgeMessageLib for bytes29;

    event ERC20Transfer(address recipient, uint256 amount);
    event ERC721Transfer(address recipient, uint256 tokenId);
    event ERC1155Transfer(address recipient, uint256 tokenId, uint256 amount);
    event ContractCall(bytes4 selector, bytes data);

    function processMessage(bytes calldata message) external {
        bytes29 _view = message.ref(0).getTypedView();

        if (_view.isValidERC20Transfer()) {
            _handleERC20Transfer(_view);
        } else if (_view.isValidNFTTransfer()) {
            _handleNFTTransfer(_view);
        } else if (_view.isValidContractCall()) {
            _handleContractCall(_view);
        } else {
            revert("Invalid message");
        }
    }

    function _handleERC20Transfer(bytes29 _view) private {
        (address recipient, uint256 amount) = _view.parseERC20Transfer();
        // TODO handle transfer
        emit ERC20Transfer(recipient, amount);
    }

    function _handleNFTTransfer(bytes29 _view) private {
        bytes29 nftView = _view.parseNFTTransfer().getTypedView();
        if (nftView.isValidERC721Transfer()) {
            (address recipient, uint256 tokenId) = nftView.parseERC721Transfer();
            // TODO handle transfer
            emit ERC721Transfer(recipient, tokenId);
        } else if (nftView.isValidERC1155Transfer()) {
            (address recipient, uint256 tokenId, uint256 amount) = nftView.parseERC1155Transfer();
            // TODO handle transfer
            emit ERC1155Transfer(recipient, tokenId, amount);
        } else {
            revert("Invalid nft message");
        }
    }

    function _handleContractCall(bytes29 _view) private {
        (bytes4 selector, bytes memory data) = _view.parseContractCall();
        // TODO handle call
        emit ContractCall(selector, data);
    }
}
