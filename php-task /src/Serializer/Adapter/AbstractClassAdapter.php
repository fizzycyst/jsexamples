<?php

namespace Pay4Later\PDT\Serializer\Adapter;

use Exception;
use Prewk\XmlStringStreamer;
use Zend\Config\Config;
use Zend\Serializer\Adapter\AbstractAdapter;
use Zend\Stdlib\Hydrator\ClassMethods;
use Zend\Stdlib\Hydrator\NamingStrategy\ArrayMapNamingStrategy;

abstract class AbstractClassAdapter extends AbstractAdapter
{
    /**
     * @var ClassOptions
     */
    protected $options = null;

    /**
     * @param array|\Traversable|ClassOptions $options
     */
    public function __construct($options = null)
    {
        $this->setOptions($options);
    }

    /**
     * @param array|\Traversable|ClassOptions $options
     * @return $this
     */
    public function setOptions($options)
    {
        if (!$options instanceof ClassOptions) {
            $optionsClassName = get_called_class() . 'Options';
            if (!class_exists($optionsClassName)) {
                $optionsClassName = __NAMESPACE__ . '\\ClassOptions';
            }
            $options = new $optionsClassName($options);
        }

        $this->options = $options;
        return $this;
    }

    /**
     * @return ClassOptions
     */
    public function getOptions()
    {
        return $this->options;
    }

    protected function assertOptionsValid()
    {
        if (!class_exists($this->options->getClass())) {
            throw new Exception('Missing OPTION_CLASS');
        }
    }

    protected function buildHydrator($product, $direction)
    {
        $this->assertOptionsValid();

        $config = $this->options->getConfig();
        $class = $this->options->getClass();
        $hydrator = new ClassMethods();
        
        if (!isset($config[$this->options->getClass()][$product])) {
            return $hydrator;
        }

        $tmp = new Config(array());

        if (isset($config[$class]['*'])) {
            $tmp = new Config($config[$class]['*']);
        }

        if (isset($config[$class][$product])) {
            $productConfig = new Config($config[$class][$product]);
            $tmp = $productConfig->merge($tmp);
        }

        $config = $tmp['shared'];

        if (isset($tmp[$direction])) {
            $config->merge($tmp[$direction]);
        }

        $config = $config->toArray();

        if (!empty($config['map'])) {
            $hydrator->setNamingStrategy(new ArrayMapNamingStrategy($config['map']));
        }

        if (!empty($config['strategy'])) {
            foreach ($config['strategy'] as $name => $strategyCallback) {
                $hydrator->addStrategy($name, $strategyCallback());
            }
        }

        if (!empty($config['options'])) {
            $this->options->setFromArray($config['options']);
        }

        return $hydrator;
    }
}
