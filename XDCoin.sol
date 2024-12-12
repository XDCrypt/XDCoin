// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol" as ERC20;
import "@openzeppelin/contracts/access/Ownable.sol" as Ownable;

contract XDCoin is ERC20.ERC20, Ownable.Ownable {
    uint256 private constant _totalSupply = 69420000000 * 10 ** 18; // 69,420,000,000 XD
    
    uint8 private constant _burnFee = 1; // 1% burn
    uint8 private constant _reflectionFee = 1; // 1% reflection
    uint8 private constant _liquidityFee = 1; // 1% liquidity

    address public liquidityWallet; // Liquidity wallet address
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isHolder;
    address[] private _holders;

    constructor() ERC20.ERC20("XD Coin", "XD") Ownable.Ownable(msg.sender) {
        _mint(msg.sender, _totalSupply);
        liquidityWallet = msg.sender; // Default liquidity wallet is the deployer's address
        _isExcludedFromFee[msg.sender] = true; // Exclude owner from fees
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 transferAmount = amount;

        if (!_isExcludedFromFee[_msgSender()]) {
            uint256 burnAmount = (amount * _burnFee) / 100;
            uint256 reflectionAmount = (amount * _reflectionFee) / 100;
            uint256 liquidityAmount = (amount * _liquidityFee) / 100;

            // Apply fees
            transferAmount = amount - burnAmount - reflectionAmount - liquidityAmount;

            // Burn 1%
            _burn(_msgSender(), burnAmount);

            // Redistribute 1% to holders
            _reflectToHolders(reflectionAmount);

            // Add 1% to liquidity
            _transfer(_msgSender(), liquidityWallet, liquidityAmount);
        }

        _transfer(_msgSender(), recipient, transferAmount);

        // Update the holders list
        _updateHolders(_msgSender());
        _updateHolders(recipient);

        return true;
    }

    function _reflectToHolders(uint256 amount) private {
        uint256 totalSupplyWithoutBurn = totalSupply() - balanceOf(address(0)); // Exclude burn wallet
        for (uint256 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
            uint256 holderBalance = balanceOf(holder);
            if (holderBalance > 0) {
                uint256 share = (holderBalance * amount) / totalSupplyWithoutBurn;
                if (share > 0) {
                    _transfer(_msgSender(), holder, share);
                }
            }
        }
    }

    function _updateHolders(address account) private {
        if (balanceOf(account) > 0 && !_isHolder[account]) {
            _isHolder[account] = true;
            _holders.push(account);
        } else if (balanceOf(account) == 0 && _isHolder[account]) {
            _isHolder[account] = false;
            // Remove the account from the holders array
            for (uint256 i = 0; i < _holders.length; i++) {
                if (_holders[i] == account) {
                    _holders[i] = _holders[_holders.length - 1];
                    _holders.pop();
                    break;
                }
            }
        }
    }

    function excludeFromFee(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function setLiquidityWallet(address wallet) public onlyOwner {
        liquidityWallet = wallet;
    }

    // Utility function to fetch the list of holders (optional)
    function getHolders() public view returns (address[] memory) {
        return _holders;
    }
}