<?php

namespace Pay4Later\PDT\Serializer\Adapter;

use DOMDocument;
use Exception;
use Prewk\XmlStringStreamer;

class XmlClass extends AbstractClassAdapter
{
    /**
     * @var XmlClassOptions
     */
    protected $options = null;

    /**
     * @param object|object[] $value
     * @return string
     * @throws Exception
     */
    public function serialize($value)
    {
        $hydrator = $this->buildHydrator('xml', 'extract');

        $class = $this->getOptions()->getClass();
        $docElementName = $this->getOptions()->getDocElementName();
        $elementName = $this->getOptions()->getElementName();

        $doc = new DOMDocument('1.0', 'UTF-8');
        $doc->formatOutput = true;
        $docElement = $doc->appendChild($doc->createElement($docElementName));

        /**
         * @var object $object
         */
        foreach ((array)$value as $object) {
            if (!$object instanceof $class) {
                throw new Exception("serialize expects classes to be of type $class");
            }

            $data = $hydrator->extract($object);
            $child = $doc->createElement($elementName);

            foreach ($data as $k => $v) {
                $child->appendChild($doc->createElement($k, $v));
            }

            $docElement->appendChild($child);
        }

        return $doc->saveXML();
    }

    /**
     * @param string|XmlStringStreamer $xml
     * @return object[]
     */
    public function unserialize($xml)
    {
        $hydrator = $this->buildHydrator('xml', 'hydrate');

        $class = $this->getOptions()->getClass();
        $classes = array();

        if ($xml instanceof XmlStringStreamer) {
            while ($node = $xml->getNode()) {
                $node = simplexml_load_string($node);
                $classes[] = $hydrator->hydrate((array)$node, new $class());
            }
        } else {
            $docElement = simplexml_load_string($xml)->children();
            $name = $docElement->getName();
            foreach ($docElement->$name as $node) {
                $classes[] = $hydrator->hydrate((array)$node, new $class());
            }
        }

        return $classes;
    }
}
