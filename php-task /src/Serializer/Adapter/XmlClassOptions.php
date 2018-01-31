<?php

namespace Pay4Later\PDT\Serializer\Adapter;

use Zend\Serializer\Exception;

class XmlClassOptions extends ClassOptions
{
    const OPTION_DOC_ELEMENT_NAME = 'docElementName';
    const OPTION_ELEMENT_NAME = 'elementName';

    private $docElementName = 'nodes';
    private $elementName = 'node';

    /**
     * @return string
     */
    public function getElementName()
    {
        return $this->elementName;
    }

    /**
     * @param string $elementName
     * @return $this
     */
    public function setElementName($elementName)
    {
        $this->elementName = $elementName;
        return $this;
    }

    /**
     * @return string
     */
    public function getDocElementName()
    {
        return $this->docElementName;
    }

    /**
     * @param string $docElementName
     * @return $this
     */
    public function setDocElementName($docElementName)
    {
        $this->docElementName = $docElementName;
        return $this;
    }
}
