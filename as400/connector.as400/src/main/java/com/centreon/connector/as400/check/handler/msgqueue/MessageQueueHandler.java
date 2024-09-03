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
import java.util.Enumeration;
import java.util.LinkedList;
import java.util.HashMap;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.MessageQueue;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.QueuedMessage;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.IMessageQueueHandler;
import com.centreon.connector.as400.check.handler.impl.AbstractHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class MessageQueueHandler extends AbstractHandler implements IMessageQueueHandler {

    public MessageQueueHandler(final String host, final String login, final String password) {
        super(host, login, password);
    }

    @Override
    public void dumpMessageQueue() throws AS400SecurityException, ErrorCompletingRequestException, InterruptedException,
            IOException, ObjectDoesNotExistException {
        final AS400 system = this.getNewAs400();
        /*
         * MessageQueue messageQueue = new MessageQueue(system);
         * messageQueue.getHelpTextFormatting(); messageQueue.getLength();
         * messageQueue.getListDirection(); messageQueue.getMessages();
         * messageQueue.getMessages(-1, -1); messageQueue.getPath();
         * messageQueue.getSelection(); messageQueue.getSeverity();
         * messageQueue.getSort(); messageQueue.getSystem();
         * messageQueue.getUserStartingMessageKey();
         * messageQueue.getWorkstationStartingMessageKey();
         */
        final MessageQueue queue = new MessageQueue(system, MessageQueue.CURRENT);

        @SuppressWarnings("rawtypes")
        final Enumeration e = queue.getMessages();

        while (e.hasMoreElements()) {
            final QueuedMessage message = (QueuedMessage) e.nextElement();
            System.out.println(message.getText().replace('|', ' '));
        }

    }

    @Override
    public ResponseData getErrorMessageQueue(final String messageQueuePath, final String messageIdfilterPattern,
            final int minSeverityLevel, final int maxSeverityLevel) throws Exception {
        final ResponseData data = new ResponseData();

        final AS400 system = this.getNewAs400();
        try {
            final Collection<QueuedMessage> messagesFound = new LinkedList<QueuedMessage>();

            final MessageQueue queue = new MessageQueue(system, messageQueuePath);

            @SuppressWarnings("rawtypes")
            final Enumeration e = queue.getMessages();

            long errorCount = 0;
            while (e.hasMoreElements()) {

                final QueuedMessage message = (QueuedMessage) e.nextElement();
                ConnectorLogger.getInstance()
                        .debug("Message found : " + message.getID() + " - " + message.getText().replace('|', ' '));

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
        } catch (final Exception e) {
            system.disconnectService(AS400.COMMAND);
            system.disconnectAllServices();
            throw e;
        }
        system.disconnectService(AS400.COMMAND);
        system.disconnectAllServices();

        return data;
    }
}
