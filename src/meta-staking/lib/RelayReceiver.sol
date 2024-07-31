// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

abstract contract RelayReceiver {
    address public immutable relayer;

    constructor(address _relayer) {
        relayer = _relayer;
    }

    function _msgSender() internal view returns (address) {
        if (msg.sender == relayer && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view returns (bytes calldata) {
        if (msg.sender == relayer && msg.data.length >= 20) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}