// TODO may need modify
pragma solidity ^0.8.4;

interface IiZiSwapMintCallback {

    function mintDepositCallback(
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

}

interface IiZiSwapCallback {
    function swapY2XCallback(
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
    function swapX2YCallback(
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
}

interface IiZiSwapAddLimOrderCallback {
    function payCallback(
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
}