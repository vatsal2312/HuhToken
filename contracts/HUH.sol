// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./DividendPayingToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/IterableMapping.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import { IUniswapV2Pair, IUniswapV2Router02 } from "./interfaces/IUniswap.sol";


contract HUH is ERC20, Ownable {
    using SafeMath for uint256;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    bool private swapping;

    HUHDividendTracker public dividendTracker;

    address public liquidityWallet;
    uint256 public swapTokensAtAmount = 200000 * (10**18);

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public immutable sellFeeIncreaseFactor = 120;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // users ref code mappings
    mapping(bytes => address) private _refCodeToAddress;
    mapping(address => bytes) private _addressToRefCode;
    mapping(address => bool) private _refCodeUsed;
    mapping(address => address) private _referrer;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);
    event UserWhitelisted(address account, address referrer, bytes refCode);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );


    //  -----------------------------
    //  CONSTRUCTOR
    //  -----------------------------


    constructor(address uniswapV2Router_, address uniswapV2Pair_) public ERC20("HUH Token", "HUH") {
    	dividendTracker = new HUHDividendTracker();
    	liquidityWallet = owner();

        uniswapV2Pair = uniswapV2Pair_;
        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);

        _setAutomatedMarketMakerPair(uniswapV2Pair_, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router_));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {}

    fallback() external payable {}


    //  -----------------------------
    //  SETTERS (OWNABLE)
    //  -----------------------------


    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "HUH: The dividend tracker already has that address");

        HUHDividendTracker newDividendTracker = HUHDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "HUH: The new dividend tracker must be owned by the HUH token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "HUH: The router already has that address");

        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "HUH: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "HUH: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "HUH: The liquidity wallet is already this address");

        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "HUH: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "HUH: Cannot update gasForProcessing to same value");

        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimPeriod(uint256 claimPeriod) external onlyOwner {
        dividendTracker.updateClaimPeriod(claimPeriod);
    }

    // TODO: It uses too much centralisation (owner allowed to whitelist many referrals under himself)
    function whitelist(address account, string memory refCode) public onlyOwner {
        bytes memory refCode_ = bytes(refCode);
        require(refCode_.length > 0, "whitelist: Invalid code!");
        require(!isWhitelisted(account), "whitelist: Already whitelisted!");
        require(isRefCodeAvailable(refCode_), "whitelist: Code taken!");

        address referrer = _refCodeToAddress[refCode_];
        _whitelistWithRef(account, refCode_, referrer);
    }


    //  -----------------------------
    //  SETTERS (PUBLIC)
    //  -----------------------------


	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function whitelist(string memory ownCode, string memory refCode) public {
        bytes memory ownCode_ = bytes(ownCode);
        bytes memory refCode_ = bytes(refCode);
        require(ownCode_.length > 0, "whitelist: Invalid own code!");
        require(refCode_.length > 0, "whitelist: Invalid referrer code!");

        require(!isWhitelisted(msg.sender), "whitelist: User already whitelisted!");
        require(isRefCodeAvailable(ownCode_), "whitelist: Own code taken!");
        require(!isRefCodeAvailable(refCode_), "whitelist: Referrer code not exists!");

        address referrer = _refCodeToAddress[refCode_];
        _whitelistWithRef(msg.sender, ownCode_, referrer);
    }

    //  -----------------------------
    //  GETTERS
    //  -----------------------------


    function getAccountDividendsInfo(address account) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
    	return dividendTracker.getAccountAtIndex(index);
    }

    function getClaimPeriod() external view returns (uint256) {
        return dividendTracker.claimPeriod();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getLastProcessedIndex() external view returns (uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getRefCode(address account) public view returns (string memory) {
        return string(_addressToRefCode[account]);
    }

    function refCodeUsed(address account) public view returns (bool) {
        return _refCodeUsed[account];
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _addressToRefCode[account].length != 0;
    }

    function isRefCodeAvailable(bytes memory refCode) public view returns (bool) {
        return _refCodeToAddress[refCode] == address(0);
    }

    //  -----------------------------
    //  PRIVATE
    //  -----------------------------


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "HUH: Automated market maker pair is already set to that value");

        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool enoughTokensToSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            enoughTokensToSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            // Step 1) Add liquidity
            uint256 swapTokens = contractTokenBalance.mul(5).div(15);
            _swapAndLiquify(swapTokens);

            // Step 2) Send dividends to 10k HUH/+ holders
            uint256 sellTokens = balanceOf(address(this));
            _swapAndSendDividends(sellTokens);

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
        	uint256 fees = amount.mul(15).div(100);

            // if sell, multiply by 1.2
            if (automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} catch {}
        }
    }

    function _swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapAndTransfer(uint256 tokens, address receiver) private {
        _swapTokensForEth(tokens);
        (bool success,) = receiver.call{value: address(this).balance}("");
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function _swapAndSendDividends(uint256 tokens) private {
        _swapTokensForEth(tokens);

        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if (success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }

    // TODO: Check any possible issue with string/bytes length
    function _whitelistWithRef(address account, bytes memory code, address referrer) private {
        _refCodeToAddress[code] = account;
        _addressToRefCode[account] = code;
        _referrer[account] = referrer;

        emit UserWhitelisted(account, referrer, code);
    }
}

contract HUHDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimPeriod;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimPeriodUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);


    //  -----------------------------
    //  CONSTRUCTOR
    //  -----------------------------


    constructor() public DividendPayingToken("HUH_Dividend_Tracker", "HUH_Dividend_Tracker") {
    	claimPeriod = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }


    //  -----------------------------
    //  SETTERS (OWNABLE)
    //  -----------------------------


    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimPeriod(uint256 newClaimPeriod) external onlyOwner {
        require(newClaimPeriod >= 3600 && newClaimPeriod <= 86400, "HUH_Dividend_Tracker: claimPeriod must be updated to between 1 and 24 hours");
        require(newClaimPeriod != claimPeriod, "HUH_Dividend_Tracker: Cannot update claimPeriod to same value");

        emit ClaimPeriodUpdated(newClaimPeriod, claimPeriod);

        claimPeriod = newClaimPeriod;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if (excludedFromDividends[account]) {
    		return;
    	}

    	if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	} else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if (amount > 0) {
    		lastClaimTimes[account] = block.timestamp;

            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }


    //  -----------------------------
    //  SETTERS (PUBLIC)
    //  -----------------------------


    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if (numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if (_canAutoClaim(lastClaimTimes[account])) {
    			if (processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if (gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function withdrawDividend() public override {
        require(false, "HUH_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main HUH contract.");
    }


    //  -----------------------------
    //  GETTERS
    //  -----------------------------


    function getLastProcessedIndex() external view returns (uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account) public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable
    ) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimPeriod) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index) public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
    	if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }


    //  -----------------------------
    //  PRIVATE
    //  -----------------------------


    function _transfer(address, address, uint256) internal override {
        require(false, "HUH_Dividend_Tracker: No transfers allowed");
    }

    function _canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if (lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimPeriod;
    }
}