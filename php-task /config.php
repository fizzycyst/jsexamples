<?php

use Zend\Stdlib\Hydrator\Strategy\DateTimeFormatterStrategy;

return array(
    'Pay4Later\PDT\User' => array(
        'xml' => array(
            'shared' => array(
                'map' => array(
                    'userId' => 'userid',
                    'firstName' => 'firstname',
                    'lastName' => 'surname',
                    'username' => 'username',
                    'userType' => 'type',
                    'lastLoginTime' => 'lastlogintime'
                ),
            ),
            'hydrate' => array(
                'strategy' => array(
                    'lastlogintime' => function () {
                        return new DateTimeFormatterStrategy('d-m-Y H:i:s');
                    }
                )
            ),
            'extract' => array(
                'strategy' => array(
                    'lastlogintime' => function () {
                        return new DateTimeFormatterStrategy('c');
                    }
                ),
                'options' => array(
                    'docElementName' => 'users',
                    'elementName' => 'user'
                )
            )
        )
    )
);
