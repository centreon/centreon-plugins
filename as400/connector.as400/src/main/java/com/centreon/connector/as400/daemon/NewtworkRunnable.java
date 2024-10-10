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

package com.centreon.connector.as400.daemon;

import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.client.impl.NetworkClient;
import com.centreon.connector.as400.dispatcher.check.ResponseData;
import com.centreon.connector.as400.dispatcher.client.impl.ClientDispatcherImpl;

/**
 * The Class NewtworkRunnable.
 * 
 * @author Lamotte Jean-Baptiste
 */
class NewtworkRunnable implements Runnable {
    private NetworkClient client = null;

    /**
     * Instantiates a new newtwork runnable.
     * 
     * @param client the client
     */
    NewtworkRunnable(final NetworkClient client) {
        this.client = client;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Runnable#run()
     */
    @Override
    public void run() {
        try {
            try {
                this.client.readRequest();
                this.client.parseRequest();
                ClientDispatcherImpl.getInstance().dispatch(this.client);
            } catch (final java.net.SocketException e) {
                ConnectorLogger.getInstance().debug("", e);
                this.client.writeAnswer(new ResponseData(ResponseData.statusError, "" + e.getMessage()));
            } catch (final Exception e) {
                ConnectorLogger.getInstance().error("", e);
                this.client.writeAnswer(new ResponseData(ResponseData.statusError, "" + e.getMessage()));
            }
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
        }
    }
}
