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

import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Message;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ConnectionEvent;
import com.ibm.as400.access.ConnectionListener;
import com.ibm.as400.access.SocketProperties;
import com.ibm.as400.data.PcmlException;
import com.ibm.as400.data.ProgramCallDocument;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.impl.FailedCheckException;

/**
 * @author Lamotte Jean-Baptiste
 */
public class QyaspolYasp0300PcmlHandler {
    String pcmlFile = "qyaspol300.pcml";

    // AS400 system = null;

    ProgramCallDocument pcml; // com.ibm.as400.data.ProgramCallDocument
    HashMap<String, Yasp0300Data> currentDiskLoad = new HashMap<String, Yasp0300Data>();
    HashMap<String, Yasp0300Data> cachedDiskList = null;
    Exception lastFailException = new Exception("First check");

    long lastLoad = 0;

    int totalRecord = -1;

    int rcdsReturned = -1;

    byte[] rqsHandle = null;

    String host = null;
    String login = null;
    String password = null;

    public QyaspolYasp0300PcmlHandler(final String host, final String login, final String password) {
        this.host = host;
        this.login = login;
        this.password = password;
    }

    public void addYasp0300Data(final Yasp0300Data data) {
        this.currentDiskLoad.put(data.getResourceName(), data);
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

    public Yasp0300Data getDiskByResourceName(final String name) throws Exception {
        this.load();
        if (this.cachedDiskList == null) {
            throw this.lastFailException;
        }
        return this.cachedDiskList.get(name);
    }

    public List<Yasp0300Data> getDisksList() throws Exception {
        this.load();
        if (this.cachedDiskList == null) {
            throw this.lastFailException;
        }
        final List<Yasp0300Data> list = new LinkedList<Yasp0300Data>();
        list.addAll(this.cachedDiskList.values());
        return list;
    }

    public List<String> getResourceNameList() throws Exception {
        this.load();
        if (this.cachedDiskList == null) {
            throw this.lastFailException;
        }
        final LinkedList<String> list = new LinkedList<String>();
        list.addAll(this.cachedDiskList.keySet());
        return list;
    }

    public void load() throws PcmlException {
        if (!((this.lastLoad + Conf.cacheTimeout) < System.currentTimeMillis())) {
            return;
        }

        AS400 system = null;
        try {
            this.currentDiskLoad = new HashMap<String, Yasp0300Data>();

            system = this.getNewAs400();
            this.pcml = new ProgramCallDocument(system, this.pcmlFile);

            this.callProgram("qyaspol");
            this.loadListInfo("qyaspol");
            this.addYasp0300Data(this.loadYasp0300(this.pcml, "qyaspol"));

            if (this.totalRecord > 1) {
                for (int i = 1; i <= this.totalRecord; i++) {
                    this.pcml.setValue("qgygtle.requestHandle", this.rqsHandle);
                    this.pcml.setIntValue("qgygtle.startingRcd", i);
                    this.callProgram("qgygtle");
                    this.addYasp0300Data(this.loadYasp0300(this.pcml, "qgygtle"));
                }
            }

            this.pcml.setValue("qgyclst.requestHandle", this.rqsHandle);
            this.callProgram("qgyclst");

            this.cachedDiskList = this.currentDiskLoad;
            this.lastLoad = System.currentTimeMillis();

        } catch (final com.ibm.as400.data.PcmlException e) {
            if (e.getCause() != null) {
                new FailedCheckException("" + e.getCause().getMessage());
            } else {
                new FailedCheckException("" + e.getMessage());
            }
            this.cachedDiskList = null;
            ConnectorLogger.getInstance().debug("", e);
        } catch (final java.net.UnknownHostException e) {
            this.lastFailException = new FailedCheckException("Invalid hostname for server: " + e.getMessage());
            this.cachedDiskList = null;
            ConnectorLogger.getInstance().debug("", e);
        } catch (final Exception e) {
            System.out.println("plop " + e.getMessage());
            this.lastFailException = new FailedCheckException("" + e.getMessage());
            this.cachedDiskList = null;
            ConnectorLogger.getInstance().debug("", e);
        } finally {
            this.lastLoad = System.currentTimeMillis();
            if (system != null) {
                system.disconnectAllServices();
            }
        }
    }

    public void loadListInfo(final String programName) throws PcmlException {
        this.totalRecord = this.pcml.getIntValue(programName + ".listInfo.totalRcds");
        this.rcdsReturned = this.pcml.getIntValue(programName + ".listInfo.rcdsReturned");
        this.rqsHandle = (byte[]) this.pcml.getValue(programName + ".listInfo.rqsHandle");
    }

    public Yasp0300Data loadYasp0300(final ProgramCallDocument pcml, final String programName) throws PcmlException {
        final int[] indices = new int[1];
        indices[0] = 0;

        final Yasp0300Data data = new Yasp0300Data();

        data.setAspNumber(pcml.getIntValue(programName + ".receiver.aspNumber", indices));
        data.setDiskType(pcml.getStringValue(programName + ".receiver.diskType", indices));
        data.setDiskModel(pcml.getStringValue(programName + ".receiver.diskModel", indices));
        data.setDiskSerialNumber(pcml.getStringValue(programName + ".receiver.diskSerialNumber", indices));
        data.setResourceName(pcml.getStringValue(programName + ".receiver.resourceName", indices));
        data.setDiskUnitNumber(pcml.getIntValue(programName + ".receiver.diskUnitNumber", indices));
        data.setDiskCapacity(pcml.getIntValue(programName + ".receiver.diskCapacity", indices));
        data.setDiskStorageAvailable(pcml.getIntValue(programName + ".receiver.diskStorageAvailable", indices));
        data.setDiskStorageReservedForSystem(
                pcml.getIntValue(programName + ".receiver.diskStorageReservedForSystem", indices));
        data.setMirroredUnitProtected(pcml.getStringValue(programName + ".receiver.mirroredUnitProtected", indices));
        data.setMirroredUnitReported(pcml.getStringValue(programName + ".receiver.mirroredUnitReported", indices));
        data.setMirroredUnitStatus(pcml.getStringValue(programName + ".receiver.mirroredUnitStatus", indices));
        data.setReserved(pcml.getStringValue(programName + ".receiver.reserved", indices));
        data.setUnitControl(pcml.getIntValue(programName + ".receiver.unitControl", indices));
        data.setBlockTransferredToMainStorage(
                pcml.getIntValue(programName + ".receiver.blockTransferredToMainStorage", indices));
        data.setBlockTransferredFromMainStorage(
                pcml.getIntValue(programName + ".receiver.blockTransferredFromMainStorage", indices));
        data.setRequestForDataToMainStorage(
                pcml.getIntValue(programName + ".receiver.requestForDataToMainStorage", indices));
        data.setRequestForDataForMainStorage(
                pcml.getIntValue(programName + ".receiver.requestForDataForMainStorage", indices));
        data.setRequestForPermanentFromMainStorage(
                pcml.getIntValue(programName + ".receiver.requestForPermanentFromMainStorage", indices));
        data.setSampleCount(pcml.getIntValue(programName + ".receiver.sampleCount", indices));
        data.setNotBusyCount(pcml.getIntValue(programName + ".receiver.notBusyCount", indices));
        data.setCompressionStatus(pcml.getStringValue(programName + ".receiver.compressionStatus", indices));
        data.setDiskProtectionType(pcml.getStringValue(programName + ".receiver.diskProtectionType", indices));
        data.setCompressedUnit(pcml.getStringValue(programName + ".receiver.compressedUnit", indices));
        data.setStorageAllocationRestrictedUnit(
                pcml.getStringValue(programName + ".receiver.storageAllocationRestrictedUnit", indices));
        data.setAvailabilityParitySetUnit(
                pcml.getStringValue(programName + ".receiver.availabilityParitySetUnit", indices));
        data.setMultipleConnectionUnit(pcml.getStringValue(programName + ".receiver.multipleConnectionUnit", indices));

        return data;
    }

    protected AS400 getNewAs400() throws AS400SecurityException, IOException {
        final SocketProperties properties = new SocketProperties();
        properties.setSoLinger(1);
        properties.setKeepAlive(false);
        properties.setTcpNoDelay(true);
        properties.setLoginTimeout(Conf.as400LoginTimeout);
        properties.setSoTimeout(Conf.as400ReadTimeout);

        final AS400 system = new AS400(this.host, this.login, this.password);
        system.setSocketProperties(properties);
        system.addConnectionListener(new ConnectionListener() {
            @Override
            public void connected(final ConnectionEvent event) {
                ConnectorLogger.getInstance().getLogger().debug("Connect event service : " + event.getService());
            }

            @Override
            public void disconnected(final ConnectionEvent event) {
                ConnectorLogger.getInstance().getLogger().debug("Disconnect event service : " + event.getService());
            }
        });

        system.validateSignon();

        return system;
    }
}
