/*
 * SimPEL Process Execution Language
 * Copyright (C) 2008-2009  Intalio
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.intalio.simpel;

import junit.framework.TestCase;
import com.intalio.simpel.util.DefaultErrorListener;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.List;

import org.junit.Ignore;

/**
 * @author Matthieu Riou <mriou@intalio.com>
 */
public class SimPELCompilerTest extends TestCase {

    Descriptor desc;

    public SimPELCompilerTest() {
        super();
        desc = new Descriptor();
        desc.setRestful(false);
    }

    public void testAllOk() throws Exception {
        compileAllInFile("compile-tests-ok.simpel", true);
    }

    public void testAllKo() throws Exception {
        compileAllInFile("compile-tests-ko.simpel", false);
    }

    /**
     * If this was Ruby, I'd just dynamically create methods for each tested process
     * and we'd have one clean method for each test case. But this is Java so there's
     * only one reported test for all the processes.
     * @throws Exception
     */
    private void compileAllInFile(String file, boolean forSuccess) throws Exception {
        BufferedReader reader = new BufferedReader(new FileReader(
                getClass().getClassLoader().getResource(file).getFile()));

        int testCount = 0;
        String line;
        StringBuffer processBody = new StringBuffer();
        SimPELCompiler comp = new SimPELCompiler();
        boolean failed = false;
        String testCaseName = "";

        // Priming the pump
        while (!reader.readLine().startsWith("#="));
        testCaseName = reader.readLine().trim().substring(2);
        reader.readLine();reader.readLine();

        while ((line = reader.readLine()) != null) {
            if (line.trim().startsWith("#=")) {
                // Found next test case divider, process is complete so we can compile
                try {
                    comp.compileProcess(processBody.toString(), desc);
                    System.out.println("Test case " + testCaseName + " compiled properly.");
                    if (!forSuccess) failed = true;
                } catch (CompilationException e) {
                    System.out.println("There were errors while compiling test case " + testCaseName);
                    System.out.println(e);
                    if (forSuccess) failed = true;
                }
                testCount++;

                // Preparing for next test case
                testCaseName = reader.readLine().trim().substring(2);
                reader.readLine();reader.readLine();
                processBody = new StringBuffer();
                comp.setErrorListener(new DefaultErrorListener());
            } else {
                processBody.append(line).append("\n");
            }
        }

        // And the last one
        try {
            comp.compileProcess(processBody.toString(), desc);
        } catch (CompilationException e) {
            System.err.println("There were errors while compiling test case " + testCaseName);
            System.err.println(e);
            if (forSuccess) failed = true;
        }
        testCount++;

        if (failed) {
            fail("There were failures.");
        } else {
            System.out.println("\nTested " + testCount + " processes successfully.");
        }
    }

    public void testAuction() throws Exception {
        SimPELCompiler c = compiler();
        c.compileProcess(readProcess("auction.simpel"), desc);
        reportErrors("Auction service", c);
    }

    // These two are full of [..] embedded XPath which has been removed (conflicts with
    // arrays). TODO see whether to remove that entirely
//    public void testLoanApproval() throws Exception {
//        SimPELCompiler c = compiler();
//        c.compileProcess(readProcess("loan-approval.simpel"), desc);
//        reportErrors("Loan approval", c);
//    }
//
//    public void testTaskManager() throws Exception {
//        SimPELCompiler c = compiler();
//        c.compileProcess(readProcess("task-manager.simpel"), desc);
//        reportErrors("Auction service", c);
//    }

    private String readProcess(String fileName) throws Exception {
        BufferedReader reader = new BufferedReader(new FileReader(
                getClass().getClassLoader().getResource(fileName).getFile()));

        String line;
        StringBuffer processText = new StringBuffer();
        while ((line = reader.readLine()) != null) processText.append(line).append("\n");
        return processText.toString();
    }

    private SimPELCompiler compiler() {
        TestErrorListener l = new TestErrorListener();
        SimPELCompiler comp = new SimPELCompiler();
        comp.setErrorListener(l);
        return comp;
    }

    private void reportErrors(String testName, SimPELCompiler c) {
        if (((TestErrorListener)c.getErrorListener()).messages.toString().length() > 0) {
            System.out.println(testName+" failed to compile:\n");
            System.out.println(((TestErrorListener)c.getErrorListener()).messages.toString());
            fail("There were failures.");
        }
    }

    private static class TestErrorListener implements ErrorListener {
        public StringBuffer messages = new StringBuffer();

        public List<CompilationException.Error> getErrors() {
            return null;
        }

        public void reportRecognitionError(int line, int column, String message, Exception e) {
            messages.append(" - line ").append(line).append(": ").append(message).append("\n");
        }
    }
}
