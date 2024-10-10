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

import java.util.List;
import java.util.Map;
import java.util.HashMap;

import com.ibm.as400.access.AS400;
import com.centreon.connector.as400.check.handler.IJobQueueHandler;
import com.centreon.connector.as400.check.handler.impl.jobqueue.Jobq0100;
import com.centreon.connector.as400.check.handler.impl.jobqueue.Jobq0200;
import com.centreon.connector.as400.check.handler.impl.jobqueue.Qsprjobq100Handler;
import com.centreon.connector.as400.check.handler.impl.jobqueue.Qsprjobq200Handler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class JobQueueHandler extends AbstractHandler implements IJobQueueHandler {

    public JobQueueHandler(final String host, final String login, final String password) {
        super(host, login, password);
    }

    @Override
    public ResponseData getJobQueues(List<Map<String , String>> queues) throws Exception {
        final ResponseData data = new ResponseData();

        final AS400 system = this.getNewAs400();
        final Qsprjobq200Handler qsprjobq200Handler = new Qsprjobq200Handler(system);

        for (Map<String, String> queue : queues) {
            String name = queue.get("name");
            String library = queue.get("library");

            if (name == null || library == null) {
                return new ResponseData(ResponseData.statusError,
                    "JobQueue name/library attribute must be set");
            }

            Jobq0200 jobq0200 = null;
            try {
                jobq0200 = qsprjobq200Handler.loadJobq0200(name, library);
            } catch (final Exception e) {
                system.disconnectAllServices();
                throw e;
            }
            
            if (jobq0200 == null) {
                return new ResponseData(ResponseData.statusError,
                    "JobQueue " + name + " in library " + library + " not found");
            }

            HashMap<String, Object> attrs = new HashMap<String, Object>();
            attrs.put("name", name);
            attrs.put("library", library);
            // RELEASED, HELD
            attrs.put("status", jobq0200.getJobQueueStatus());
            attrs.put("activeJob", jobq0200.getActiveJobTotal());
            attrs.put("heldJobOnQueue", jobq0200.getHeldJobTotal());
            attrs.put("scheduledJobOnQueue", jobq0200.getScheduledJobTotal());
            data.getResult().add(attrs);
        }

        system.disconnectAllServices();
        return data;
    }
}
