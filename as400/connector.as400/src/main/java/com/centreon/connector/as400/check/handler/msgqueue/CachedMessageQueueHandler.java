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

package com.centreon.connector.as400.check.handler.msgqueue;

import java.io.IOException;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.MessageQueue;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.QueuedMessage;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.ICachedMessageQueueHandler;
import com.centreon.connector.as400.check.handler.impl.AbstractHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;
import com.centreon.connector.as400.utils.BlowFishUtils;

public class CachedMessageQueueHandler extends AbstractHandler implements ICachedMessageQueueHandler {

    static int PAGINATE_SIZE = 50;
    private static Map<String, QueuedMessage> LAST_MESSAGES = java.util.Collections
            .synchronizedMap(new HashMap<String, QueuedMessage>());

    public static String dumpLightMessage(QueuedMessage m) {
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(m.getDate().getTime()).append("] ").append("(").append(m.getSeverity()).append(") ")
                .append(m.getID()).append(":").append(m.getText().replace('|', ' ')).append(" [JobName: ")
                .append(m.getFromJobName()).append("][JobNumber: ").append(m.getFromJobNumber()).append("][User: ")
                .append(m.getUser()).append("]");

        return sb.toString();
    }

    public static String dumpMessage(QueuedMessage m) {
        final String newLine = "\n";
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(m.getDate().getTime()).append("] ").append("(").append(m.getSeverity()).append(") ")
                .append(m.getID()).append(":").append(m.getText().replace('|', ' ')).append(" [JobName: ")
                .append(m.getFromJobName()).append("][JobNumber: ").append(m.getFromJobNumber()).append("][User: ")
                .append(m.getUser()).append("]");

        sb.append("getModificationDate: ").append(m.getModificationDate()).append(newLine).append("getAlertOption: ")
                .append(m.getAlertOption()).append(newLine).append("getCurrentUser: ").append(m.getCurrentUser())
                .append(newLine).append("getDataCcsidConversionStatusIndicator: ")
                .append(m.getDataCcsidConversionStatusIndicator()).append(newLine).append("getDefaultReply: ")
                .append(m.getDefaultReply()).append(newLine).append("getFileName: ").append(m.getFileName()).append(newLine)
                .append("getFromJobName: ").append(m.getFromJobName()).append(newLine).append("getFromJobNumber: ")
                .append(m.getFromJobNumber()).append(newLine).append("getFromProgram: ").append(m.getFromProgram())
                .append(newLine).append("getLibraryName: ").append(m.getLibraryName()).append(newLine).append("getQueue: ")
                .append(m.getQueue()).append(newLine).append("getMessage: ").append(m.getMessage()).append(newLine)
                .append("getMessageFileLibrarySpecified: ").append(m.getMessageFileLibrarySpecified()).append(newLine)
                .append("getMessageHelp: ").append(m.getMessageHelp()).append(newLine).append("getMessageHelpFormat: ")
                .append(m.getMessageHelpFormat()).append(newLine).append("getMessageHelpReplacement: ")
                .append(m.getMessageHelpReplacement()).append(newLine).append("getMessageHelpReplacementandFormat: ")
                .append(m.getMessageHelpReplacementandFormat()).append(newLine).append("getPath: ").append(m.getPath())
                .append(newLine).append("getReceivingModuleName: ").append(m.getReceivingModuleName()).append(newLine)
                .append("getReceivingProcedureName: ").append(m.getReceivingProcedureName()).append(newLine)
                .append("getReceivingProgramInstructionNumber: ").append(m.getReceivingProgramInstructionNumber())
                .append(newLine).append("getReceivingProgramName: ").append(m.getReceivingProgramName()).append(newLine)
                .append("getReceivingType: ").append(m.getReceivingType()).append(newLine).append("getReplyStatus: ")
                .append(m.getReplyStatus()).append(newLine).append("getRequestStatus: ").append(m.getRequestStatus())
                .append(newLine).append("getReceiverStatementNumbers: ").append(m.getReceiverStatementNumbers()).append(newLine)
                .append("getRequestLevel: ").append(m.getRequestLevel()).append(newLine).append("getSenderType: ")
                .append(m.getSenderType()).append(newLine).append("getSendingModuleName: ").append(m.getSendingModuleName())
                .append(newLine).append("getSendingProcedureName: ").append(m.getSendingProcedureName()).append(newLine)
                .append("getSendingProgramInstructionNumber: ").append(m.getSendingProgramInstructionNumber()).append(newLine)
                .append("getSendingProgramName: ").append(m.getSendingProgramName()).append(newLine).append("getSendingType: ")
                .append(m.getSendingType()).append(newLine).append("getSendingUserProfile: ").append(m.getSendingUserProfile())
                .append(newLine).append("getSendingStatementNumbers: ").append(m.getSendingStatementNumbers()).append(newLine)
                .append("getSeverity: ").append(m.getSeverity()).append(newLine).append("getSubstitutionData: ")
                .append(m.getSubstitutionData()).append(newLine).append("getCcsidCodedCharacterSetIdentifierForData: ")
                .append(m.getCcsidCodedCharacterSetIdentifierForData()).append(newLine)
                .append("getCcsidCodedCharacterSetIdentifierForText: ").append(m.getCcsidCodedCharacterSetIdentifierForText())
                .append(newLine).append("getCcsidconversionStatusIndicatorForData: ")
                .append(m.getCcsidconversionStatusIndicatorForData()).append(newLine)
                .append("getCcsidConversionStatusIndicatorForText: ").append(m.getCcsidConversionStatusIndicatorForText())
                .append(newLine);

        return sb.toString();
    }

    public CachedMessageQueueHandler(final String host, final String login, final String password) {
        super(host, login, password);
    }

