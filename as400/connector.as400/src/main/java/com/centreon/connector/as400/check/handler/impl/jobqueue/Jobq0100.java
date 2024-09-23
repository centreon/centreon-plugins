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

package com.centreon.connector.as400.check.handler.impl.jobqueue;

/**
 * @author Lamotte Jean-Baptiste
 */
public class Jobq0100 {
    private int bytesReturned;
    private int bytesAvailable;
    private String jobqName;
    private String jobqLibName;
    private String operatorControlled;
    private String authorityCheck;
    private int numberOfJob;
    private String jobQueueStatus;
    private String subSystemName;
    private String textDescription;
    private String subSystemLibName;
    private int sequenceNumber;
    private int maximumActive;
    private int currentActive;

    public int getBytesReturned() {
        return this.bytesReturned;
    }

    public void setBytesReturned(final int bytesReturned) {
        this.bytesReturned = bytesReturned;
    }

    public int getBytesAvailable() {
        return this.bytesAvailable;
    }

    public void setBytesAvailable(final int bytesAvailable) {
        this.bytesAvailable = bytesAvailable;
    }

    public String getJobqName() {
        return this.jobqName;
    }

    public void setJobqName(final String jobqName) {
        this.jobqName = jobqName;
    }

    public String getJobqLibName() {
        return this.jobqLibName;
    }

    public void setJobqLibName(final String jobqLibName) {
        this.jobqLibName = jobqLibName;
    }

    public String getOperatorControlled() {
        return this.operatorControlled;
    }

    public void setOperatorControlled(final String operatorControlled) {
        this.operatorControlled = operatorControlled;
    }

    public String getAuthorityCheck() {
        return this.authorityCheck;
    }

    public void setAuthorityCheck(final String authorityCheck) {
        this.authorityCheck = authorityCheck;
    }

    public int getNumberOfJob() {
        return this.numberOfJob;
    }

    public void setNumberOfJob(final int numberOfJob) {
        this.numberOfJob = numberOfJob;
    }

    public String getJobQueueStatus() {
        return this.jobQueueStatus;
    }

    public void setJobQueueStatus(final String jobQueueStatus) {
        this.jobQueueStatus = jobQueueStatus;
    }

    public String getSubSystemName() {
        return this.subSystemName;
    }

    public void setSubSystemName(final String subSystemName) {
        this.subSystemName = subSystemName;
    }

    public String getTextDescription() {
        return this.textDescription;
    }

    public void setTextDescription(final String textDescription) {
        this.textDescription = textDescription;
    }

    public String getSubSystemLibName() {
        return this.subSystemLibName;
    }

    public void setSubSystemLibName(final String subSystemLibName) {
        this.subSystemLibName = subSystemLibName;
    }

    public int getSequenceNumber() {
        return this.sequenceNumber;
    }

    public void setSequenceNumber(final int sequenceNumber) {
        this.sequenceNumber = sequenceNumber;
    }

    public int getMaximumActive() {
        return this.maximumActive;
    }

    public void setMaximumActive(final int maximumActive) {
        this.maximumActive = maximumActive;
    }

    public int getCurrentActive() {
        return this.currentActive;
    }

    public void setCurrentActive(final int currentActive) {
        this.currentActive = currentActive;
    }
}
