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

package com.centreon.connector.as400.dispatcher.check;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.ibm.as400.access.AS400SecurityException;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.client.impl.NetworkClient;

/**
 * @author Lamotte Jean-Baptiste
 */
public class CheckHandlerRunnable implements Runnable {

    protected NetworkClient client = null;
    protected CheckDispatcher checkDispatcher = null;

    public CheckHandlerRunnable(final NetworkClient client, final CheckDispatcher checkDispatcher) {
        this.client = client;
        this.checkDispatcher = checkDispatcher;
    }

    public NetworkClient getClient() {
        return this.client;
    }

    private ResponseData getErrorResponse(final String message) {
        return new ResponseData(ResponseData.statusError, message);
    }

    @Override
    public void run() {
        this.client.writeAnswer(this.handleAs400Args(this.client.getAs400CheckType()));
    }

    protected ResponseData handleAs400Args(final String check) {
        ResponseData data = null;

        final String[] args = null;
        final long now = System.currentTimeMillis();

        try {
            if (check.equalsIgnoreCase("listDisks")) {
                data = this.listDisks();
            } else if (check.equalsIgnoreCase("listSubsystems")) {
                data = this.listSubsystems();
            } else if (check.equalsIgnoreCase("listJobs")) {
                data = this.listJobs();
            } else if (check.equalsIgnoreCase("getErrorMessageQueue")) {
                data = this.getErrorMessageQueue();
            } else if (check.equalsIgnoreCase("pageFault")) {
                data = this.checkPageFault();
            } else if (check.equalsIgnoreCase("getSystem")) {
                data = this.getSystem();
            } else if (check.equalsIgnoreCase("getJobQueues")) {
                data = this.getJobQueues();
            } else if (check.equalsIgnoreCase("executeCommand")) {
                data = this.executeCommand();
            } else if (check.equalsIgnoreCase("getNewMessageInMessageQueue")) {
                data = this.getNewMessageInMessageQueue();
            } else if (check.equalsIgnoreCase("workWithProblem")) {
                data = this.workWithProblem();
            } else if (check.equalsIgnoreCase("dumpAll")) {
                this.dumpAll();
                data = new ResponseData(ResponseData.statusOk, "dump done");
            } else {
                data = new ResponseData(ResponseData.statusError, "unknown request : " + check);
                ConnectorLogger.getInstance().debug("unknown request : " + check);
            }
        } catch (final NumberFormatException e) {
            data = new ResponseData(ResponseData.statusError, e.getMessage());
            ConnectorLogger.getInstance().debug("Error during request", e);
        } catch (final AS400SecurityException e) {
            String error = "";
            if (e.getCause() != null) {
                error = e.getCause().getMessage();
            } else {
                error = e.getMessage();
            }
            data = new ResponseData(ResponseData.statusError, error);
            ConnectorLogger.getInstance().debug("Error during request", e);
        } catch (final IOException e) {
            data = new ResponseData(ResponseData.statusError, e.getMessage());
            ConnectorLogger.getInstance().debug("Error during request", e);
        } catch (final Exception e) {
            data = new ResponseData(ResponseData.statusError, e.getMessage());
            ConnectorLogger.getInstance().debug("Error during request", e);
        }

        data.setRequestDuration(System.currentTimeMillis() - now);
        return data;
    }

    private void dumpAll() {
        try {
            checkDispatcher.getSystemHandler().dumpSystem();
        } catch (Exception e) {
            ConnectorLogger.getInstance().error("Failed to dump system measures", e);
            throw new IllegalStateException("Failed to dump system measures", e);
        }
    }

    private ResponseData workWithProblem() throws Exception {
        Object lang = this.client.getAs400Arg("lang");

        final ResponseData data = this.checkDispatcher.getWrkPrbHandler().getProblems(
            lang != null ? lang.toString() : null);

        return data;
    }

