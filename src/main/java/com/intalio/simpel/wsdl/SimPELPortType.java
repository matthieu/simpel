package com.intalio.simpel.wsdl;

import javax.wsdl.PortType;
import javax.wsdl.Operation;
import javax.xml.namespace.QName;
import java.util.LinkedList;
import java.util.List;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELPortType extends SimPELWSDLElement implements PortType {
    private QName _name;
    private LinkedList<Operation> _operations = new LinkedList<Operation>();
    public void setQName(QName qName) {
        _name = qName;
    }
    public QName getQName() {
        return _name;
    }
    public void addOperation(Operation operation) {
        if (getOperation(operation.getName(), null, null) == null)
            _operations.add(operation);
    }
    public Operation getOperation(String name, String inputName, String outputName) {
        for (Operation op : _operations) {
            if (op.getName().equals(name)) return op;
        }
        return null;
    }
    public List getOperations() {
        return _operations;
    }
    public Operation removeOperation(String name, String inputName, String outputName) {
        Operation op = getOperation(name, inputName, outputName);
        if (op != null) _operations.remove(op);
        return op;
    }

    public void setUndefined(boolean b) {
    }
    public boolean isUndefined() {
        return false;
    }
}
