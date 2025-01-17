pragma solidity ^0.8.4;

interface IiZiSwapPool {

    /// @notice Emitted when miner successfully add liquidity (mint)
    /// @param sender The address that minted the liquidity
    /// @param owner The owner who will benefit from this liquidity
    /// @param leftPoint left endpoint of the liquidity
    /// @param rightPoint right endpoint of the liquidity
    /// @param liquidity The amount of liquidity minted to the range [leftPoint, rightPoint)
    /// @param amountX amount of tokenX deposit
    /// @param amountY amount of tokenY deposit
    event Mint(
        address sender, 
        address indexed owner, 
        int24 indexed leftPoint, 
        int24 indexed rightPoint, 
        uint128 liquidity, 
        uint256 amountX, 
        uint256 amountY
    );

    /// @notice Emitted when miner successfully decrease liquidity (withdraw)
    /// @param owner owner address of liquidity
    /// @param leftPoint left endpoint of liquidity
    /// @param rightPoint right endpoint of liquidity
    /// @param liquidity amount of liquidity decreased
    /// @param amountX amount of tokenX withdrawed
    /// @param amountY amount of tokenY withdrawed
    event Burn(
        address indexed owner, 
        int24 indexed leftPoint,
        int24 indexed rightPoint,
        uint128 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    /// @notice Emitted when a trader successfully exchange
    /// @param tokenX tokenX of pool
    /// @param tokenY tokenY of pool
    /// @param fee fee amount of pool
    /// @param sellXEarnY true for selling tokenX, false for buying tokenX
    /// @param amountX amount of tokenX in this exchange
    /// @param amountY amount of tokenY in this exchange
    event Swap(
        address indexed tokenX,
        address indexed tokenY,
        uint24 indexed fee,
        bool sellXEarnY,
        uint256 amountX,
        uint256 amountY
    );


    /// @notice Emitted by the pool for any flashes of tokenX/tokenY
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amountX The amount of tokenX that was flashed
    /// @param amountY The amount of tokenY that was flashed
    /// @param paidX The amount of tokenX paid for the flash, which can exceed the amountX plus the fee
    /// @param paidY The amount of tokenY paid for the flash, which can exceed the amountY plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amountX,
        uint256 amountY,
        uint256 paidX,
        uint256 paidY
    );

    /// @notice Emitted when a seller successfully add a limit order
    /// @param amount amount of token to sell the seller added
    /// @param point point of limit order
    /// @param sellXEarnY direction of limit order, etc. sell tokenX or sell tokenY
    event AddLimitOrder(
        uint256 amount,
        int24 point,
        bool sellXEarnY
    );

    /// @notice Emitted when a seller successfully decrease a limit order
    /// @param amount amount of token to sell the seller decreased
    /// @param point point of limit order
    /// @param sellXEarnY direction of limit order, etc. sell tokenX or sell tokenY
    event DecLimitOrder(
        uint256 amount,
        int24 point,
        bool sellXEarnY
    );

    /// @notice Returns the information about a liquidity by the liquidity's key
    /// @param key The liquidity's key is a hash of a preimage composed by the miner(owner), pointLeft and pointRight
    /// @return liquidity The amount of liquidity,
    /// Returns lastFeeScaleX_128 fee growth of tokenX inside the range as of the last mint/burn/collect,
    /// Returns lastFeeScaleY_128 fee growth of tokenY inside the range as of the last mint/burn/collect,
    /// Returns tokenOwedX the computed amount of tokenX miner can collect as of the last mint/burn/collect,
    /// Returns tokenOwedY the computed amount of tokenY miner can collect as of the last mint/burn/collect
    function liquidity(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 lastFeeScaleX_128,
            uint256 lastFeeScaleY_128,
            uint256 tokenOwedX,
            uint256 tokenOwedY
        );
    
    /// @notice return the information about a user's limit order (sell tokenY and earn tokenX)
    /// @param key the limit order's key is a hash of a preimage composed by the seller, point
    /// @return lastAccEarn total amount of tokenX earned by all users at this point as of the last add/dec/collect
    /// Returns sellingRemain amount of tokenY not selled in this limit order
    /// Returns sellingDec amount of tokenY decreased by seller from this limit order
    /// Returns earn amount of tokenX earned in this limit order not assigned
    /// Returns earnAssign assigned amount of tokenX earned in this limit order
    function userEarnX(bytes32 key)
        external
        view
        returns (
            uint256 lastAccEarn,
            uint128 sellingRemain,
            uint128 sellingDec,
            uint128 earn,
            uint128 earnAssign
        );
    