    private ResponseData listDisks() throws Exception {
        Object diskName = this.client.getAs400Arg("diskName");

        final ResponseData data = this.checkDispatcher.getDiskHandler().listDisks(
            diskName != null ? diskName.toString() : null);

        return data;
    }

    private ResponseData listJobs() throws Exception {
        ResponseData data = this.checkDispatcher.getJobHandler().listJobs();

        return data;
    }

    private ResponseData executeCommand() throws Exception {
        Object cmdName = this.client.getAs400Arg("cmdName");

        final ResponseData data = this.checkDispatcher.getCommandHandler().executeCommand(
             cmdName != null ? cmdName.toString() : null);

        return data;
    }

    private ResponseData getJobQueues() throws Exception {
        List<Map<String , String>> queues = this.client.getAs400ArgList("queues");

        if (queues == null || queues.size() == 0) {
            return this.getErrorResponse("Invalid arguments. please set jobQueueNames");
        }

        final ResponseData data = this.checkDispatcher.getJobQueueHandler().getJobQueues(queues);

        return data;
    }

    private ResponseData getSystem() throws Exception {
        final ResponseData data = this.checkDispatcher.getSystemHandler().getSystem();

        return data;
    }

    private ResponseData checkPageFault() throws Exception {
        final ResponseData data = this.checkDispatcher.getSystemHandler().getPageFault();

        return data;
    }

    private ResponseData getErrorMessageQueue() throws NumberFormatException, Exception {    
        Object arg = this.client.getAs400Arg("messageQueuePath");
        String messageQueuePath = (arg != null ? arg.toString() : null);
        
        arg = this.client.getAs400Arg("messageIdfilterPattern");
        String messageIdfilterPattern = (arg != null ? arg.toString() : null);

        if (messageQueuePath == null) {
            return this.getErrorResponse("Invalid arguments. please set messageQueuePath");
        }

        int minSeverityLevel;
        try {
            minSeverityLevel = Integer.parseInt(this.client.getAs400Arg("minSeverityLevel").toString());
        } catch (final Exception e) {
            minSeverityLevel = Integer.MIN_VALUE;
        }
        int maxSeverityLevel;
        try {
            maxSeverityLevel = Integer.parseInt(this.client.getAs400Arg("maxSeverityLevel").toString());
        } catch (final Exception e) {
            maxSeverityLevel = Integer.MAX_VALUE;
        }

        final ResponseData data = this.checkDispatcher.getMessageQueueHandler().getErrorMessageQueue(
                messageQueuePath, messageIdfilterPattern, minSeverityLevel, maxSeverityLevel);

        return data;
    }

    private ResponseData getNewMessageInMessageQueue() throws NumberFormatException, Exception {
        Object arg = this.client.getAs400Arg("messageQueuePath");
        String messageQueuePath = (arg != null ? arg.toString() : null);
        
        arg = this.client.getAs400Arg("messageIdfilterPattern");
        String messageIdfilterPattern = (arg != null ? arg.toString() : null);

        if (messageQueuePath == null) {
            return this.getErrorResponse("Invalid arguments. please set messageQueuePath");
        }

        int minSeverityLevel;
        try {
            minSeverityLevel = Integer.parseInt(this.client.getAs400Arg("minSeverityLevel").toString());
        } catch (final Exception e) {
            minSeverityLevel = Integer.MIN_VALUE;
        }
        int maxSeverityLevel;
        try {
            maxSeverityLevel = Integer.parseInt(this.client.getAs400Arg("maxSeverityLevel").toString());
        } catch (final Exception e) {
            maxSeverityLevel = Integer.MAX_VALUE;
        }

        final ResponseData data = this.checkDispatcher.getCachedMessageQueueHandler().getNewMessageInMessageQueue(
                messageQueuePath, messageIdfilterPattern, minSeverityLevel, maxSeverityLevel);

        return data;
    }

    private ResponseData listSubsystems() throws Exception {
        final ResponseData data = this.checkDispatcher.getSubSystemHandler().listSubsystems();

        return data;
    }

}
