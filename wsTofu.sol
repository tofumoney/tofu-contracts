// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract wOHM is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable staking;
    address public immutable OHM;
    address public immutable sOHM;

    constructor(
        address _staking,
        address _OHM,
        address _sOHM
    ) ERC20("Wrapped sTOFU", "wsTOFU") {
        require(_staking != address(0));
        staking = _staking;
        require(_OHM != address(0));
        OHM = _OHM;
        require(_sOHM != address(0));
        sOHM = _sOHM;
    }

    /**
        @notice stakes OHM and wraps sOHM
        @param _amount uint
        @return uint
     */
    function wrapFromOHM(uint256 _amount) external returns (uint256) {
        IERC20(OHM).transferFrom(msg.sender, address(this), _amount);

        IERC20(OHM).approve(staking, _amount); // stake OHM for sOHM
        IStaking(staking).stake(_amount, address(this));

        uint256 value = wOHMValue(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sOHM and unstake OHM
        @param _amount uint
        @return uint
     */
    function unwrapToOHM(uint256 _amount) external returns (uint256) {
        _burn(msg.sender, _amount);

        uint256 value = sOHMValue(_amount);
        IERC20(sOHM).approve(staking, value); // unstake sOHM for OHM
        IStaking(staking).unstake(value, address(this));

        IERC20(OHM).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice wrap sOHM
        @param _amount uint
        @return uint
     */
    function wrapFromsOHM(uint256 _amount) external returns (uint256) {
        IERC20(sOHM).transferFrom(msg.sender, address(this), _amount);

        uint256 value = wOHMValue(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sOHM
        @param _amount uint
        @return uint
     */
    function unwrapTosOHM(uint256 _amount) external returns (uint256) {
        _burn(msg.sender, _amount);

        uint256 value = sOHMValue(_amount);
        IERC20(sOHM).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice converts wOHM amount to sOHM
        @param _amount uint
        @return uint
     */
    function sOHMValue(uint256 _amount) public view returns (uint256) {
        return _amount.mul(IStaking(staking).index()).div(10**decimals());
    }

    /**
        @notice converts sOHM amount to wOHM
        @param _amount uint
        @return uint
     */
    function wOHMValue(uint256 _amount) public view returns (uint256) {
        return _amount.mul(10**decimals()).div(IStaking(staking).index());
    }
}
