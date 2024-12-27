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
import java.util.Enumeration;
import java.util.LinkedList;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.Job;
import com.ibm.as400.access.JobList;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.ConnectorLogger;

class JobCache {
    private volatile LinkedList<Job> lastJobCache = null;
    private long lastRefresh = 0;

    JobHandler handler;
    Exception lastFailException = new Exception("First check");

    JobCache(final JobHandler handler) {
        this.handler = handler;
    }

    Collection<Job> getJobListCache(final boolean forceRefresh) throws Exception {
        this.refreshJobListCache(forceRefresh);
        if (this.lastJobCache == null) {
            throw this.lastFailException;
        }
        return new LinkedList<Job>(this.lastJobCache);
    }

    Collection<Job> getJobListCache() throws Exception {
        return this.getJobListCache(false);
    }

    private void refreshJobListCache(final boolean forceRefresh) throws Exception {
        if (!(((this.lastRefresh + Conf.cacheTimeout) < System.currentTimeMillis()) || forceRefresh)) {
            return;
        }
        final AS400 system = this.handler.getNewAs400();

        final JobList jobList = new JobList(system);
        jobList.addJobAttributeToRetrieve(Job.ACTIVE_JOB_STATUS);
        jobList.addJobAttributeToRetrieve(Job.SUBSYSTEM);
        jobList.addJobAttributeToRetrieve(Job.JOB_NAME);
        jobList.addJobSelectionCriteria(JobList.SELECTION_PRIMARY_JOB_STATUS_ACTIVE, Boolean.TRUE);
        jobList.addJobSelectionCriteria(JobList.SELECTION_PRIMARY_JOB_STATUS_JOBQ, Boolean.FALSE);
        jobList.addJobSelectionCriteria(JobList.SELECTION_PRIMARY_JOB_STATUS_OUTQ, Boolean.FALSE);

        try {
            @SuppressWarnings("unchecked")
            final Enumeration<Job> enumeration = jobList.getJobs();
            final LinkedList<Job> list = new LinkedList<Job>();

            while (enumeration.hasMoreElements()) {
                list.add(enumeration.nextElement());
            }

            this.lastJobCache = list;
        } catch (final Exception e) {
            this.lastFailException = new FailedCheckException("" + e.getMessage());
            this.lastJobCache = null;
            ConnectorLogger.getInstance().debug("", e);
        } finally {
            try {
                jobList.close();
                system.disconnectAllServices();
            } catch (final Exception e) {
                ConnectorLogger.getInstance().info("Job list close failed (" + system.getSystemName() + ")", e);
            }
            this.lastRefresh = System.currentTimeMillis();
        }
    }

}
