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

import java.io.IOException;
import java.io.FileInputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Collections;
import java.util.List;

import io.undertow.Undertow;
import io.undertow.UndertowOptions;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.HttpString;

import io.undertow.security.api.AuthenticationMechanism;
import io.undertow.security.api.AuthenticationMode;
import io.undertow.security.api.SecurityContext;
import io.undertow.security.handlers.AuthenticationCallHandler;
import io.undertow.security.handlers.AuthenticationConstraintHandler;
import io.undertow.security.handlers.AuthenticationMechanismsHandler;
import io.undertow.security.handlers.SecurityInitialHandler;
import io.undertow.security.idm.IdentityManager;
import io.undertow.security.impl.BasicAuthenticationMechanism;

import java.security.KeyStore;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;

import com.centreon.connector.as400.daemon.MapIdentityManager;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.client.impl.NetworkClient;

/**
 * The Class DaemonCore.
 * 
 * @author Lamotte Jean-Baptiste
 */
public class Daemon {
    /**
     * execute.
     * 
     */
    public void start(int port) throws Exception, IOException, InterruptedException {
        Undertow server;
        
        Undertow.Builder builder = Undertow.builder();

        builder.setServerOption(UndertowOptions.NO_REQUEST_TIMEOUT, Conf.daemonNoRequestTimeout)
            .setServerOption(UndertowOptions.REQUEST_PARSE_TIMEOUT, Conf.daemonRequestParseTimeout);

        if (Conf.keyStoreFile != null) {
            try {
                ClassLoader classLoader = Thread.currentThread().getContextClassLoader();

                KeyStore keyStore = KeyStore.getInstance(Conf.keyStoreType);
                FileInputStream stream = new FileInputStream(Conf.keyStoreFile);
                if (stream == null) {
                    throw new Exception("keystore file not found: " + Conf.keyStoreFile);
                }

                keyStore.load(
                        stream,
                        Conf.keyStorePassword.toCharArray());
                KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                keyManagerFactory.init(keyStore, Conf.keyStorePassword.toCharArray());

                SSLContext sslContext;
                sslContext = SSLContext.getInstance(Conf.sslProtocol);

                sslContext.init(keyManagerFactory.getKeyManagers(), null, null);
                builder.addHttpsListener(port, Conf.daemonListenerHost, sslContext);
            } catch (final Exception e) {
                throw new Exception(e);
            }
        } else {
            builder.addHttpListener(port, Conf.daemonListenerHost);
        }

        if (Conf.authUsername != null && Conf.authPassword != null) {
            final Map<String, char[]> users = new HashMap<String, char[]>(1);
            users.put(Conf.authUsername, Conf.authPassword.toCharArray());

            final IdentityManager identityManager = new MapIdentityManager(users);

            server = builder.setHandler(addSecurity(new HttpHandler() {
                    @Override
                    public void handleRequest(final HttpServerExchange exchange) throws Exception {
                        NewtworkRunnable network = new NewtworkRunnable(new NetworkClient(exchange));
                        network.run();
                    }
                }, identityManager))
                .build();
        } else {
            server = builder.setHandler(new HttpHandler() {
                @Override
                public void handleRequest(final HttpServerExchange exchange) throws Exception {
                    NewtworkRunnable network = new NewtworkRunnable(new NetworkClient(exchange));
                    network.run();
                }
            }).build();
        }
        server.start();
    
        while (true) {
            Thread.sleep(10000);
        }
    }

    private static HttpHandler addSecurity(final HttpHandler toWrap, final IdentityManager identityManager) {
        HttpHandler handler = toWrap;
        handler = new AuthenticationCallHandler(handler);
        handler = new AuthenticationConstraintHandler(handler);
        final List<AuthenticationMechanism> mechanisms = Collections.<AuthenticationMechanism>singletonList(new BasicAuthenticationMechanism("My Realm"));
        handler = new AuthenticationMechanismsHandler(handler, mechanisms);
        handler = new SecurityInitialHandler(AuthenticationMode.PRO_ACTIVE, identityManager, handler);
        return handler;
    }
}
