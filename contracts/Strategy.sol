// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {
    BaseStrategy,
    StrategyParams
} from "@yearnvaults/contracts/BaseStrategy.sol";
import {
    SafeERC20,
    SafeMath,
    IERC20,
    Address
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol"; 

// Import interfaces for many popular DeFi projects, or add your own!
import "../interfaces/aave/ILendingPool.sol";
//import "../interfaces/aave/IProtocolDataProvider.sol";
import "../interfaces/aave/IAaveIncentivesController.sol";
import "../interfaces/aave/IAToken.sol";
    
}

contract StrategyAAVE is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    ILendingPool public constant AaveLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    //IProtocolDataProvider private constant dataProvider = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    //IAaveIncentivesController public constant incentivesController = IAaveIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);

    IERC20 public usdc = IERC20(0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48);
    IERC20 public aToken = IERC20(0xbcca60bb61934080951369a648fb03df4f96263c);

    mapping(address => uint256) public userDepositedUSDC;

    constructor() public {
        usdc.approve(address(AaveLendingPool), type(uint256).max);
    }

    function depositUSDC(uint256 _amountUsdc) external {
        userDepositedUSDC[msg.sender] = _amountUsdc;
        require(usdc.transferFrom(msg.sender, address(this), _amountUsdc), "Transfer failed!");
        AaveLendingPool.deposit(address(usdc), _amountUsdc, 0);
    }
}
