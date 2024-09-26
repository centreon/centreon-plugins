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

package com.centreon.connector.as400.check.handler.impl.jobqueue;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Message;
import com.ibm.as400.data.ProgramCallDocument;

/**
 * @author Lamotte Jean-Baptiste
 */
public class Qsprjobq100Handler {
    private final String pcmlFile = "qsprjobq100.pcml";

    private AS400 system = null;

    public Qsprjobq100Handler(final AS400 system) {
        this.system = system;
    }

    private void displayMessageError(final ProgramCallDocument pcml, final String programmName) throws Exception {
        final AS400Message[] msgs = pcml.getMessageList(programmName);

        for (final AS400Message msg : msgs) {
            final String msgId = msg.getID();
            final String msgText = msg.getText();
            throw new Exception("" + msgId + " - " + msgText);
        }
    }

    public Jobq0100 loadJobq0100(final String jobqName, final String lib) throws Exception {

        String qualifiedQueueName = jobqName;
        while (qualifiedQueueName.length() < 10) {
            qualifiedQueueName += " ";
        }
        qualifiedQueueName += lib;

        final ProgramCallDocument pcml = new ProgramCallDocument(this.system, this.pcmlFile);

        pcml.setValue("qsprjobq.receiverLength", pcml.getOutputsize("qsprjobq.receiver"));
        pcml.setValue("qsprjobq.qualifiedJobQueueName", qualifiedQueueName);
        // pcml.setValue("qsprjobq.qualifiedJobQueueName", jobqName);

        // If return code is false, we received messages from the server
        if (pcml.callProgram("qsprjobq") == false) {
            this.displayMessageError(pcml, "qsprjobq");
        } else {
            final int[] indices = new int[1];
            indices[0] = 0;

            final Jobq0100 jobq0100 = new Jobq0100();

            jobq0100.setAuthorityCheck(pcml.getStringValue("qsprjobq.receiver.authorityCheck", indices));
            jobq0100.setBytesAvailable(pcml.getIntValue("qsprjobq.receiver.bytesAvailable", indices));
            jobq0100.setBytesReturned(pcml.getIntValue("qsprjobq.receiver.bytesReturned", indices));
            jobq0100.setCurrentActive(pcml.getIntValue("qsprjobq.receiver.currentActive", indices));
            jobq0100.setJobqLibName(pcml.getStringValue("qsprjobq.receiver.jobqLibName", indices));
            jobq0100.setJobqName(pcml.getStringValue("qsprjobq.receiver.jobqName", indices));
            jobq0100.setJobQueueStatus(pcml.getStringValue("qsprjobq.receiver.jobQueueStatus", indices));
            jobq0100.setMaximumActive(pcml.getIntValue("qsprjobq.receiver.maximumActive", indices));
            jobq0100.setNumberOfJob(pcml.getIntValue("qsprjobq.receiver.numberOfJob", indices));
            jobq0100.setOperatorControlled(pcml.getStringValue("qsprjobq.receiver.operatorControlled", indices));
            jobq0100.setSequenceNumber(pcml.getIntValue("qsprjobq.receiver.sequenceNumber", indices));
            jobq0100.setSubSystemLibName(pcml.getStringValue("qsprjobq.receiver.subSystemLibName", indices));
            jobq0100.setSubSystemName(pcml.getStringValue("qsprjobq.receiver.subSystemName", indices));
            jobq0100.setTextDescription(pcml.getStringValue("qsprjobq.receiver.textDescription", indices));

            return jobq0100;
        }
        return null;
    }
}
