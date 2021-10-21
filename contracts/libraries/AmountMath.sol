pragma solidity >=0.7.3;

import './FullMath.sol';
import './FixedPoint96.sol';
import './TickMath.sol';

library AmountMath {


    function getAmountY(
        uint128 liquidity,
        uint160 sqrtPriceL_96,
        uint160 sqrtPriceR_96,
        uint160 sqrtRate_96,
        bool upper
    ) internal pure returns (uint256 amount) {
        uint160 numerator = sqrtPriceR_96 - sqrtPriceL_96;
        uint160 denominator = sqrtRate_96 - uint160(FixedPoint96.Q96);
        if (!upper) {
            amount = FullMath.mulDiv(liquidity, numerator, denominator);
        } else {
            amount = FullMath.mulDivRoundingUp(liquidity, numerator, denominator);
        }
    }

    function getAmountX(
        uint128 liquidity,
        int24 leftPt,
        int24 rightPt,
        uint160 sqrtPriceR_96,
        uint160 sqrtRate_96,
        bool upper
    ) internal pure returns (uint256 amount) {
        // rightPt - (leftPt - 1), pc = leftPt - 1
        uint160 sqrtPricePrPc_96 = TickMath.getSqrtRatioAtTick(rightPt - leftPt + 1);
        uint160 sqrtPricePrPd_96 = TickMath.getSqrtRatioAtTick(rightPt + 1);

        uint160 numerator = sqrtPricePrPc_96 - sqrtRate_96;
        uint160 denominator = sqrtPricePrPd_96 - sqrtPriceR_96;
        if (!upper) {
            amount = FullMath.mulDiv(liquidity, numerator, denominator);
        } else {
            amount = FullMath.mulDivRoundingUp(liquidity, numerator, denominator);
        }
    }

}