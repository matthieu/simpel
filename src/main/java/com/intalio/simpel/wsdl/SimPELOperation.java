package com.intalio.simpel.wsdl;

import javax.wsdl.*;
import java.util.Map;
import java.util.List;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELOperation extends SimPELWSDLElement implements Operation {
    private String name;
    private Input _input;
    private Output _output;

    public SimPELOperation(String name) {
        this.name = name;
    }
    public void setName(String s) {
        this.name = s;
    }
    public String getName() {
        return name;
    }
    public void setInput(Input input) {
        _input = input;
    }
    public Input getInput() {
        return _input;
    }
    public void setOutput(Output output) {
        _output = output;
    }
    public Output getOutput() {
        return _output;
    }
    public void addFault(Fault fault) {
    }
    public Fault getFault(String s) {
        return null;
    }
    public Fault removeFault(String s) {
        return null;
    }
    public Map getFaults() {
        return null;
    }
    public void setStyle(OperationType operationType) {
    }
    public OperationType getStyle() {
        return null;
    }
    public void setParameterOrdering(List list) {
    }
    public List getParameterOrdering() {
        return null;
    }
    public void setUndefined(boolean b) {
    }
    public boolean isUndefined() {
        return false;
    }
}
