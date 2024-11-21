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

import java.util.HashMap;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Message;
import com.ibm.as400.access.CommandCall;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.ICommandHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class CommandHandler extends AbstractHandler implements ICommandHandler {

    public CommandHandler(final String host, final String login, final String password) {
        super(host, login, password);
    }

    @Override
    public ResponseData executeCommand(final String commandName) throws Exception {
        final ResponseData data = new ResponseData();
        HashMap<String, Object> attrs = new HashMap<String, Object>();
        attrs.put("cmdName", commandName);
        attrs.put("status", "success");

        final AS400 system = this.getNewAs400();

        final CommandCall command = new CommandCall(system);
        String output = "";
        try {
            if (!command.run(commandName)) {
                attrs.put("status", "failed");
                attrs.put("message", "command run failed");
            }
            for (final AS400Message message : command.getMessageList()) {
                output += message.getText() + "\n";
            }
        } catch (final Exception e) {
            attrs.put("status", "failed");
            attrs.put("message", "exception: " + e.getMessage());
            ConnectorLogger.getInstance().debug("", e);
        }
        attrs.put("output", output);
        data.getResult().add(attrs);

        // Done with the system.
        system.disconnectService(AS400.COMMAND);
        system.disconnectAllServices();

        return data;
    }
}
