// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721AX} from "./ERC721AX.sol";

contract MockERC721A is ERC721AX {
    constructor() ERC721AX("M", "M", 1, 3888, 20) {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(uint256 quantity) public virtual {
        _mint(msg.sender, quantity);
    }
}
