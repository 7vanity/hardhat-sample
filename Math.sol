// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Math {
    function min(uint256 m, uint256 n) internal pure returns (uint256) {
        return m < n ? m : n;
    }
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
