<?php

namespace Pay4Later\PDT\Serializer\Adapter;

use Zend\Serializer\Adapter\AdapterOptions;
use Zend\Serializer\Exception;

class ClassOptions extends AdapterOptions
{
    const OPTION_CONFIG  = 'config';
    const OPTION_CLASS   = 'class';

    /**
     * @var array
     */
    private $config;

    /**
     * @var string
     */
    private $class;

    /**
     * @return array
     */
    public function getConfig()
    {
        return $this->config;
    }

    /**
     * @param array $config
     * @return $this
     */
    public function setConfig($config)
    {
        $this->config = $config;
        return $this;
    }

    /**
     * @return string
     */
    public function getClass()
    {
        return $this->class;
    }

    /**
     * @param string $class
     * @return $this
     */
    public function setClass($class)
    {
        $this->class = $class;
        return $this;
    }
}