    /// @notice return the information about a user's limit order (sell tokenX and earn tokenY)
    /// @param key the limit order's key is a hash of a preimage composed by the seller, point
    /// @return lastAccEarn total amount of tokenY earned by all users at this point as of the last add/dec/collect
    /// Returns sellingRemain amount of tokenX not selled in this limit order
    /// Returns sellingDec amount of tokenX decreased by seller from this limit order
    /// Returns earn amount of tokenY earned in this limit order not assigned
    /// Returns earnAssign assigned amount of tokenY earned in this limit order
    function userEarnY(bytes32 key)
        external
        view
        returns (
            uint256 lastAccEarn,
            uint128 sellingRemain,
            uint128 sellingDec,
            uint128 earn,
            uint128 earnAssign
        );
    
    /// @notice mark a given amount of tokenY in a limitorder(sellx and earn y) as assigned
    /// @param point point (log Price) of seller's limit order,be sure to be times of pointDelta
    /// @param assignY max amount of tokenY to mark assigned
    /// @return actualAssignY actual amount of tokenY marked
    function assignLimOrderEarnY(
        int24 point,
        uint128 assignY
    ) external returns(uint128 actualAssignY);
    
    /// @notice mark a given amount of tokenX in a limitorder(selly and earn x) as assigned
    /// @param point point (log Price) of seller's limit order,be sure to be times of pointDelta
    /// @param assignX max amount of tokenX to mark assigned
    /// @return actualAssignX actual amount of tokenX marked
    function assignLimOrderEarnX(
        int24 point,
        uint128 assignX
    ) external returns(uint128 actualAssignX);

    /// @notice decrease limitorder of selling X
    /// @param point point of seller's limit order, be sure to be times of pointDelta
    /// @param deltaX max amount of tokenX seller wants to decrease
    /// @return actualDeltaX actual amount of tokenX decreased
    function decLimOrderWithX(
        int24 point,
        uint128 deltaX
    ) external returns (uint128 actualDeltaX);
    
    /// @notice decrease limitorder of selling Y
    /// @param point point of seller's limit order, be sure to be times of pointDelta
    /// @param deltaY max amount of tokenY seller wants to decrease
    /// @return actualDeltaY actual amount of tokenY decreased
    function decLimOrderWithY(
        int24 point,
        uint128 deltaY
    ) external returns (uint128 actualDeltaY);
    
    /// @notice add a limit order (selling x) in the pool
    /// @param recipient owner of the limit order
    /// @param point point of the order, be sure to be times of pointDelta
    /// @param amountX amount of tokenX to sell
    /// @param data Any data that should be passed through to the callback
    /// @return orderX actual added amount of tokenX
    /// Returns acquireY amount of tokenY acquired if there is a limit order to sell y before adding
    function addLimOrderWithX(
        address recipient,
        int24 point,
        uint128 amountX,
        bytes calldata data
    ) external returns (uint128 orderX, uint128 acquireY);

    /// @notice add a limit order (selling y) in the pool
    /// @param recipient owner of the limit order
    /// @param point point of the order, be sure to be times of pointDelta
    /// @param amountY amount of tokenY to sell
    /// @param data Any data that should be passed through to the callback
    /// @return orderY actual added amount of tokenY
    /// Returns acquireX amount of tokenX acquired if there exists a limit order to sell x before adding
    function addLimOrderWithY(
        address recipient,
        int24 point,
        uint128 amountY,
        bytes calldata data
    ) external returns (uint128 orderY, uint128 acquireX);

    /// @notice collect earned or decreased token from limit order
    /// @param recipient address to benefit
    /// @param point point of limit order, be sure to be times of pointDelta
    /// @param collectDec max amount of decreased selling token to collect
    /// @param collectEarn max amount of earned token to collect
    /// @param isEarnY direction of this limit order, true for sell y, false for sell x
    /// @return actualCollectDec actual amount of decresed selling token collected
    /// @return actualCollectEarn actual amount of earned token collected
    function collectLimOrder(
        address recipient, int24 point, uint128 collectDec, uint128 collectEarn, bool isEarnY
    ) external returns(uint128 actualCollectDec, uint128 actualCollectEarn);

