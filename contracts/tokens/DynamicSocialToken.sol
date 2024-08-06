// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NovaroErrors} from "../libraries/NovaroErrors.sol";
import {NovaroDataTypes} from "../libraries/NovaroDataTypes.sol";
import {NovaroEvents} from"../libraries/NovaroEvents.sol";
import {IDynamicSocialToken} from "../interfaces/IDynamicSocialToken.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
/**
 * @title DynamicSocialToken
 * @dev This contract allows users to mint a DST when they bind their wallet.
 */
contract DynamicSocialToken is IDynamicSocialToken, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable {

    uint256 internal _tokenIdCounter;

    mapping(uint256 => NovaroDataTypes.DstData) internal _dstData;

    NovaroDataTypes.DstInterval[] internal _dstIntervals;

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return _dstData[tokenId].url;
    }

    function mint(address to, uint256 initialExp) external override returns (uint256) {
        if (to == address(0)) {
            revert NovaroErrors.InvalidAddress();
        }
        unchecked {
            _tokenIdCounter++;
            _safeMint(to, _tokenIdCounter);
            _feedDst(_tokenIdCounter, initialExp);
            return _tokenIdCounter;
        }
    }

    function readInterval(NovaroDataTypes.DstInterval[] memory intervals) external {
        delete _dstIntervals;
        uint256 length = intervals.length;
        if (length == 0) {
            revert NovaroErrors.EmptyInterval();
        }
        for (uint256 i = 0; i < length; i++) {
            _dstIntervals.push(intervals[i]);
        }
        emit NovaroEvents.ReadInterval(length);
    }

    function _locateMetadata(uint256 tokenId) internal view returns (uint256 lv, string memory url) {
        uint256 length = _dstIntervals.length;
        if (length == 0) {
            revert NovaroErrors.IntervalNotSet();
        }
        uint256 exp = _dstData[tokenId].exp;
        for (uint256 i = 0; i < length - 1; i++) {
            NovaroDataTypes.DstInterval memory interval = _dstIntervals[i];
            if (exp > interval.left && exp <= interval.right) {
                return (interval.lv, interval.url);
            }
        }
        return (_dstIntervals[length - 1].lv, _dstIntervals[length - 1].url);
    }

    function onChainFeed(uint256 tokenId, uint256 amount) external {
        _feedDst(tokenId, amount);
        emit NovaroEvents.OnChainFeed(tokenId, amount);

    }

    function offChainFeed(uint256 tokenId, uint256 amount) external {
        _feedDst(tokenId, amount);
        emit NovaroEvents.OffChainFeed(tokenId, amount);
    }

    function _feedDst(uint256 tokenId, uint256 amount) internal {
        NovaroDataTypes.DstData storage dstData = _dstData[tokenId];
        dstData.exp += amount;
        (dstData.lv, dstData.url) = _locateMetadata(tokenId);
        _setTokenURI(tokenId, dstData.url);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return ERC721URIStorageUpgradeable.supportsInterface(interfaceId);
    }

}
