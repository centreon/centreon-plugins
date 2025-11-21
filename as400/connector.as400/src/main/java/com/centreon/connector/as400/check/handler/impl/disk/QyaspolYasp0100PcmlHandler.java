/*
 * Copyright 2021 Centreon (http://www.centreon.com/)
 *
 * Centreon is a full-fledged industry-strength solution that meets
 * the needs in IT infrastructure and application monitoring for
 * service performance.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, 
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 * See the License for the specific language governing permissions and 
 * limitations under the License.
 */

package com.centreon.connector.as400.check.handler.impl.disk;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Message;
import com.ibm.as400.data.PcmlException;
import com.ibm.as400.data.ProgramCallDocument;

/**
 * @author Lamotte Jean-Baptiste
 */
public class QyaspolYasp0100PcmlHandler {
    AS400 system = null;

    ProgramCallDocument pcml; // com.ibm.as400.data.ProgramCallDocument
    HashMap<String, Yasp0100Data> disks = new HashMap<String, Yasp0100Data>();

    long lastLoad = 0;

    int totalRecord = -1;

    int rcdsReturned = -1;

    byte[] rqsHandle = null;

    public QyaspolYasp0100PcmlHandler(final AS400 system) {
        this.system = system;

    }

    public void addYasp0100Data(final Yasp0100Data data) {
        this.disks.put(data.getResourceName(), data);
    }

    public boolean callProgram(final String programName) throws PcmlException {

        // Request to call the API
        final boolean rc = this.pcml.callProgram(programName);
        if (rc == false) {
            this.displayMessageError(this.pcml, programName);
            return false;
        }
        return true;
    }

    public void displayMessageError(final ProgramCallDocument pcml, final String programmName) throws PcmlException {
        // Retrieve list of server messages
        final AS400Message[] msgs = pcml.getMessageList(programmName);

        // Iterate through messages and write them to standard output
        for (final AS400Message msg : msgs) {
            final String msgId = msg.getID();
            final String msgText = msg.getText();
            System.out.println("    " + msgId + " - " + msgText);
        }
    }

    public Yasp0100Data getDiskByResourceName(final String name) {
        return this.disks.get(name);
    }

    public List<Yasp0100Data> getDisksList() {
        final List<Yasp0100Data> list = new LinkedList<Yasp0100Data>();
        list.addAll(this.disks.values());
        return list;
    }

    public List<String> getResourceNameList() {
        final LinkedList<String> list = new LinkedList<String>();
        list.addAll(this.disks.keySet());
        return list;
    }

    public synchronized void load() throws PcmlException {
        if (System.currentTimeMillis() < (this.lastLoad + (10 * 1000))) {
            return;
        }
        this.lastLoad = System.currentTimeMillis();

        this.pcml = new ProgramCallDocument(this.system, "com.centreon.connector.as400.box.system.disk.qyaspol100.pcml");

        this.callProgram("qyaspol");
        this.loadListInfo("qyaspol");
        this.addYasp0100Data(this.loadYasp0100(this.pcml, "qyaspol"));

        if (this.totalRecord > 1) {
            for (int i = 1; i <= this.totalRecord; i++) {
                this.pcml.setValue("qgygtle.requestHandle", this.rqsHandle);
                this.pcml.setIntValue("qgygtle.startingRcd", i);
                this.callProgram("qgygtle");
                this.addYasp0100Data(this.loadYasp0100(this.pcml, "qgygtle"));
            }
        }
        this.pcml.setValue("qgyclst.requestHandle", this.rqsHandle);
        this.callProgram("qgyclst");
    }

    public void loadListInfo(final String programName) throws PcmlException {
        this.totalRecord = this.pcml.getIntValue(programName + ".listInfo.totalRcds");
        this.rcdsReturned = this.pcml.getIntValue(programName + ".listInfo.rcdsReturned");
        this.rqsHandle = (byte[]) this.pcml.getValue(programName + ".listInfo.rqsHandle");
    }

    public Yasp0100Data loadYasp0100(final ProgramCallDocument pcml, final String programName) throws PcmlException {
        final int[] indices = new int[1];
        indices[0] = 0;

        final Yasp0100Data data = new Yasp0100Data();
        data.setResourceName(pcml.getStringValue(programName + ".receiver.resourceName", indices));

        return data;
    }
}
