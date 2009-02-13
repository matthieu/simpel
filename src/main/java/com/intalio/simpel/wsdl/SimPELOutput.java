package com.intalio.simpel.wsdl;

import javax.wsdl.Message;
import javax.wsdl.Output;
import javax.xml.namespace.QName;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELOutput extends SimPELWSDLElement implements Output {
    private String name;
    private SimPELMessage _message;

    public SimPELOutput(QName msgName) {
        this.name = "Response";
        _message =  new SimPELMessage(msgName);
    }
    public void setName(String s) {
        this.name = s;
    }
    public String getName() {
        return name;
    }
    public void setMessage(Message message) {
    }
    public Message getMessage() {
        return _message;
    }
}
