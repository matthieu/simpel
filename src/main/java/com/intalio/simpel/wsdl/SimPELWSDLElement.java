package com.intalio.simpel.wsdl;

import org.w3c.dom.Element;

import javax.wsdl.WSDLElement;
import javax.wsdl.extensions.ExtensibilityElement;
import javax.xml.namespace.QName;
import java.util.Map;
import java.util.List;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELWSDLElement implements WSDLElement {
    public void setDocumentationElement(Element element) {
    }
    public Element getDocumentationElement() {
        return null;
    }
    public void setExtensionAttribute(QName qName, Object o) {
    }
    public Object getExtensionAttribute(QName qName) {
        return null;
    }
    public Map getExtensionAttributes() {
        return null;
    }
    public List getNativeAttributeNames() {
        return null;
    }
    public void addExtensibilityElement(ExtensibilityElement extensibilityElement) {
    }
    public ExtensibilityElement removeExtensibilityElement(ExtensibilityElement extensibilityElement) {
        return null;
    }
    public List getExtensibilityElements() {
        return null;
    }
}
