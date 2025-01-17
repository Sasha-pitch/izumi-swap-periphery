const { ethers } = require("hardhat");
const BigNumber = require('bignumber.js');

function stringMinus(a, b) {
    return BigNumber(a).minus(b).toFixed(0);
}

function stringMul(a, b) {
    const mul = BigNumber(a).times(b).toFixed(0);
    return mul;
}

function stringDiv(a, b) {
    let an = BigNumber(a);
    an = an.minus(an.mod(b));
    return an.div(b).toFixed(0);
}

function stringMod(a, b) {
    let an = BigNumber(a);
    an = an.mod(b);
    return an.toFixed(0);
}

function stringDivCeil(a, b) {
    const div = stringDiv(a, b);
    if (stringMod(a, b) === '0') {
        return div;
    }
    return stringAdd(div, '1');
}

function stringAdd(a, b) {
    return BigNumber(a).plus(b).toFixed(0);
}

function stringLess(a, b) {
    return BigNumber(a).lt(b);
}

async function getIzumiswapFactory(receiverAddr, swapX2YModule, swapY2XModule, liquidityModule, limitOrderModule, signer) {
    const iZiSwapJson = getContractJson(__dirname + '/core/iZiSwapFactory.json');
    
    const iZiSwapFactory = await ethers.getContractFactory(iZiSwapJson.abi, iZiSwapJson.bytecode, signer);

    const factory = await iZiSwapFactory.deploy(receiverAddr, swapX2YModule, swapY2XModule, liquidityModule, limitOrderModule);
    await factory.deployed();

    await factory.enableFeeAmount(3000, 50);
    return factory;
}


function getContractJson(path) {
    const fs = require('fs');
    let rawdata = fs.readFileSync(path);
    let data = JSON.parse(rawdata);
    return data;
}

async function getPoolParts(signer) {
    const swapX2YModuleJson = getContractJson(__dirname + '/core/SwapX2YModule.json');
    const SwapX2YModuleFactory = await ethers.getContractFactory(swapX2YModuleJson.abi, swapX2YModuleJson.bytecode, signer);
    const swapX2YModule = await SwapX2YModuleFactory.deploy();
    await swapX2YModule.deployed();
    
    const swapY2XModuleJson = getContractJson(__dirname + '/core/SwapY2XModule.json');
    const SwapY2XModuleFactory = await ethers.getContractFactory(swapY2XModuleJson.abi, swapY2XModuleJson.bytecode, signer);
    const swapY2XModule = await SwapY2XModuleFactory.deploy();
    await swapY2XModule.deployed();
  
    const liquidityModuleJson = getContractJson(__dirname + '/core/LiquidityModule.json');
    const LiquidityModuleFactory = await ethers.getContractFactory(liquidityModuleJson.abi, liquidityModuleJson.bytecode, signer);
    const liquidityModule = await LiquidityModuleFactory.deploy();
    await liquidityModule.deployed();
  
    const limitOrderModuleJson = getContractJson(__dirname + '/core/LimitOrderModule.json');
    const LimitOrderModuleFactory = await ethers.getContractFactory(limitOrderModuleJson.abi, limitOrderModuleJson.bytecode, signer);
    const limitOrderModule = await LimitOrderModuleFactory.deploy();
    await limitOrderModule.deployed();
    return {
      swapX2YModule: swapX2YModule.address,
      swapY2XModule: swapY2XModule.address,
      liquidityModule: liquidityModule.address,
      limitOrderModule: limitOrderModule.address,
    };
  }


async function getLimOrder(poolAddr, pt) {
    const iZiSwapPool = await ethers.getContractFactory("iZiSwapPool");
    pool = await iZiSwapPool.attach(poolAddr);
    const {sellingX, accEarnX, sellingY, accEarnY, earnX, earnY} = await pool.limitOrderData(pt);
    return {
        sellingX: BigNumber(sellingX._hex),
        accEarnX: BigNumber(accEarnX._hex),
        sellingY: BigNumber(sellingY._hex),
        accEarnY: BigNumber(accEarnY._hex),
        earnX: BigNumber(earnX._hex),
        earnY: BigNumber(earnY._hex)
    }
}

