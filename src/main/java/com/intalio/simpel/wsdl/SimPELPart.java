package com.intalio.simpel.wsdl;

import javax.wsdl.Part;
import javax.xml.namespace.QName;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELPart extends SimPELWSDLElement implements Part {
    private QName _elmtName;

    public SimPELPart(QName elmtName) {
        _elmtName = elmtName;
    }

    public void setName(String s) {
    }

    public String getName() {
        return _elmtName.getLocalPart();
    }

    public void setElementName(QName qName) {
    }

    public QName getElementName() {
        return _elmtName;
    }

    public void setTypeName(QName qName) {
    }

    public QName getTypeName() {
        return null;
    }
}
