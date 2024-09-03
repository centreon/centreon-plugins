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

import java.util.Collection;
import java.util.HashMap;

import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.Job;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.IJobHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class JobHandler extends AbstractHandler implements IJobHandler {
    private final JobCache jobCache;

    public JobHandler(final String host, final String login, final String password) {
        super(host, login, password);
        this.jobCache = new JobCache(this);
    }

    @Override
    public ResponseData listJobs() throws Exception {
        final ResponseData data = new ResponseData();

        Collection<Job> jobs = this.jobCache.getJobListCache();
        for (final Job job : jobs) {
            HashMap<String, Object> attrs = new HashMap<String, Object>();

            attrs.put("name", job.getName());
            attrs.put("subSystem", job.getSubsystem());
            attrs.put("status", job.getStatus());
            attrs.put("activeStatus", job.getValue(Job.ACTIVE_JOB_STATUS));

            String currentLibrary = "";
            try {
                job.getCurrentLibrary();
            } catch (final Exception e) {
                attrs.put("currentLibraryException", e.getMessage());
            }
            attrs.put("currentLibrary", currentLibrary);

            data.getResult().add(attrs);
        }

        return data;
    }
}
