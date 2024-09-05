// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NovaroErrors {
    error InvalidAddress();
    error TransferNotAllowed();
    error EmptyInterval();
    error IntervalNotSet();
    error AddressHasToken();
    error TokenNotMinted();
    error AlreadyBoundDST();
    error AlreadyTransferDST();
    error DSTNotMinted();
}
