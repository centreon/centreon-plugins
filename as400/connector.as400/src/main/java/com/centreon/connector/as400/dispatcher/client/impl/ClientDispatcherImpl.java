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

package com.centreon.connector.as400.dispatcher.client.impl;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.ibm.as400.access.AS400SecurityException;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.client.impl.NetworkClient;
import com.centreon.connector.as400.daemon.DelayedConnectionException;
import com.centreon.connector.as400.dispatcher.check.CheckDispatcher;
import com.centreon.connector.as400.dispatcher.client.ClientDispatcher;

/**
 * @author Lamotte Jean-Baptiste
 */
public class ClientDispatcherImpl implements ClientDispatcher {

    private volatile Map<CheckDispatcher, Long> pool = null;

    private static ClientDispatcherImpl instance = null;

    public static synchronized ClientDispatcherImpl getInstance() {
        if (ClientDispatcherImpl.instance == null) {
            ClientDispatcherImpl.instance = new ClientDispatcherImpl();
        }
        return ClientDispatcherImpl.instance;
    }

    private ClientDispatcherImpl() {
        this.pool = new ConcurrentHashMap<CheckDispatcher, Long>();
    }

    private synchronized CheckDispatcher createNewCheckDispatcher(final String host, final String login,
            final String password) throws AS400SecurityException, IOException, DelayedConnectionException, Exception {

        ConnectorLogger.getInstance().info("create new As400 : " + host);

        CheckDispatcher resource = null;
        resource = new CheckDispatcher(host, login, password);

        this.pool.put(resource, System.currentTimeMillis());

        return resource;
    }

    private CheckDispatcher getAs400(final String host, final String login, final String password)
            throws AS400SecurityException, IOException, DelayedConnectionException, Exception {

        for (final CheckDispatcher resource : this.pool.keySet()) {
            if (resource.getHost().equalsIgnoreCase(host) && resource.getLogin().equalsIgnoreCase(login)
                    && resource.getPassword().equalsIgnoreCase(password)) {
                this.pool.put(resource, System.currentTimeMillis());
                return resource;
            }
        }

        return this.createNewCheckDispatcher(host, login, password);
    }

    @Override
    public synchronized void dispatch(final NetworkClient client)
            throws AS400SecurityException, IOException, DelayedConnectionException, Exception {
        final CheckDispatcher checkDispatcher = this.getAs400(client.getAs400Host(), client.getAs400Login(),
                client.getAs400Password());
        checkDispatcher.dispatch(client);
    }
}
