// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RideSharing {
    struct Ride {
        uint256 rideId;
        address payable driver;
        uint256 fare;
        uint256 timestamp;
        bool isActive;
    }

    struct Rider {
        address payable riderAddress;
        uint256[] rides;
        mapping(uint256 => bool) hasRide;
    }

    mapping(uint256 => Ride) public rides;
    mapping(address => Rider) public riders;
    uint256 public totalRides;

    event RideCreated(uint256 rideId, address driver, uint256 fare);
    event RideCompleted(
        uint256 rideId,
        address driver,
        address rider,
        uint256 fare
    );
    event RiderBlacklisted(address rider);

    function createRide(uint256 _fare) external {
        require(_fare > 0, "Invalid fare amount");
        Ride storage newRide = rides[totalRides];
        newRide.rideId = totalRides;
        newRide.driver = payable(msg.sender);
        newRide.fare = _fare;
        newRide.timestamp = block.timestamp;
        newRide.isActive = true;
        totalRides++;

        emit RideCreated(newRide.rideId, newRide.driver, newRide.fare);
    }

    function completeRide(uint256 _rideId) external payable {
        require(msg.value > 0, "Invalid fare amount");
        Ride storage completedRide = rides[_rideId];
        require(
            completedRide.driver == msg.sender,
            "Only the driver can complete the ride"
        );
        require(
            completedRide.isActive == true,
            "Ride is already completed or does not exist"
        );
        require(msg.value == completedRide.fare, "Incorrect fare amount");

        Rider storage currentRider = riders[msg.sender];
        currentRider.rides.push(_rideId);
        currentRider.hasRide[_rideId] = true;

        completedRide.isActive = false;
        emit RideCompleted(
            completedRide.rideId,
            completedRide.driver,
            msg.sender,
            completedRide.fare
        );
        completedRide.driver.transfer(msg.value);
    }

    function getRiderRides(
        address _riderAddress
    ) external view returns (uint256[] memory) {
        Rider storage currentRider = riders[_riderAddress];
        return currentRider.rides;
    }

    function getRideDetails(
        uint256 _rideId
    ) external view returns (address, uint256, uint256) {
        Ride storage currentRide = rides[_rideId];
        require(currentRide.isActive == false, "Ride is still active");
        return (currentRide.driver, currentRide.fare, currentRide.timestamp);
    }

    function blacklistRider(address _riderAddress) external {
        require(_riderAddress != address(0), "Invalid rider address");
        Rider storage currentRider = riders[_riderAddress];
        currentRider.riderAddress = payable(address(0));
        emit RiderBlacklisted(_riderAddress);
    }

    function getRiderAddress(uint256 _rideId) external view returns (address) {
        Ride storage currentRide = rides[_rideId];
        require(currentRide.isActive == false, "Ride is still active");
        return riders[currentRide.driver].riderAddress;
    }

    function getRiderRideCount(
        address _riderAddress
    ) external view returns (uint256) {
        Rider storage currentRider = riders[_riderAddress];
        return currentRider.rides.length;
    }

    function setRiderAddress(address _riderAddress) external {
        require(_riderAddress != address(0), "Invalid rider address");
        Rider storage currentRider = riders[msg.sender];
        currentRider.riderAddress = payable(_riderAddress);
    }

    function getRideCount() external view returns (uint256) {
        return totalRides;
    }

    function getActiveRides() external view returns (uint256[] memory) {
        uint256[] memory activeRides = new uint256[](totalRides);
        uint256 index = 0;
        for (uint256 i = 0; i < totalRides; i++) {
            Ride storage currentRide = rides[i];
            if (currentRide.isActive) {
                activeRides[index] = currentRide.rideId;
                index++;
            }
        }
        return activeRides;
    }
}
