<?php

namespace Pay4Later\PDT;

use DateTime;
use JsonSerializable;
class User implements JsonSerializable
{
    /**
     * @var int
     */
    private $userId;

    /**
     * @var string
     */
    private $firstName;

    /**
     * @var string
     */
    private $lastName;

    /**
     * @var string
     */
    private $username;

    /**
     * @var string
     */
    private $userType;

    /**
     * @var DateTime
     */
    private $lastLoginTime;

    /**
     * @return int
     */
    public function getUserId()
    {
        return $this->userId;
    }

    /**
     * @param int $userId
     * @return $this
     */
    public function setUserId($userId)
    {
        $this->userId = (int)$userId;
        return $this;
    }

    /**
     * @return string
     */
    public function getFirstName()
    {
        return $this->firstName;
    }

    /**
     * @param string $firstName
     * @return $this
     */
    public function setFirstName($firstName)
    {
        $this->firstName = $firstName;
        return $this;
    }

    /**
     * @return string
     */
    public function getLastName()
    {
        return $this->lastName;
    }

    /**
     * @param string $lastName
     * @return $this
     */
    public function setLastName($lastName)
    {
        $this->lastName = $lastName;
        return $this;
    }

    /**
     * @return string
     */
    public function getUsername()
    {
        return $this->username;
    }

    /**
     * @param string $username
     * @return $this
     */
    public function setUsername($username)
    {
        $this->username = $username;
        return $this;
    }

    /**
     * @return string
     */
    public function getUserType()
    {
        return $this->userType;
    }

    /**
     * @param string $userType
     * @return $this
     */
    public function setUserType($userType)
    {
        $this->userType = $userType;
        return $this;
    }

    /**
     * @return DateTime
     */
    public function getLastLoginTime()
    {
        return $this->lastLoginTime;
    }

    /**
     * @param DateTime $lastLoginTime
     * @return $this
     */
    public function setLastLoginTime(DateTime $lastLoginTime = null)
    {
        $this->lastLoginTime = $lastLoginTime;
        return $this;
    }

    public function jsonSerialize() {

      # This function returns the data needed for JSON files....
      return [
        'userId' => $this->userId,
        'first_name' => $this->firstName,
        'last_name' => $this->lastName,
        'username' => $this->username,
        'user_type'  => $this->userType,
        'last_login_time' => $this->lastLoginTime
      ];
  }

  public function toArray() {
    # A function that returns the user information as an array for various purposes.
    return [$this->userId,$this->firstName,$this->lastName,$this->username,$this->userType,$this->getLastLoginTime()->format('Y-m-d H:i:s')];
  }

  public function toString() {
     # Returns a comma seprated list of the user information -- useful for creating CSVs...
    return implode(',',$this->toArray());

  }

}
