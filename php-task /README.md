# The Task

* Read the users from the xml, csv and json files within the `data` directory
* Merge all users into a single list and sort them by their `userId` in ascending order
* Write the ordered results to new xml, csv and json files, see the `examples` directory
  * Results should use the same structure as the source files they were parsed from
  * The exception is for `lastLoginTime` where an `ISO 8601` date format is preferred for output


# Requirements

* PHP >= 5.3.23
* [composer](https://getcomposer.org/download/)


# Installation

    composer install


# Notes

A sample implementation is provided for parsing and writing xml files, it can be used like this:


    <?php
    
    use Pay4Later\PDT\Serializer\Adapter\ClassOptions;
    use Pay4Later\PDT\Serializer\Adapter\XmlClass;
    
    require_once __DIR__ . '/vendor/autoload.php';
    
    $config = require __DIR__ . '/config.php';
    
    $xmlSerializer = new XmlClass(
        array(
            ClassOptions::OPTION_CONFIG => $config,
            ClassOptions::OPTION_CLASS  => 'Pay4Later\PDT\User'
        ));
    
    # parse the xml file into an array of Pay4Later\PDT\User
    $users = $xmlSerializer->unserialize(file_get_contents(__DIR__ . '/data/users.xml'));
    
    # produce an xml file from an array of Pay4Later\PDT\User
    $xmlString = $xmlSerializer->serialize($users);

You are free to implement your solution however you feel most appropriate and will be assessed on the architecture
of your solution. We recommend producing a simple, extensible solution and do not require you to complete all the
tasks within the allotted time. However, please comment on any assumptions made or design decisions you would have
made if you would have done something differently given more time.

# Submitting your solution

Please don't fork the repo, as your solution will be public.

Either:
* Zip up your solution, omitting the vendor folder
* After committing your changes, create a git bundle from your local repo with:
```
git bundle create solution.bundle master
```

Submit your solution via email
