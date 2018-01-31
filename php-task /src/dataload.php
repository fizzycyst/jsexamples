<?php

/*
This file has all the main functions to do the donkey work

Reads in data from the XML/CSV/JSON files

and then creates the new merged versions of these files.



*/
use Pay4Later\PDT\Serializer\Adapter\ClassOptions;
use Pay4Later\PDT\Serializer\Adapter\XmlClass;

require_once __DIR__ . '/../vendor/autoload.php';

# parse the xml file into an array of Pay4Later\PDT\User
#$users_xml = $xmlSerializer->unserialize(file_get_contents(__DIR__ . '/../data/users.xml'));

function getXmlUsers($xml_files) {
  # Takes a list of xml files loops through and puts the contents into an array
  # of Users which is returned back to the main function.

  $xml_users = [];
  $config = require __DIR__ . '/../config.php';
  $xmlSerializer = new XmlClass(
      array(
          ClassOptions::OPTION_CONFIG => $config,
          ClassOptions::OPTION_CLASS  => 'Pay4Later\PDT\User'
      ));

  foreach ($xml_files as $filename){

    $xml_users = array_merge($xml_users,$xmlSerializer->unserialize(file_get_contents($filename)));
  }

  return $xml_users;
}


function getJsonUsers($json_files) {

  # Takes a list of JSON files goes through them one by one and creates an array
  # that is then returned.

  $json_users = [];
  foreach ($json_files as $filename) {
    $users_json =  json_decode(file_get_contents($filename));
    if ($users_json === null) {
      echo 'We have a bit of bad JSON data by the looks of it';
      switch (json_last_error()) {
            case JSON_ERROR_NONE:
                echo ' - No errors';
                break;
                case JSON_ERROR_DEPTH:
                echo ' - Maximum stack depth exceeded';
                break;
                case JSON_ERROR_STATE_MISMATCH:
                echo ' - Underflow or the modes mismatch';
                break;
                case JSON_ERROR_CTRL_CHAR:
                echo ' - Unexpected control character found';
                break;
                case JSON_ERROR_SYNTAX:
                echo ' - Syntax error, malformed JSON';
                break;
                case JSON_ERROR_UTF8:
                echo ' - Malformed UTF-8 characters, possibly incorrectly encoded';
                break;
                default:
                echo ' - Unknown error';
                break;
              }
    } else {

      foreach ($users_json as $myuser){


        $new_user = new Pay4Later\PDT\User();
        $new_user->setUserName($myuser->username);
        $new_user->setFirstName($myuser->first_name);
        $new_user->setLastName($myuser->last_name);
        $new_user->setUserId($myuser->user_id);
        $new_user->setUserType($myuser->user_type);
        $new_user->setLastLoginTime(new DateTime($myuser->last_login_time));
        array_push($json_users,$new_user);
      }

    }

  }

  return $json_users;
}

function getCsvUsers($json_files) {
# Loops through the list of CSCV files creating and array of Users to be returned

  $csv_users_to_return = [];
  foreach ($json_files as $filename) {
    $csvUsers = file($filename);
    $csv_users = [];
    foreach ($csvUsers as $line) {
      $csv_users[] = str_getcsv($line);
    }
    $columns = array_shift($csv_users);

    foreach ($csv_users as $key=>$myuser) {
      $new_user = new Pay4Later\PDT\User();

      $new_user->setUserName($myuser[3]);
      $new_user->setFirstName($myuser[1]);
      $new_user->setLastName($myuser[2]);
      $new_user->setUserId($myuser[0]);
      $new_user->setUserType($myuser[4]);
      $new_user->setLastLoginTime(new DateTime($myuser[5]));
      array_push($csv_users_to_return,$new_user);
    }
  }

  return $csv_users_to_return;
}

function createCsvOutput($merged_users) {
  # Unlike JSON or XML there isn't simple way of serializing for CSV so
  # this is a quick function that loops through the merged array creating
  # a new csv output that can be dumped into a file.
  
  $csvArray = [];
  $header = 'User ID,First Name,Last Name,Username,User Type,Last Login Time';

  array_push($csvArray,$header);

    foreach ($merged_users as &$value) {
      array_push($csvArray,$value->toString());
    }

    $csvOutput = implode("\n",$csvArray);

    return $csvOutput;

  }



 ?>
