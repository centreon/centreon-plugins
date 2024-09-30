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
public class Qsprjobq200Handler {
    private final String pcmlFile = "qsprjobq200.pcml";

    private AS400 system = null;

    public Qsprjobq200Handler(final AS400 system) {
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

    public Jobq0200 loadJobq0200(final String jobqName, final String lib) throws Exception {

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

            final Jobq0200 jobq0200 = new Jobq0200();

            jobq0200.setBytesReturned(pcml.getIntValue("qsprjobq.receiver.bytesReturned", indices));
            jobq0200.setBytesAvailable(pcml.getIntValue("qsprjobq.receiver.bytesAvailable", indices));
            jobq0200.setJobqName(pcml.getStringValue("qsprjobq.receiver.jobqName", indices));
            jobq0200.setJobqLibName(pcml.getStringValue("qsprjobq.receiver.jobqLibName", indices));
            jobq0200.setOperatorControlled(pcml.getStringValue("qsprjobq.receiver.operatorControlled", indices));
            jobq0200.setAuthorityCheck(pcml.getStringValue("qsprjobq.receiver.authorityCheck", indices));
            jobq0200.setNumberOfJob(pcml.getIntValue("qsprjobq.receiver.numberOfJob", indices));
            jobq0200.setJobQueueStatus(pcml.getStringValue("qsprjobq.receiver.jobQueueStatus", indices));
            jobq0200.setSubSystemName(pcml.getStringValue("qsprjobq.receiver.subSystemName", indices));
            jobq0200.setSubSystemLibName(pcml.getStringValue("qsprjobq.receiver.subSystemLibName", indices));
            jobq0200.setTextDescription(pcml.getStringValue("qsprjobq.receiver.textDescription", indices));
            jobq0200.setSequenceNumber(pcml.getIntValue("qsprjobq.receiver.sequenceNumber", indices));
            jobq0200.setMaximumActive(pcml.getIntValue("qsprjobq.receiver.maximumActive", indices));
            jobq0200.setCurrentActive(pcml.getIntValue("qsprjobq.receiver.currentActive", indices));

            jobq0200.setMaxActiveJobPriority1(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority1", indices));
            jobq0200.setMaxActiveJobPriority2(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority2", indices));
            jobq0200.setMaxActiveJobPriority3(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority3", indices));
            jobq0200.setMaxActiveJobPriority4(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority4", indices));
            jobq0200.setMaxActiveJobPriority5(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority5", indices));
            jobq0200.setMaxActiveJobPriority6(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority6", indices));
            jobq0200.setMaxActiveJobPriority7(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority7", indices));
            jobq0200.setMaxActiveJobPriority8(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority8", indices));
            jobq0200.setMaxActiveJobPriority9(pcml.getIntValue("qsprjobq.receiver.maxActiveJobPriority9", indices));

            jobq0200.setActiveJobPriority0(pcml.getIntValue("qsprjobq.receiver.activeJobPriority0", indices));
            jobq0200.setActiveJobPriority1(pcml.getIntValue("qsprjobq.receiver.activeJobPriority1", indices));
            jobq0200.setActiveJobPriority2(pcml.getIntValue("qsprjobq.receiver.activeJobPriority2", indices));
            jobq0200.setActiveJobPriority3(pcml.getIntValue("qsprjobq.receiver.activeJobPriority3", indices));
            jobq0200.setActiveJobPriority4(pcml.getIntValue("qsprjobq.receiver.activeJobPriority4", indices));
            jobq0200.setActiveJobPriority5(pcml.getIntValue("qsprjobq.receiver.activeJobPriority5", indices));
            jobq0200.setActiveJobPriority6(pcml.getIntValue("qsprjobq.receiver.activeJobPriority6", indices));
            jobq0200.setActiveJobPriority7(pcml.getIntValue("qsprjobq.receiver.activeJobPriority7", indices));
            jobq0200.setActiveJobPriority8(pcml.getIntValue("qsprjobq.receiver.activeJobPriority8", indices));
            jobq0200.setActiveJobPriority9(pcml.getIntValue("qsprjobq.receiver.activeJobPriority9", indices));

            jobq0200
                    .setScheduledJobOnQueuePriority0(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority0", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority1(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority1", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority2(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority2", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority3(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority3", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority4(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority4", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority5(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority5", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority6(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority6", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority7(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority7", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority8(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority8", indices));
            jobq0200
                    .setScheduledJobOnQueuePriority9(pcml.getIntValue("qsprjobq.receiver.scheduledJobOnQueuePriority9", indices));

            jobq0200.setHeldJobOnQueuePriority0(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority0", indices));
            jobq0200.setHeldJobOnQueuePriority1(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority1", indices));
            jobq0200.setHeldJobOnQueuePriority2(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority2", indices));
            jobq0200.setHeldJobOnQueuePriority3(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority3", indices));
            jobq0200.setHeldJobOnQueuePriority4(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority4", indices));
            jobq0200.setHeldJobOnQueuePriority5(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority5", indices));
            jobq0200.setHeldJobOnQueuePriority6(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority6", indices));
            jobq0200.setHeldJobOnQueuePriority7(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority7", indices));
            jobq0200.setHeldJobOnQueuePriority8(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority8", indices));
            jobq0200.setHeldJobOnQueuePriority9(pcml.getIntValue("qsprjobq.receiver.heldJobOnQueuePriority9", indices));

            return jobq0200;
        }
        return null;
    }
}
