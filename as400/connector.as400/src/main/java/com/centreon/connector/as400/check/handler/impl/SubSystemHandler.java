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

package com.centreon.connector.as400.check.handler.impl;

import java.io.IOException;
import java.util.Enumeration;
import java.util.HashMap;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Exception;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.ObjectDescription;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.ObjectList;
import com.ibm.as400.access.RequestNotSupportedException;
import com.ibm.as400.access.Subsystem;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.ISubSystemHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class SubSystemHandler extends AbstractHandler implements ISubSystemHandler {

    public SubSystemHandler(final String host, final String login, final String password)
            throws AS400SecurityException, IOException {
        super(host, login, password);
    }

    @Override
    public void dumpSubSystem(final Subsystem subSystem) throws AS400Exception, AS400SecurityException,
            ErrorCompletingRequestException, InterruptedException, IOException, ObjectDoesNotExistException {
        System.out.println("getCurrentActiveJobs : " + subSystem.getCurrentActiveJobs());
        System.out.println("getDescriptionText : " + subSystem.getDescriptionText());
        System.out.println("getDisplayFilePath : " + subSystem.getDisplayFilePath());
        System.out.println("getLanguageLibrary : " + subSystem.getLanguageLibrary());
        System.out.println("getLibrary : " + subSystem.getLibrary());
        System.out.println("getMaximumActiveJobs : " + subSystem.getMaximumActiveJobs());

        subSystem.getMonitorJob();

        System.out.println("getName : " + subSystem.getName());
        System.out.println("getObjectDescription : " + subSystem.getObjectDescription());
        System.out.println("getPath : " + subSystem.getPath());
        System.out.println("getPools (array count) : " + subSystem.getPools().length);
        System.out.println("getStatus : " + subSystem.getStatus());
    }

    @Override
    public ResponseData listSubsystems() throws Exception {
        final ResponseData data = new ResponseData();

        final AS400 system = this.getNewAs400();
        try {
            Subsystem[] list = Subsystem.listAllSubsystems(system);
            for (int i = 0; i < list.length; i++) {
                HashMap<String, Object> attrs = new HashMap<String, Object>();

                list[i].refresh();
                attrs.put("name", list[i].getName());
                attrs.put("path", list[i].getPath());
                attrs.put("library", list[i].getLibrary());
                // *ACTIVE, *ENDING, *INACTIVE, *RESTRICTED, *STARTING
                attrs.put("status", list[i].getStatus());
                attrs.put("currentActiveJobs", list[i].getCurrentActiveJobs());
                data.getResult().add(attrs);                
            }
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            try {
                system.disconnectAllServices();
            } catch (final Exception e1) {
                ConnectorLogger.getInstance().debug("", e);
            }
            throw new Exception(e);
        }
        system.disconnectAllServices();

        return data;
    }
}
