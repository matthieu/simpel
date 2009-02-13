package com.intalio.simpel.wsdl;

import javax.wsdl.Message;
import javax.wsdl.Part;
import javax.xml.namespace.QName;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELMessage extends SimPELWSDLElement implements Message {
    private SimPELPart _part;
    private QName _qname;

    public SimPELMessage(QName qname) {
        _qname = qname;
        _part =  new SimPELPart(qname);
    }

    public void setQName(QName qName) {
        this._qname = qName;
    }

    public QName getQName() {
        return _qname;
    }

    public void addPart(Part part) {
    }

    public Part getPart(String s) {
        return _part;
    }

    public Part removePart(String s) {
        return null;
    }

    public Map getParts() {
        HashMap m = new HashMap(1);
        m.put(_part.getName(), _part);
        return m;
    }

    public List getOrderedParts(List list) {
        LinkedList l = new LinkedList();
        l.add(_part);
        return l;
    }

    public void setUndefined(boolean b) {
    }

    public boolean isUndefined() {
        return false;
    }
}