function floor(a) {
    return a.toFixed(0, 3);
}
function ceil(b) {
    return b.toFixed(0, 2);
}
function getAcquiredFee(amount, chargePercent = 50) {
    const originFee = ceil(BigNumber(amount).times(3).div(997));
    const charged = floor(BigNumber(originFee).times(chargePercent).div(100));
    return BigNumber(originFee).minus(charged).toFixed(0);
}

function getFeeCharge(fee, chargePercent = 50) {
    return floor(BigNumber(fee).times(chargePercent).div('100'));
}

function yInRange(liquidity, pl, pr, rate, up) {
    let amountY = BigNumber("0");
    let price = BigNumber(rate).pow(pl);
    for (var i = pl; i < pr; i ++) {
        amountY = amountY.plus(BigNumber(liquidity).times(price.sqrt()));
        price = price.times(rate);
    }
    if (up) {
        return ceil(amountY);
    } else {
        return floor(amountY);
    }
}
function xInRange(liquidity, pl, pr, rate, up) {
    let amountX = BigNumber("0");
    let price = BigNumber(rate).pow(pl);
    for (var i = pl; i < pr; i ++) {
        amountX = amountX.plus(BigNumber(liquidity).div(price.sqrt()));
        price = price.times(rate);
    }
    if (up) {
        return ceil(amountX);
    } else {
        return floor(amountX);
    }
}

function getYRangeList(rangeList, rate, up) {
    const amountY = [];
    for (const range of rangeList) {
        amountY.push(yInRange(range.liquidity, range.pl, range.pr, rate, up));
    }
    return amountY;
}
function getXRangeList(rangeList, rate, up) {
    const amountX = [];
    for (const range of rangeList) {
        amountX.push(xInRange(range.liquidity, range.pl, range.pr, rate, up));
    }
    return amountX;
}

function y2xAt(point, rate, amountY) {
    const sp = rate.pow(point).sqrt();
    const liquidity = floor(BigNumber(amountY).div(sp));
    const acquireX = floor(BigNumber(liquidity).div(sp));
    const liquidity1 = ceil(BigNumber(acquireX).times(sp));
    const costY = ceil(BigNumber(liquidity1).times(sp));
    return [acquireX, costY];
}

function getCostYFromXAt(sqrtPrice_96, acquireX) {
    const q96 = BigNumber(2).pow(96).toFixed(0);

    const liquidity = stringDivCeil(stringMul(acquireX, sqrtPrice_96), q96);
    const costY = stringDivCeil(stringMul(liquidity, sqrtPrice_96), q96);

    return costY;
}

function acquiredFeeLiquidity(amount, feeTier=3000, chargePercent=50) {

    const fee = stringDivCeil(stringMul(amount, feeTier), stringMinus(1e6, feeTier));
    return stringMinus(fee, getFeeCharge(fee, chargePercent));
}

function amountAddFee(amount, feeTier=3000) {
    const fee = stringDivCeil(stringMul(amount, feeTier), stringMinus(1e6, feeTier));
    return stringAdd(amount, fee);
}


function l2x(liquidity, sqrtPrice_96, up) {
    const q96 = BigNumber(2).pow(96).toFixed(0);
    if (up) {
        return stringDivCeil(stringMul(liquidity, q96), sqrtPrice_96)
    } else {
        return stringDiv(stringMul(liquidity, q96), sqrtPrice_96)
    }
}

function l2y(liquidity, sqrtPrice_96, up) {
    const q96 = BigNumber(2).pow(96).toFixed(0);
    if (up) {
        return stringDivCeil(stringMul(liquidity, sqrtPrice_96), q96)
    } else {
        return stringDiv(stringMul(liquidity, sqrtPrice_96), q96)
    }
}

module.exports ={
    getPoolParts,
    getIzumiswapFactory,
    getLimOrder,
    getAcquiredFee,
    getFeeCharge,
    getYRangeList,
    getXRangeList,
    xInRange,
    yInRange,
    y2xAt,
    getCostYFromXAt,
    acquiredFeeLiquidity,
    amountAddFee,
    l2x,
    l2y
}