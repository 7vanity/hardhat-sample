// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./TokenPair.sol";
import "hardhat/console.sol";

interface IuniswapV2Pair {
    function initPair(address, address) external;

    function getReserves()
    external
    returns (
        uint112,
        uint112,
        uint32
    );

    function mint(address) external returns (uint256);
    function burn(address) external returns (uint256, uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
   function swap(
        uint256,
        uint256,
        address
    ) external;

    function getToken0() external view returns (address);
    function getToken1() external view returns (address);

    function getTokenReserve(address token)
    external
    view
    returns (uint112);
}

contract uniswapV2Router {
   IuniswapV2Pair pair;
     constructor(address pairAddress) {
        pair = IuniswapV2Pair(pairAddress);
    }

//增加流动性
    function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) 

    public
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    )
    {
        if (pair.getToken0() == address(0) && pair.getToken1() == address(0)) {
            pair.initPair(tokenA, tokenB);
        }
        (amountA, amountB) = _calculateLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        _safeTransferFrom(tokenA, msg.sender, address(pair), amountA);
        _safeTransferFrom(tokenB, msg.sender, address(pair), amountB);
        liquidity = IuniswapV2Pair(pair).mint(to);
    }
//抽取流动性
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        IuniswapV2Pair(pair).transferFrom(msg.sender, address(pair), liquidity);
        (amountA, amountB) = IuniswapV2Pair(pair).burn(to);
        require(amountA >= amountAMin && amountA >= amountBMin, "InsufficientBAmount");
    }
//实现两种token交易
    function swapExactTokenForToken(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to
    ) public returns (uint256 amount) {

        console.log("amountIn", amountIn);
        amount = getAmountOut(
            amountIn,
            pair.getTokenReserve(tokenIn),
            pair.getTokenReserve(tokenOut)
        );
        require(amount >= amountOutMin, "InsufficientOutputAmount");
        _safeTransferFrom(
            tokenIn,
            msg.sender,
            address(pair),
            amountIn
        );
        if(tokenIn == pair.getToken0()) pair.swap(0, amount, to);
        if(tokenIn == pair.getToken1()) pair.swap(amount, 0, to);
    }

    function _calculateLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal > amountBMin, "InsufficientBAmount");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
 require(amountAOptimal > amountAMin, "InsufficientAAmount");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
//        (bool success, bytes memory data) = token.call(
//            abi.encodeWithSignature(
//                "transferFrom(address,address,uint256)",
//                from,
//                to,
//                value
//            )
//        );
//        require(success || (data.length == 0 && abi.decode(data, (bool))), "SafeTransferFailed");
        FT(token).transferFrom(from, to, value);
    }
//收取手续费
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn != 0, "InsufficientAmount");
    require(reserveIn != 0 && reserveOut != 0, "InsufficientLiquidity");
    uint amountInWithFee = amountIn.mul(997);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
}
  
    function getAmountIn(uint256 amountOut,uint256 reserveIn，uint256 reserveOut) public pure returns (uint256) {
        require(amountOut != 0, "InsufficientAmount");
        require(reserveIn != 0 && reserveOut != 0, "InsufficientLiquidity");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        return (numerator / denominator) + 1;
    }

    function quote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn != 0, "InsufficientAmount");
        require(reserveIn != 0 && reserveOut != 0, "InsufficientLiquidity");

        return (amountIn * reserveOut) / reserveIn;
    }
}