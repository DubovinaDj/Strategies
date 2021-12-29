// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//Open Zepplein
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/math/SafeMath.sol";

//AAVE 
import "../interfaces/aave/ILendingPool.sol";
import "../interfaces/aave/ILendingPoolAddressesProvider.sol";
import "../interfaces/aave/IAaveIncentivesController.sol";
import "../interfaces/aave/IAToken.sol";
import "../interfaces/aave/IStableDebtToken.sol";

contract AAVEFarmingStrategy {
    using SafeMath for uint256;

    //PriceFeed public priceFeed = PriceFeed(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
    //ILendingPool public constant AaveLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    //IAaveIncentivesController public constant incentivesController = IAaveIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);

    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    IAaveIncentivesController public IAaveIncentivesController;


    address LENDING_POOL;
    address INCENTIVES_CONTROLLER;
    address STRATEGY_OWNER;

    IERC20 public tokenSupply;
    IAToken public aTokenSupply;

    //set address of tokens
    constructor(
        ILendingPoolAddressesProvider _provider,
        IAaveIncentivesController _incentivesController,
        address _strategyOwner,
        address _tokenSupply,
        address _aTokenSupply
    ) public {
        provider = _provider;
        lendingPool = ILendingPool(provider.getLendingPool());
        incentivesController = _incentivesController;

        LENDING_POOL = provider.getLendingPool();
        INCENTIVES_CONTROLLER = address(incentivesController);
        STRATEGY_OWNER = _strategyOwner;

        tokenSupply = IERC20(_tokenSupply);
        aTokenSupply = IAToken(_aTokenSupply);
    }

    //Midifier - is caller strategy owner or not 
    modifier onlyStrategyOwner() {
        require(msg.sender == STRATEGY_OWNER, "Caller have to be a strategy owner");
        _;
    }

    function loanToAave(uint _amount) external onlyStrategyOwner returns (bool) {
        tokenSupply.transferFrom(msg.sender, address(this), _amount);
        tokenSupply.approve(LENDING_POOL, _amount);
        //Deposit token
        lendingPool.deposit(address(aTokenSupply), _amount, msg.sender, 0);
        require(aTokenSupply.mint(_amount) == 0, "mint failed");
    }

    function getATokenBalance() external view returns (uint) {
        return aTokenSupply.balanceOf(address(this));
    }
    
    // total supply and average stable rate of the token.
    function TotalSupplyAndAvgRate() external returns (uint) {
        return aTokenSupply.getTotalSupplyAndAvgRate(address(this));
    }

    function collateralAave(bool useAsCollateral) external onlyStrategyOwner returns (bool) {
        //useAsCollateral -> [Note]: `true` if the user wants to use the deposit as collateral, `false` otherwise
        bool useAsCollateral = true;
        lendingPool.setUserUseReserveAsCollateral(address(tokenSupply), useAsCollateral);
    }

    function borrow(
        uint _aTokenBorrow,
        uint _amount, 
        uint _interestRateMode
    ) external onlyStrategyOwner returns (bool) {
        lendingPool.borrow(_borrowToken, _amount, _interestRateMode, msg.sender, 0);
    }
    
    function claimRewardsForAave(address[] calldata _aTokenBorrow, uint256 _amount) external onlyStrategyOwner returns (bool) {
        uint rewardsClaimed = incentivesController.claimRewards(_aTokenBorrow, _amount, msg.sender);
    }

   //Get rewards balance of the AAVE
    function getAaveRewardsBalance(address[] memory assets) external view returns (uint _rewardsBalance) {
        return incentivesController.getRewardsBalance(address(aTokenSupply), address(this));
    }

    function repayAave(address _asset, uint _amount) external returns (uint256) {
        return ILendingPool.repay(address(aTokenSupply), amount, 2, msg.sender);
    }

}