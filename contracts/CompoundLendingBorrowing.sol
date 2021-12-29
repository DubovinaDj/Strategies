// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/compound/compound.sol";

contract CompoundStrat {
    IERC20 public token;
    CErc20 public cToken;

    //set address of tokens
    constructor(address _token, address _cToken) {
        token = IERC20(_token);
        cToken = CErc20(_cToken);
    }

    function supply(uint _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);
        // we need to allowance to send token
        token.approve(address(cToken), _amount);
        // how much tokens you want to send to exchange and get cToken
        require(cToken.mint(_amount) == 0, "mint failed");
    }

    // How much cTokens do we have ? 
    function getCTokenBalance() external view returns (uint) {
        return cToken.balanceOf(address(this));
    }

    // you need to send transaction to get information about exchangeRate and supplyRate
    function getInfo() external returns(uint exchangeRate, uint supplyRate) {
        // Amount of current exchange rate form cToken to underlying
        exchangeRate = cToken.exchangeRateCurrent();
        // Amount added to you supply balance this block (intrest rate)
        supplyRate = cToken.supplyRatePerBlock();
    }

    // calculate and supply the amount of token then we supplyed into compund
    function balanceOfUnderlying() external returns (uint) {
        return cToken.balanceOfUnderlying(address(this));
    }
    
    
    // ready to claim token and intrest 
    function redeem(uint _cTokenAmount) external {
        require(cToken.redeem(_cTokenAmount) == 0, "redeem is faild");

    }

    // borow and repay 
    Comptroller public comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    PriceFeed public priceFeed = PriceFeed(0x6d7F71Cc3109D4132Ad6124D84e72E353b979880);

    // Collateral
    function getCollateralFactor() external view returns (uint) {
        // need to call markets in order to supply token
        // isListed -> is the cToken recognize by comptroler (if pass invalid address for cTokne, you will get false)
        // colFactor -> collateral factor (you will get precentage)
        // isComped -> is the cTokne going to recive compound reward token (comp)
        (bool isListed, uint colFactor, bool isComped) = comptroller.markets(address(cToken));
        return colFactor; // divide by 1e18 to get in %
    }

    // account liquidity - how much i can borrow ?
    function getAccountLiquidity() external view returns (uint liquidity, uint shortfall) {
        // liquidity and shortfall in USD scaled up by 1e18
        // comptroller.getAccountLiquidity(address(this)); -> get current liquidity of account 
        // error -> if it is not error you will get number greather then zero 
        // _liquidity -> usd amount that we can borrow up to
        // _shortfall -> greather then zero means that you borrow over the limit
        (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(address(this));
        require(error == 0, "error");
        // normal circumstance - liquidity > 0 and shortfall == 0
        // liquidity > 0 means account can borrow up to 'liquidity'
        // shortfall > 0 is subject to liquidation, you borrowed over limit
        return (_liquidity, _shortfall);
    }

    // open price feed - USD price of token to borrow 
    function getPriceFeed(address _cToken) external view returns (uint) {
        return priceFeed.getUnderlyingPrice(_cToken);

    }

    // enter market and borrow
    function borrow(address _cTokenToBorrow, uint _decimals) external {
        // enter market
        // enter the supply market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cToken);
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        require(error[0] == 0, "Comptroller.enterMarkets failed.");
        //chekck liquiddity
        (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(address(this));
        require(error == 0, "error");
        require(shortfall == 0, "shortfall >0");
        require(liquidity > 0, "liquidity = 0");
        // calculate max borrow
        uint price = priceFeed.getUnderlyingPrice(_cTokenToBorrow);

        uint maxBorrow = (liquidity * (10** _decimals)) / price;
        require(maxBorrow > 0, "max borrow = 0");

        // borrow 50% of max borrow
        uint amount = (maxBorrow * 50) / 100; 
        require(CErc20(_cTokenToBorrow).borrow(amount) == 0, "borrow failed");
    }

    // borrowed balance (includes intrest)
    function getBorrowRatePerBLock(address _cTokenBorrowed) public returns (uint) {
        return CErc20(_cTokenBorrowed).borrowBalanceCurrent(address(this));
    }

    // borrow rate
    function getBorrowRatePerBLock(address _cTokenBorrowed) external view returns (uint) {
        // scaled up by 1e18
        return CErc20(_cTokenBorrowed).borrowRatePerBlock();
    }

    function repay(address _tokenBorrowed, address _cTokenBorrowed, uint _amount) external {
        IERC20(_tokenBorrowed).approve(_cTokenBorrowed, _amount);
        require(CErc20(_cTokenBorrowed).repayBorrow(_amount) == 0, "repay failed");
    }
}




