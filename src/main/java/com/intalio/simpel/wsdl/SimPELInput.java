package com.intalio.simpel.wsdl;

import javax.wsdl.Input;
import javax.wsdl.Message;
import javax.xml.namespace.QName;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public class SimPELInput extends SimPELWSDLElement implements Input {
    private String name;
    private SimPELMessage _message;

    public SimPELInput(QName msgName) {
        name = "Request";
        _message = new SimPELMessage(msgName);
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
