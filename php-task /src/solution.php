<?php
use Pay4Later\PDT\Serializer\Adapter\ClassOptions;
use Pay4Later\PDT\Serializer\Adapter\XmlClass;

require_once __DIR__ . '/../vendor/autoload.php';

require_once __DIR__ . '/dataload.php';

$config = require __DIR__ . '/../config.php';

$xmlSerializer = new XmlClass(
    array(
        ClassOptions::OPTION_CONFIG => $config,
        ClassOptions::OPTION_CLASS  => 'Pay4Later\PDT\User'
    ));

$datadir = __DIR__ . '/../data/';


echo "Starting.\n";
echo "Cleaning up old data\n";
# clear up old files before we start creating new ones.
if (file_exists ($datadir . 'merged_data.xml')) unlink($datadir . 'merged_data.xml');
if (file_exists ($datadir . 'merged_data.json')) unlink($datadir  . 'merged_data.json');
if (file_exists ($datadir . 'merged_data.csv')) unlink($datadir . 'merged_data.csv');


# Find all files we might be interested in be they XML/CSV/JSON -- not just the example ones

echo "Reading in XML data\n";
$xml_files = glob($datadir  . '*.xml');
echo "Reading in JSON data\n";
$json_files = glob($datadir . '*.json');
echo "Reading in CSV data\n";
$csv_files = glob($datadir . '*.csv');


# Go get the users by file type ...

$xml_users = getXmlUsers($xml_files);

$json_users = getJsonUsers($json_files);

$csv_users = getCsvUsers($csv_files);

echo "Merging users\n";
# Merge the users into a single array
$merged_users = array_merge($xml_users,$json_users,$csv_users);

echo "Sorting users\n";
# Sort that array by the userId field -- This is a string sort so you get 2 22 3 33 etc
usort($merged_users, function($a, $b)
{
    return strcmp($a->getUserId(), $b->getUserId());
});

# Then output back out into merged data files....

# Create the data first
echo "Creating output data\n";
$xmlString = $xmlSerializer->serialize($merged_users);

$jsonOutPutString = json_encode($merged_users,  JSON_PRETTY_PRINT);

$csvOutputData = createCsvOutPut($merged_users);

# Then do the actual outputting..
echo "Creating output files\n";
file_put_contents($datadir . 'merged_data.xml', $xmlString);

file_put_contents($datadir . 'merged_data.json', $jsonOutPutString);

file_put_contents($datadir . 'merged_data.csv', $csvOutputData);
