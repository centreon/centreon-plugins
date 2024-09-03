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
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Locale;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ConnectionEvent;
import com.ibm.as400.access.ConnectionListener;
import com.ibm.as400.access.SocketProperties;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;

/**
 * @author Lamotte Jean-Baptiste
 */
public abstract class AbstractHandler {

    private static NumberFormat formatterNoDecimal;
    private static NumberFormat formatterTreeDecimal;

    protected String host = null;
    protected String login = null;
    protected String password = null;

    public AbstractHandler(final String host, final String login, final String password) {
        this.host = host;
        this.login = login;
        this.password = password;
    }

    static {
        final DecimalFormat df0 = (DecimalFormat) NumberFormat.getNumberInstance(Locale.ENGLISH);
        df0.applyPattern("#0");
        AbstractHandler.formatterNoDecimal = df0;

        final DecimalFormat df3 = (DecimalFormat) NumberFormat.getNumberInstance(Locale.ENGLISH);
        df3.applyPattern("#0.###");
        AbstractHandler.formatterTreeDecimal = df3;
    }

    static NumberFormat getFormatterNoDecimal() {
        return AbstractHandler.formatterNoDecimal;
    }

    static NumberFormat getFormatterTreeDecimal() {
        return AbstractHandler.formatterTreeDecimal;
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
