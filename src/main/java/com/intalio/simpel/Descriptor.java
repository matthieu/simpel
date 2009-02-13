package com.intalio.simpel;

/**
 * Deployment level information about a process.
 */
public class Descriptor {

    private String address;
    private boolean restful = true;
    private boolean inmem = false;

    /**
     * @return address of the root RESTful resource that the process implements. 
     */
    public String getAddress() {
        return address;
    }

    /**
     * For a RESTful process, sets the root resource address that the process implements.
     * @param address ex: "/calendar"
     */
    public void setAddress(String address) {
        this.address = address;
    }

    /**
     * Whether the deployed process follows the RESTful or SOAP style. Defaults to true.
     * @return true if restful
     */
    public boolean isRestful() {
        return restful;
    }

    /**
     * Declare whether this process follows the RESTful or SOAP style. Processes are RESTful by default.
     * @param restful
     */
    public void setRestful(boolean restful) {
        this.restful = restful;
    }

    /**
     * True for in-memory processes. The execution of a transient process won't touch the database.
     * @return
     */
    public boolean isTransient() {
        return inmem;
    }

    public void setTransient(boolean t) {
        inmem = t;
    }
}