    @Override
    public ResponseData getNewMessageInMessageQueue(final String messageQueuePath, final String messageIdfilterPattern,
            final int minSeverityLevel, final int maxSeverityLevel)
            throws Exception {

        StringBuilder dbIdentifier = new StringBuilder();
        dbIdentifier.append(messageQueuePath).append(messageIdfilterPattern).append(minSeverityLevel)
                .append(maxSeverityLevel);

        final Collection<QueuedMessage> messages = this.synchronizeDB(messageQueuePath, dbIdentifier.toString());

        if (messages == null) {
            return new ResponseData(ResponseData.statusOk, "Initialisation of the local DB");
        }

        final ResponseData data = new ResponseData();

        for (final QueuedMessage message : messages) {
            if ((message.getSeverity() >= minSeverityLevel) && (message.getSeverity() < maxSeverityLevel)) {
                if ("A".equals(message.getReplyStatus())) {
                    // The message has been acknowledge already and we don't take it into account
                    continue;
                }

                final String messageId = message.getID();
                if (messageIdfilterPattern != null && !messageId.matches(messageIdfilterPattern)) {
                    continue;
                }

                HashMap<String, Object> attrs = new HashMap<String, Object>();
                attrs.put("id", messageId);
                attrs.put("text", message.getText());
                attrs.put("severity", message.getSeverity());
                attrs.put("date", message.getDate().getTimeInMillis());
                attrs.put("jobName", message.getFromJobName());
                attrs.put("jobNumber", message.getFromJobNumber());
                attrs.put("user", message.getUser());
                data.getResult().add(attrs);
            }
        }

        return data;
    }

    /**
     * Synchronize DB and return the new messages
     *
     * @param messageQueuePath
     * @return the new messages
     * @throws AS400SecurityException
     * @throws IOException
     * @throws ErrorCompletingRequestException
     * @throws InterruptedException
     * @throws ObjectDoesNotExistException
     */
    private Collection<QueuedMessage> synchronizeDB(final String messageQueuePath, final String dbIdentifier)
            throws AS400SecurityException, IOException, ErrorCompletingRequestException, InterruptedException,
            ObjectDoesNotExistException {

        String key = BlowFishUtils.encrypt(host + login + dbIdentifier);
        QueuedMessage previousLastMessage = CachedMessageQueueHandler.LAST_MESSAGES.get(key);

        final AS400 system = this.getNewAs400();
        final MessageQueue queue = new MessageQueue(system, messageQueuePath);
        queue.setListDirection(false);

        Collection<QueuedMessage> newMessages = null;

        if (previousLastMessage == null) {
            final QueuedMessage[] messages = queue.getMessages(0, 1);
            CachedMessageQueueHandler.LAST_MESSAGES.put(key, messages[0]);
        } else {
            newMessages = new LinkedList<QueuedMessage>();
            int position = 0;
            final int lenght = queue.getLength();
            boolean foundMessage = false;
            boolean firstLoop = true;

            ConnectorLogger.getInstance().trace("*********************************************************");
            ConnectorLogger.getInstance().trace("    Check message for key: " + key);
            ConnectorLogger.getInstance().trace("    Last message was: ");
            ConnectorLogger.getInstance().trace(CachedMessageQueueHandler.dumpLightMessage(previousLastMessage));

            while (position < lenght && !foundMessage) {
                final QueuedMessage[] messages = queue.getMessages(position, CachedMessageQueueHandler.PAGINATE_SIZE);
                position += CachedMessageQueueHandler.PAGINATE_SIZE;

                for (QueuedMessage message : messages) {
                    if (firstLoop) {
                        firstLoop = false;
                        CachedMessageQueueHandler.LAST_MESSAGES.put(key, message);
                        ConnectorLogger.getInstance().trace("   New message is:");
                        ConnectorLogger.getInstance().trace(CachedMessageQueueHandler.dumpLightMessage(message));
                    }
                    if (this.customMessageEquals(message, previousLastMessage)
                            || message.getDate().before(previousLastMessage.getDate())) {
                        foundMessage = true;
                        break;
                    } else {
                        newMessages.add(message);
                    }
                }
            }
        }
        system.disconnectService(AS400.COMMAND);
        system.disconnectAllServices();

        return newMessages;
    }

    /**
     * 
     * @param a Message to compare with
     * @param b Message to compare to
     * @return True if all the used fields are equals. False otherwise.
     */
    private boolean customMessageEquals(QueuedMessage a, QueuedMessage b) {
        if (a == null) {
            if (b == null) {
                return true;
            } else {
                return false;
            }
        }
        if (b == null) {
            return false;
        }

        if (a.getDate() == null) {
            if (b.getDate() != null)
                return false;
        } else {
            if (!a.getDate().equals(b.getDate()))
                return false;
        }

        if (a.getSeverity() != b.getSeverity())
            return false;

        if (a.getID() == null) {
            if (b.getID() != null)
                return false;
        } else {
            if (!a.getID().equals(b.getID()))
                return false;
        }

        if (a.getText() == null) {
            if (b.getText() != null)
                return false;
        } else {
            if (!a.getText().equals(b.getText()))
                return false;
        }

        if (a.getFromJobName() == null) {
            if (b.getFromJobName() != null)
                return false;
        } else {
            if (!a.getFromJobName().equals(b.getFromJobName()))
                return false;
        }

        if (a.getFromJobNumber() == null) {
            if (b.getFromJobNumber() != null)
                return false;
        } else {
            if (!a.getFromJobNumber().equals(b.getFromJobNumber()))
                return false;
        }

        if (a.getUser() == null) {
            if (b.getUser() != null)
                return false;
        } else {
            if (!a.getUser().equals(b.getUser()))
                return false;
        }
        return true;
    }
}
