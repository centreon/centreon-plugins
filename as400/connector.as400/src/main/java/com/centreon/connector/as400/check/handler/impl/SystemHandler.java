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
import java.io.UnsupportedEncodingException;
import java.util.Enumeration;
import java.util.HashMap;

import com.ibm.as400.access.AS400Bin4;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.AS400Text;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.ProgramCall;
import com.ibm.as400.access.ProgramParameter;
import com.ibm.as400.access.QSYSObjectPathName;
import com.ibm.as400.access.SystemPool;
import com.ibm.as400.access.SystemStatus;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.check.handler.ISystemHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class SystemHandler extends AbstractHandler implements ISystemHandler {
    private SystemStatus status = null;

    public SystemHandler(final String host, final String login, final String password)
            throws AS400SecurityException, IOException {
        this(host, login, password, null);
    }

    public SystemHandler(final String host, final String login, final String password, SystemStatus as400Status)
            throws AS400SecurityException, IOException {
        super(host, login, password);
        this.status = as400Status == null ? new SystemStatus(getNewAs400()) : as400Status;
    }

    @Override
    @SuppressWarnings("deprecation")
    public void dumpPool(final SystemPool pool) throws UnsupportedEncodingException, AS400SecurityException,
            ErrorCompletingRequestException, InterruptedException, IOException, ObjectDoesNotExistException {

        System.out.println("------------------------------------");
        System.out.println("name : " + pool.getName() + " | " + pool.getDescription());
        System.out.println("Identifier : " + pool.getIdentifier());
        System.out.println("ActiveToIneligible : " + pool.getActiveToIneligible()
                + " transitions per minute, of transitions of threads from an active condition to an ineligible condition");
        System.out.println("ActiveToWait : " + pool.getActiveToWait()
                + " transitions per minute, of transitions of threads from an active condition to a waiting condition");
        System.out.println("WaitToIneligible : " + pool.getWaitToIneligible()
                + " transitions per minute, of transitions of threads from a waiting condition to an ineligible condition");
        System.out.println("ActivityLevel : " + pool.getActivityLevel()
                + " maximum number of threads that can be active in the pool at any one time");
        System.out.println("DatabaseFaults : " + pool.getDatabaseFaults() + " page faults per second");
        System.out.println("DatabasePages : " + pool.getDatabasePages() + " page per second");
        System.out.println("MaximumActiveThreads : " + pool.getMaximumActiveThreads() + "(deprecated)");
        System.out.println("NonDatabaseFaults : " + pool.getNonDatabaseFaults() + " page faults per second");
        System.out.println("NonDatabasePages : " + pool.getNonDatabasePages() + " page per second");
        System.out.println("PagingOption : " + pool.getPagingOption());
        System.out.println("PoolIdentifier : " + pool.getPoolIdentifier() + "(deprecated)");
        System.out.println("PoolName : " + pool.getPoolName() + "(deprecated)");
        System.out.println("PoolSize : " + pool.getPoolSize() + " (deprecated)");
        System.out.println("ReservedSize : " + pool.getReservedSize() + " kilobytes,");
        System.out.println("Size : " + pool.getSize() + " kilobytes");
        System.out.println("SubsystemLibrary : " + pool.getSubsystemLibrary());
        System.out.println("SubsystemName : " + pool.getSubsystemName());
        System.out.println("System : " + pool.getSystem());

        pool.getActiveToIneligible();
    }

    @Override
    public void dumpSystem() throws AS400SecurityException, ErrorCompletingRequestException, InterruptedException,
            IOException, ObjectDoesNotExistException {

        System.out.println("ActiveJobsInSystem : " + this.status.getActiveJobsInSystem());
        // System.out.println("PercentSystemASPUsed : " +
        // status.getPercentSystemASPUsed() + "%"); //<== stockage
        // System.out.println("getPercentProcessingUnitUsed : " +
        // status.getPercentProcessingUnitUsed() + "%");
        System.out.println("ActiveThreadsInSystem : " + this.status.getActiveThreadsInSystem() + "");
        System.out.println("BatchJobsEndedWithPrinterOutputWaitingToPrint : "
                + this.status.getBatchJobsEndedWithPrinterOutputWaitingToPrint() + "");
        System.out.println("BatchJobsEnding : " + this.status.getBatchJobsEnding() + "");
        System.out.println("BatchJobsHeldOnJobQueue : " + this.status.getBatchJobsHeldOnJobQueue() + "");
        System.out.println("BatchJobsHeldWhileRunning : " + this.status.getBatchJobsHeldWhileRunning() + "");
        System.out.println("BatchJobsOnAHeldJobQueue : " + this.status.getBatchJobsOnAHeldJobQueue() + "");
        System.out.println("BatchJobsOnUnassignedJobQueue : " + this.status.getBatchJobsOnUnassignedJobQueue() + "");
        System.out.println("BatchJobsRunning : " + this.status.getBatchJobsRunning() + "");
        System.out.println("BatchJobsWaitingForMessage : " + this.status.getBatchJobsWaitingForMessage() + "");
        System.out.println(
                "BatchJobsWaitingToRunOrAlreadyScheduled : " + this.status.getBatchJobsWaitingToRunOrAlreadyScheduled() + "");
        System.out.println("CurrentProcessingCapacity : " + this.status.getCurrentProcessingCapacity() + "");
        System.out.println("CurrentUnprotectedStorageUsed : " + this.status.getCurrentUnprotectedStorageUsed() + "");
        System.out.println("DateAndTimeStatusGathered : " + this.status.getDateAndTimeStatusGathered() + "");
        System.out.println("ElapsedTime : " + this.status.getElapsedTime() + "");
        System.out.println("JobsInSystem : " + this.status.getJobsInSystem() + "");
        System.out.println("MainStorageSize : " + this.status.getMainStorageSize() + "");
        System.out.println("MaximumJobsInSystem : " + this.status.getMaximumJobsInSystem() + "");
        System.out.println("MaximumUnprotectedStorageUsed : " + this.status.getMaximumUnprotectedStorageUsed() + "");
        System.out.println("NumberOfPartitions : " + this.status.getNumberOfPartitions() + "");
        System.out.println("NumberOfProcessors : " + this.status.getNumberOfProcessors() + "");
        System.out.println("PartitionIdentifier : " + this.status.getPartitionIdentifier() + "");
        System.out.println(
                "PercentCurrentInteractivePerformance : " + this.status.getPercentCurrentInteractivePerformance() + "");
        System.out.println("PercentDBCapability : " + this.status.getPercentDBCapability() + "");
        System.out
                .println("PercentPermanent256MBSegmentsUsed : " + this.status.getPercentPermanent256MBSegmentsUsed() + "");
        System.out.println("PercentPermanent4GBSegmentsUsed : " + this.status.getPercentPermanent4GBSegmentsUsed() + "");
        System.out.println("PercentPermanentAddresses : " + this.status.getPercentPermanentAddresses() + "");
        System.out.println("PercentProcessingUnitUsed : " + this.status.getPercentProcessingUnitUsed() + "");
        System.out.println("PercentSharedProcessorPoolUsed : " + this.status.getPercentSharedProcessorPoolUsed() + "");
        System.out.println("PercentSystemASPUsed : " + this.status.getPercentSystemASPUsed() + "");
        System.out
                .println("PercentTemporary256MBSegmentsUsed : " + this.status.getPercentTemporary256MBSegmentsUsed() + "");
        System.out.println("PercentTemporary4GBSegmentsUsed : " + this.status.getPercentTemporary4GBSegmentsUsed() + "");
        System.out.println("PercentTemporaryAddresses : " + this.status.getPercentTemporaryAddresses() + "");
        System.out.println("PercentUncappedCPUCapacityUsed : " + this.status.getPercentUncappedCPUCapacityUsed() + "");
        System.out.println("PoolsNumber : " + this.status.getPoolsNumber() + "");
        System.out.println("ProcessorSharingAttribute : " + this.status.getProcessorSharingAttribute() + "");
        System.out.println("RestrictedStateFlag : " + this.status.getRestrictedStateFlag() + "");
        System.out.println("System : " + this.status.getSystem() + "");
        System.out.println("SystemASP : " + this.status.getSystemASP() + " Mbytes");
        System.out.println("SystemName : " + this.status.getSystemName() + "");
        System.out.println("TotalAuxiliaryStorage : " + this.status.getTotalAuxiliaryStorage() + "");
        System.out.println("UsersCurrentSignedOn : " + this.status.getUsersCurrentSignedOn() + "");
        System.out.println("UsersSignedOffWithPrinterOutputWaitingToPrint : "
                + this.status.getUsersSignedOffWithPrinterOutputWaitingToPrint() + "");
        System.out.println("UsersSuspendedByGroupJobs : " + this.status.getUsersSuspendedByGroupJobs() + "");
        System.out.println("UsersSuspendedBySystemRequest : " + this.status.getUsersSuspendedBySystemRequest() + "");
        System.out.println("UsersTemporarilySignedOff : " + this.status.getUsersTemporarilySignedOff() + "");

        final Enumeration<?> enumeration = this.status.getSystemPools();

        while (enumeration.hasMoreElements()) {
            this.dumpPool((SystemPool) enumeration.nextElement());
        }
    }

    @Override
    public ResponseData getSystem() throws Exception {
        final ResponseData data = new ResponseData();
        HashMap<String, Object> attrs = new HashMap<String, Object>();

        attrs.put("percentProcessingUnitUsed", this.status.getPercentProcessingUnitUsed());
        attrs.put("percentSystemASPUsed", this.status.getPercentSystemASPUsed());
        attrs.put("maxJobInSystem", this.status.getMaximumJobsInSystem());
        attrs.put("jobInSystem", this.status.getJobsInSystem());
        attrs.put("activeJobInSystem", this.status.getActiveJobsInSystem());
        attrs.put("activeThreadInSystem", this.status.getActiveThreadsInSystem());
        attrs.put("batchJobsEndedWithPrinterOutputWaitingToPrint", this.status
                .getBatchJobsEndedWithPrinterOutputWaitingToPrint());
        attrs.put("batchJobEnding", this.status.getBatchJobsEnding());
        attrs.put("batchJobHeldInJobQueue", this.status.getBatchJobsHeldOnJobQueue());
        attrs.put("batchJobHeldWhileRunning", this.status.getBatchJobsHeldWhileRunning());
        attrs.put("batchJobOnHeldJobQueue", this.status.getBatchJobsOnAHeldJobQueue());
        attrs.put("batchJobOnUnassignedJobQueue", this.status.getBatchJobsOnUnassignedJobQueue());
        attrs.put("batchJobRunning", this.status.getBatchJobsRunning());
        attrs.put("batchJobWaitingForMessage", this.status.getBatchJobsWaitingForMessage());
        attrs.put("batchJobWaitingToRunOrAlreadyScheduled", this.status.getBatchJobsWaitingToRunOrAlreadyScheduled());
        data.getResult().add(attrs);

        return data;
    }

    @Override
    @SuppressWarnings("unchecked")
    public ResponseData getPageFault() throws Exception {
        final ResponseData data = new ResponseData();

        for (final Enumeration<SystemPool> enumeration = this.status.getSystemPools(); enumeration.hasMoreElements();) {
            final SystemPool pool = enumeration.nextElement();
            HashMap<String, Object> attrs = new HashMap<String, Object>();

            attrs.put("id", pool.getIdentifier());
            attrs.put("name", pool.getPoolName());
            attrs.put("dbPageFault", pool.getDatabaseFaults());
            attrs.put("dbPage", pool.getDatabasePages());
            attrs.put("nonDbPageFault", pool.getNonDatabaseFaults());
            attrs.put("nonDbPage",pool.getNonDatabasePages());
            data.getResult().add(attrs);
        }

        return data;
    }

    @SuppressWarnings("unchecked")
    public SystemPool searchSystemPoolByName(final String poolName) throws AS400SecurityException,
            ErrorCompletingRequestException, InterruptedException, IOException, ObjectDoesNotExistException {
        for (final Enumeration<SystemPool> enumeration = this.status.getSystemPools(); enumeration.hasMoreElements();) {
            final SystemPool pool = enumeration.nextElement();
            System.out.println("poolName : " + pool.getName());
            if (poolName.equalsIgnoreCase(pool.getName())) {
                return pool;
            }
        }
        return null;
    }

}
