pragma solidity 0.6.12;

interface IStakingRewards {
    // Views

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function rewardWithdraw() external;

    function exit() external;
}
