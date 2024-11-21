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

package com.centreon.connector.as400.client.impl;

import io.undertow.util.HttpString;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;
import io.undertow.io.Receiver.FullBytesCallback;

import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.client.IClient;

/**
 * @author Lamotte Jean-Baptiste
 */
public class NetworkClient extends AbstractClient implements IClient {
    private HttpServerExchange exchange = null;
    private String rawRequest = null;

    public NetworkClient(final HttpServerExchange exchange) {
        super();
        this.exchange = exchange;
    }

    public void readRequest() throws Exception {
        HttpString method = exchange.getRequestMethod();

        if (method.toString().equals("POST") == false) {
            throw new Exception("Unsupported method");
        }

        this.exchange.getRequestReceiver().receiveFullBytes(new FullBytesCallback() {
            @Override
            public void handle(HttpServerExchange exchange, byte[] message) {
                rawRequest = new String(message);
            }
        });
    }

    @Override
    protected void writeAnswer(final String answer) {
        ConnectorLogger.getInstance().debug("--------------------");
        ConnectorLogger.getInstance().debug("request : " + this.getRawRequest());
        ConnectorLogger.getInstance().debug("answer : \n" + answer);
        ConnectorLogger.getInstance().debug("--------------------");

        this.exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "application/json");
        this.exchange.getResponseSender().send(answer);
        this.exchange.endExchange();
    }

    private void clean() {
    }

    @Override
    public String getRawRequest() {
        return this.rawRequest;
    }

    public HttpServerExchange getExchange() {
        return this.exchange;
    }
}