    /// @notice add liquidity to the pool
    /// @param recipient Newly created liquidity will belong to this address
    /// @param leftPt left endpoint of the liquidity, be sure to be times of pointDelta
    /// @param rightPt right endpoint of the liquidity, be sure to be times of pointDelta
    /// @param liquidDelta amount of liquidity to add
    /// @param data Any data that should be passed through to the callback
    /// @return amountX The amount of tokenX that was paid for the liquidity. Matches the value in the callback
    /// @return amountY The amount of tokenY that was paid for the liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 leftPt,
        int24 rightPt,
        uint128 liquidDelta,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);

    /// @notice decrease a given amount of liquidity from msg.sender's liquidities
    /// @param leftPt left endpoint of the liquidity
    /// @param rightPt right endpoint of the liquidity
    /// @param liquidDelta amount of liquidity to burn
    /// @return amountX The amount of tokenX should be refund after burn
    /// @return amountY The amount of tokenY should be refund after burn
    function burn(
        int24 leftPt,
        int24 rightPt,
        uint128 liquidDelta
    ) external returns (uint256 amountX, uint256 amountY);

    /// @notice Collects tokens (fee or refunded after burn) from a liquidity
    /// @param recipient The address which should receive the collected tokens
    /// @param leftPt left endpoint of the liquidity
    /// @param rightPt right endpoint of the liquidity
    /// @param amountXLim max amount of tokenX the owner wants to collect
    /// @param amountYLim max amount of tokenY the owner wants to collect
    /// @return actualAmountX The amount tokenX collected
    /// @return actualAmountY The amount tokenY collected
    function collect(
        address recipient,
        int24 leftPt,
        int24 rightPt,
        uint256 amountXLim,
        uint256 amountYLim
    ) external returns (uint256 actualAmountX, uint256 actualAmountY);

    /// @notice Swap tokenY for tokenX， given max amount of tokenY user willing to pay
    /// @param recipient The address to receive tokenX
    /// @param amount The max amount of tokenY user willing to pay
    /// @param highPt the highest point(price) of x/y during swap
    /// @param data Any data to be passed through to the callback
    /// @return amountX amount of tokenX payed
    /// @return amountY amount of tokenY acquired
    function swapY2X(
        address recipient,
        uint128 amount,
        int24 highPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);
    
    /// @notice Swap tokenY for tokenX， given amount of tokenX user desires
    /// @param recipient The address to receive tokenX
    /// @param desireX The amount of tokenX user desires
    /// @param highPt the highest point(price) of x/y during swap
    /// @param data Any data to be passed through to the callback
    /// @return amountX amount of tokenX payed
    /// @return amountY amount of tokenY acquired
    function swapY2XDesireX(
        address recipient,
        uint128 desireX,
        int24 highPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);
    
    /// @notice Swap tokenX for tokenY， given max amount of tokenX user willing to pay
    /// @param recipient The address to receive tokenY
    /// @param amount The max amount of tokenX user willing to pay
    /// @param lowPt the lowest point(price) of x/y during swap
    /// @param data Any data to be passed through to the callback
    /// @return amountX amount of tokenX acquired
    /// @return amountY amount of tokenY payed
    function swapX2Y(
        address recipient,
        uint128 amount,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);
    
    /// @notice Swap tokenX for tokenY， given amount of tokenY user desires
    /// @param recipient The address to receive tokenY
    /// @param desireY The amount of tokenY user desires
    /// @param lowPt the lowest point(price) of x/y during swap
    /// @param data Any data to be passed through to the callback
    /// @return amountX amount of tokenX acquired
    /// @return amountY amount of tokenY payed
    function swapX2YDesireY(
        address recipient,
        uint128 desireY,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);

    /// @notice returns sqrt(1.0001), in 96 bit fixpoint number
    function sqrtRate_96() external view returns(uint160);
    
    /// @notice some values of pool
    /// @return sqrtPrice_96 a 96 fixpoing number describe the sqrt value of current price(tokenX/tokenY)
    /// @return currentPoint The current point of the pool, 1.0001 ^ currentPoint = price
    /// @return observationCurrentIndex The index of the last oracle observation that was written,
    /// @return observationQueueLen The current maximum number of observations stored in the pool,
    /// @return observationNextQueueLen The next maximum number of observations, to be updated when the observation.
    /// @return locked whether the pool is locked (only used for checking reentrance)
    /// @return liquidity liquidity on the currentPoint (currX * sqrtPrice + currY / sqrtPrice)
    /// @return liquidityX liquidity of tokenX
    function state()
        external view
        returns(
            uint160 sqrtPrice_96,
            int24 currentPoint,
            uint16 observationCurrentIndex,
            uint16 observationQueueLen,
            uint16 observationNextQueueLen,
            bool locked,
            uint128 liquidity,
            uint128 liquidityX
        );
    
    /// @notice limitOrder info on a given point
    /// @param point the given point 
    /// @return sellingX total amount of tokenX selling on the point
    /// @return earnY total amount of unclaimed earned tokenY
    /// @return accEarnY total amount of earned tokenY(via selling tokenX) by all users at this point as of the last swap
    /// @return sellingY total amount of tokenYselling on the point
    /// @return earnX total amount of unclaimed earned tokenX
    /// @return accEarnX total amount of earned tokenX(via selling tokenY) by all users at this point as of the last swap
    function limitOrderData(int24 point)
        external view
        returns(
            uint128 sellingX,
            uint128 earnY,
            uint256 accEarnY,
            uint128 sellingY,
            uint128 earnX,
            uint256 accEarnX
        );
    
    /// @notice query infomation about a point whether has limit order and whether as an liquidity's endpoint
    /// @param point point to query
    /// @return val endpoint for val&1>0 and has limit order for val&2 > 0
    function orderOrEndpoint(int24 point) external returns(int24 val);

    /// @notice Returns observation data about a specific index
    /// @param index the index of observation array
    /// @return timestamp The timestamp of the observation,
    /// @return pointCumulative the point multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulative_128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return init whether the observation has been initialized and the above values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 timestamp,
            int56 pointCumulative,
            uint160 secondsPerLiquidityCumulative_128,
            bool init
        );

    /// @notice returns infomation of a point in the pool
    /// @param point the point
    /// @return liquidSum the total amount of liquidity that uses the point either as left endpoint or right endpoint
    /// @return liquidDelta how much liquidity changes when the pool price crosses the point from left to right
    /// @return accFeeXOut_128 the fee growth on the other side of the point from the current point in tokenX
    /// @return accFeeYOut_128 the fee growth on the other side of the point from the current point in tokenY
    /// @return isEndpt whether the point is an endpoint of a some miner's liquidity, true if liquidSum > 0
    function points(int24 point)
        external
        view
        returns (
            uint128 liquidSum,
            int128 liquidDelta,
            uint256 accFeeXOut_128,
            uint256 accFeeYOut_128,
            bool isEndpt
        );

    /// @notice Returns 256 packed point (statusVal>0) boolean values. See PointBitmap for more information
    function pointBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the integral value of point(time) and integral value of 1/liquidity(time)
    ///     at some target timestamps (block.timestamp - secondsAgo[i])
    /// @dev Reverts if target timestamp is early than oldest observation in the queue
    /// @dev if you call this method with secondsAgos = [3600, 0]. the average point of this pool during recent hour is 
    /// (pointCumulatives[1] - pointCumulatives[0]) / 3600
    /// @param secondsAgos describe the target timestamp , targetTimestimp[i] = block.timestamp - secondsAgo[i]
    /// @return pointCumulatives integral value of point(time) from 0 to each target timestamp
    /// @return secondsPerLiquidityCumulative_128s integral value of 1/liquidity(time) from 0 to each target timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory pointCumulatives, uint160[] memory secondsPerLiquidityCumulative_128s);
    
    /// @notice expand max-length of observation queue
    /// @param newNextQueueLen new value of observationNextQueueLen, which should be greater than current observationNextQueueLen
    function expandObservationQueue(uint16 newNextQueueLen) external;

    /// @notice Receive tokenX and/or tokenY and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IiZiSwapPool#flashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amountX The amount of tokenX to borrow
    /// @param amountY The amount of tokenY to borrow
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amountX,
        uint256 amountY,
        bytes calldata data
    ) external;

    /// @notice return a snapshot infomation of Liquidity in [leftPoint, rightPoint)
    /// @param leftPoint left endpoint of range, should be times of pointDelta
    /// @param rightPoint right endpoint of range, should be times of pointDelta
    /// @return deltaLiquidities an array of delta liquidity for points in the range
    ///    note 1. delta liquidity here is amount of liquidity changed when cross a point from left to right
    ///    note 2. deltaLiquidities only contains points which are times of pointDelta
    ///    note 3. this function may cost a ENORMOUS amount of gas, be careful to call
    function liquiditySnapshot(int24 leftPoint, int24 rightPoint) external view returns(int128[] memory deltaLiquidities);

    /// @notice amount of charged fee on tokenX
    function totalFeeXCharged() external view returns(uint256);

    /// @notice amount of charged fee on tokenY
    function totalFeeYCharged() external view returns(uint256);

    /// @notice percent to charge from miner's fee
    function feeChargePercent() external view returns(uint24);

    /// @notice collect charged fee, only factory's chargeReceiver can call
    function collectFeeCharged() external;
}