//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MERC20") {}

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function burnFrom(address owner, uint256 amount) external {
        _burn(owner, amount);
    }
}
