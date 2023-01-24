// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./Math.sol";
import './FT.sol';
import "hardhat/console.sol";


contract uniswapV2Pair is FT, Math {

    uint256 constant MINIMUM_LIQUIDITY = 10;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    bool private isEntered;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address to
    );
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(
        address indexed sender,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    modifier nonReentrant() {
        require(!isEntered);
        isEntered = true;

        _;

        isEntered = false;
    }

    constructor() FT("uniswapV2 Pair", "UNIV2") {}

    function initPair(address token0_, address token1_) public {
        require(token0 == address(0) && token1 == address(0), " This pair already Initialized");
        token0 = token0_;
        token1 = token1_;
    }

    function mint(address to) public returns (uint256 liquidity) {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0_,
                (amount1 * totalSupply()) / reserve1_
            );
        }
 require(liquidity > 0, "InsufficientLiquidityMinted");

        _mint(to, liquidity);

        _update(balance0, balance1);

        emit Mint(to, amount0, amount1);
    }

    function burn(address to)
    public
    returns (uint256 amount0, uint256 amount1)
    {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        amount0 = (liquidity * balance0) / totalSupply();
        amount1 = (liquidity * balance1) / totalSupply();

        require(amount0 != 0 && amount1 != 0, "InsufficientLiquidityBurned");

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);

    emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) public nonReentrant {
        require(amount0Out != 0 || amount1Out != 0, "InsufficientOutputAmount");

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        require(amount0Out <= reserve0_ && amount1Out <= reserve1_, "InsufficientLiquidity");

        if (amount0Out > 0) {
            _safeTransfer(token0, to, amount0Out);
        }
        if (amount1Out > 0) {
            _safeTransfer(token1, to, amount1Out);
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > reserve0 - amount0Out
        ? balance0 - (reserve0 - amount0Out)
        : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out
        ? balance1 - (reserve1 - amount1Out)
        : 0;

        require(amount0In != 0 || amount1In != 0, "InsufficientInputAmount");

        // Adjusted = balance before swap - swap fee; fee stays in the contract
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        require(
            balance0Adjusted * balance1Adjusted >=
            uint256(reserve0_) * uint256(reserve1_) * (1000**2), "InvalidK");

        _update(balance0, balance1);

        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    function getReserves()
    public
    view
    returns (
        uint112,
        uint112,
        uint32
    )
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function getTokenReserve(address token)
    external
    view
    returns (uint112)
    {
        if(token == token0) return reserve0;
        if(token == token1) return reserve1;
        return 0;
    }

    function getToken0() external view returns (address) {
        return token0;
    }

    function getToken1() external view returns (address) {
        return token1;
    }
function _update(
        uint256 balance0,
        uint256 balance1
    ) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "BalanceOverflow");

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        require(success || (data.length == 0 && abi.decode(data, (bool))), "TransferFailed");
    }
}