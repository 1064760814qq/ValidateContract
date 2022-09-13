// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FGT_stake is  Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    uint256 public _now_time;
    IERC20 public _FGT;
    bool public _bTest = true;
    

    event Relieve(address user , uint256 reward);

    receive() external payable {}


    function withdrawToken(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function withdrawBNB() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setToken(address FGT) public onlyOwner {
        _FGT = IERC20(FGT);
    }       
    function decimals() public pure  returns (uint8) {
        return 18;
    }

    struct UserInfo {
        uint256 _lockTimestamp; 
        uint256 _lockAmounts; 
        uint256 _lockMonths; 
        uint256 _releaseAmountMonth; 
        uint256 _releaseCountTotal; 
        uint256 _alreadyReleaseCount; 
        bool first_flag;
    }


    mapping(address => UserInfo) public userInfos;


    function setLock(
    address account,
    uint256 lockMonths, 
    uint256 rewardPerMonth, 
    uint256 left_balance, 
    uint256 rewardMonths)  
    external 
    onlyOwner
    {
        require((rewardMonths.mul(rewardPerMonth) == left_balance),"months * perMonthAmount != total");
        UserInfo storage user = userInfos[account];
        user._lockTimestamp = getNowTime();
        user._lockAmounts = left_balance;
        user._lockMonths = lockMonths;
        user._releaseAmountMonth = rewardPerMonth;
        user._releaseCountTotal = rewardMonths;
    }

    function release() public nonReentrant{
        UserInfo storage user = userInfos[msg.sender];
        require(user._alreadyReleaseCount < user._releaseCountTotal, " all released");
        
        uint256 rewardMonthCount = getRewardCount(); 
        require(rewardMonthCount > user._alreadyReleaseCount, "no reward");
        
        if (rewardMonthCount > user._releaseCountTotal) {
            rewardMonthCount = user._releaseCountTotal;
        }

        uint256 reward = (rewardMonthCount.sub(user._alreadyReleaseCount)).mul(user._releaseAmountMonth);
        user.first_flag = true;
        _FGT.transferFrom(address(this),msg.sender, reward);
        user._alreadyReleaseCount =  rewardMonthCount;
        
        emit Relieve(msg.sender, reward);
    }

    function getRewardCount() private view returns(uint256) {
        if(!userInfos[msg.sender].first_flag){
        return ((getNowTime().sub(userInfos[msg.sender]._lockTimestamp)).div(every_months_time()).sub(userInfos[msg.sender]._lockMonths)).add(1);
        }
        else{return (getNowTime().sub(userInfos[msg.sender]._lockTimestamp)).div(every_months_time()).sub(userInfos[msg.sender]._lockMonths);}
    }
    
    function every_months_time() private pure returns(uint256){
        return 86400*30;
    }

    function getNowTime() private view returns(uint256) {
        return block.timestamp;
    }
}