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

package com.centreon.connector.as400.dispatcher.client;

import java.io.IOException;

import com.ibm.as400.access.AS400SecurityException;
import com.centreon.connector.as400.client.impl.NetworkClient;
import com.centreon.connector.as400.daemon.DelayedConnectionException;

public interface ClientDispatcher {
    void dispatch(final NetworkClient client) throws AS400SecurityException, IOException, DelayedConnectionException, Exception;
}
