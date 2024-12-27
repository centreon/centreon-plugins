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
public class Jobq0200 extends Jobq0100 {

    private int maxActiveJobPriority1;
    private int maxActiveJobPriority2;
    private int maxActiveJobPriority3;
    private int maxActiveJobPriority4;
    private int maxActiveJobPriority5;
    private int maxActiveJobPriority6;
    private int maxActiveJobPriority7;
    private int maxActiveJobPriority8;
    private int maxActiveJobPriority9;

    private int activeJobPriority0;
    private int activeJobPriority1;
    private int activeJobPriority2;
    private int activeJobPriority3;
    private int activeJobPriority4;
    private int activeJobPriority5;
    private int activeJobPriority6;
    private int activeJobPriority7;
    private int activeJobPriority8;
    private int activeJobPriority9;

    private int scheduledJobOnQueuePriority0;
    private int scheduledJobOnQueuePriority1;
    private int scheduledJobOnQueuePriority2;
    private int scheduledJobOnQueuePriority3;
    private int scheduledJobOnQueuePriority4;
    private int scheduledJobOnQueuePriority5;
    private int scheduledJobOnQueuePriority6;
    private int scheduledJobOnQueuePriority7;
    private int scheduledJobOnQueuePriority8;
    private int scheduledJobOnQueuePriority9;

    private int heldJobOnQueuePriority0;
    private int heldJobOnQueuePriority1;
    private int heldJobOnQueuePriority2;
    private int heldJobOnQueuePriority3;
    private int heldJobOnQueuePriority4;
    private int heldJobOnQueuePriority5;
    private int heldJobOnQueuePriority6;
    private int heldJobOnQueuePriority7;
    private int heldJobOnQueuePriority8;
    private int heldJobOnQueuePriority9;

    public int getActiveJobTotal() {
        return this.activeJobPriority0 + this.activeJobPriority1 + this.activeJobPriority2 + this.activeJobPriority3
                + this.activeJobPriority4 + this.activeJobPriority5 + this.activeJobPriority6 + this.activeJobPriority7
                + this.activeJobPriority8 + this.activeJobPriority9;
    }

    public int getScheduledJobTotal() {
        return this.scheduledJobOnQueuePriority0 + this.scheduledJobOnQueuePriority1 + this.scheduledJobOnQueuePriority2
                + this.scheduledJobOnQueuePriority3 + this.scheduledJobOnQueuePriority4 + this.scheduledJobOnQueuePriority5
                + this.scheduledJobOnQueuePriority6 + this.scheduledJobOnQueuePriority7 + this.scheduledJobOnQueuePriority8
                + this.scheduledJobOnQueuePriority9;
    }

    public int getHeldJobTotal() {
        return this.heldJobOnQueuePriority0 + this.heldJobOnQueuePriority1 + this.heldJobOnQueuePriority2
                + this.heldJobOnQueuePriority3 + this.heldJobOnQueuePriority4 + this.heldJobOnQueuePriority5
                + this.heldJobOnQueuePriority6 + this.heldJobOnQueuePriority7 + this.heldJobOnQueuePriority8
                + this.heldJobOnQueuePriority9;
    }

    public int getMaxActiveJobPriority1() {
        return this.maxActiveJobPriority1;
    }

    public void setMaxActiveJobPriority1(final int maxActiveJobPriority1) {
        this.maxActiveJobPriority1 = maxActiveJobPriority1;
    }

    public int getMaxActiveJobPriority2() {
        return this.maxActiveJobPriority2;
    }

    public void setMaxActiveJobPriority2(final int maxActiveJobPriority2) {
        this.maxActiveJobPriority2 = maxActiveJobPriority2;
    }

    public int getMaxActiveJobPriority3() {
        return this.maxActiveJobPriority3;
    }

    public void setMaxActiveJobPriority3(final int maxActiveJobPriority3) {
        this.maxActiveJobPriority3 = maxActiveJobPriority3;
    }

    public int getMaxActiveJobPriority4() {
        return this.maxActiveJobPriority4;
    }

    public void setMaxActiveJobPriority4(final int maxActiveJobPriority4) {
        this.maxActiveJobPriority4 = maxActiveJobPriority4;
    }

    public int getMaxActiveJobPriority5() {
        return this.maxActiveJobPriority5;
    }

    public void setMaxActiveJobPriority5(final int maxActiveJobPriority5) {
        this.maxActiveJobPriority5 = maxActiveJobPriority5;
    }

    public int getMaxActiveJobPriority6() {
        return this.maxActiveJobPriority6;
    }

    public void setMaxActiveJobPriority6(final int maxActiveJobPriority6) {
        this.maxActiveJobPriority6 = maxActiveJobPriority6;
    }

    public int getMaxActiveJobPriority7() {
        return this.maxActiveJobPriority7;
    }

    public void setMaxActiveJobPriority7(final int maxActiveJobPriority7) {
        this.maxActiveJobPriority7 = maxActiveJobPriority7;
    }

    public int getMaxActiveJobPriority8() {
        return this.maxActiveJobPriority8;
    }

    public void setMaxActiveJobPriority8(final int maxActiveJobPriority8) {
        this.maxActiveJobPriority8 = maxActiveJobPriority8;
    }

    public int getMaxActiveJobPriority9() {
        return this.maxActiveJobPriority9;
    }

    public void setMaxActiveJobPriority9(final int maxActiveJobPriority9) {
        this.maxActiveJobPriority9 = maxActiveJobPriority9;
    }

    public int getActiveJobPriority1() {
        return this.activeJobPriority1;
    }

    public void setActiveJobPriority1(final int activeJobPriority1) {
        this.activeJobPriority1 = activeJobPriority1;
    }

    public int getActiveJobPriority2() {
        return this.activeJobPriority2;
    }

    public void setActiveJobPriority2(final int activeJobPriority2) {
        this.activeJobPriority2 = activeJobPriority2;
    }

    public int getActiveJobPriority3() {
        return this.activeJobPriority3;
    }

    public void setActiveJobPriority3(final int activeJobPriority3) {
        this.activeJobPriority3 = activeJobPriority3;
    }

    public int getActiveJobPriority4() {
        return this.activeJobPriority4;
    }

    public void setActiveJobPriority4(final int activeJobPriority4) {
        this.activeJobPriority4 = activeJobPriority4;
    }

    public int getActiveJobPriority5() {
        return this.activeJobPriority5;
    }

    public void setActiveJobPriority5(final int activeJobPriority5) {
        this.activeJobPriority5 = activeJobPriority5;
    }

    public int getActiveJobPriority6() {
        return this.activeJobPriority6;
    }

    public void setActiveJobPriority6(final int activeJobPriority6) {
        this.activeJobPriority6 = activeJobPriority6;
    }

    public int getActiveJobPriority7() {
        return this.activeJobPriority7;
    }

    public void setActiveJobPriority7(final int activeJobPriority7) {
        this.activeJobPriority7 = activeJobPriority7;
    }

    public int getActiveJobPriority8() {
        return this.activeJobPriority8;
    }

    public void setActiveJobPriority8(final int activeJobPriority8) {
        this.activeJobPriority8 = activeJobPriority8;
    }

    public int getActiveJobPriority9() {
        return this.activeJobPriority9;
    }

    public void setActiveJobPriority9(final int activeJobPriority9) {
        this.activeJobPriority9 = activeJobPriority9;
    }

    public int getScheduledJobOnQueuePriority1() {
        return this.scheduledJobOnQueuePriority1;
    }

    public void setScheduledJobOnQueuePriority1(final int scheduledJobOnQueuePriority1) {
        this.scheduledJobOnQueuePriority1 = scheduledJobOnQueuePriority1;
    }

    public int getScheduledJobOnQueuePriority2() {
        return this.scheduledJobOnQueuePriority2;
    }

    public void setScheduledJobOnQueuePriority2(final int scheduledJobOnQueuePriority2) {
        this.scheduledJobOnQueuePriority2 = scheduledJobOnQueuePriority2;
    }

    public int getScheduledJobOnQueuePriority3() {
        return this.scheduledJobOnQueuePriority3;
    }

    public void setScheduledJobOnQueuePriority3(final int scheduledJobOnQueuePriority3) {
        this.scheduledJobOnQueuePriority3 = scheduledJobOnQueuePriority3;
    }

    public int getScheduledJobOnQueuePriority4() {
        return this.scheduledJobOnQueuePriority4;
    }

    public void setScheduledJobOnQueuePriority4(final int scheduledJobOnQueuePriority4) {
        this.scheduledJobOnQueuePriority4 = scheduledJobOnQueuePriority4;
    }

    public int getScheduledJobOnQueuePriority5() {
        return this.scheduledJobOnQueuePriority5;
    }

    public void setScheduledJobOnQueuePriority5(final int scheduledJobOnQueuePriority5) {
        this.scheduledJobOnQueuePriority5 = scheduledJobOnQueuePriority5;
    }

    public int getScheduledJobOnQueuePriority6() {
        return this.scheduledJobOnQueuePriority6;
    }

    public void setScheduledJobOnQueuePriority6(final int scheduledJobOnQueuePriority6) {
        this.scheduledJobOnQueuePriority6 = scheduledJobOnQueuePriority6;
    }

    public int getScheduledJobOnQueuePriority7() {
        return this.scheduledJobOnQueuePriority7;
    }

    public void setScheduledJobOnQueuePriority7(final int scheduledJobOnQueuePriority7) {
        this.scheduledJobOnQueuePriority7 = scheduledJobOnQueuePriority7;
    }

    public int getScheduledJobOnQueuePriority8() {
        return this.scheduledJobOnQueuePriority8;
    }

    public void setScheduledJobOnQueuePriority8(final int scheduledJobOnQueuePriority8) {
        this.scheduledJobOnQueuePriority8 = scheduledJobOnQueuePriority8;
    }

    public int getScheduledJobOnQueuePriority9() {
        return this.scheduledJobOnQueuePriority9;
    }

    public void setScheduledJobOnQueuePriority9(final int scheduledJobOnQueuePriority9) {
        this.scheduledJobOnQueuePriority9 = scheduledJobOnQueuePriority9;
    }

    public int getHeldJobOnQueuePriority1() {
        return this.heldJobOnQueuePriority1;
    }

    public void setHeldJobOnQueuePriority1(final int heldJobOnQueuePriority1) {
        this.heldJobOnQueuePriority1 = heldJobOnQueuePriority1;
    }

    public int getHeldJobOnQueuePriority2() {
        return this.heldJobOnQueuePriority2;
    }

    public void setHeldJobOnQueuePriority2(final int heldJobOnQueuePriority2) {
        this.heldJobOnQueuePriority2 = heldJobOnQueuePriority2;
    }

    public int getHeldJobOnQueuePriority3() {
        return this.heldJobOnQueuePriority3;
    }

    public void setHeldJobOnQueuePriority3(final int heldJobOnQueuePriority3) {
        this.heldJobOnQueuePriority3 = heldJobOnQueuePriority3;
    }

    public int getHeldJobOnQueuePriority4() {
        return this.heldJobOnQueuePriority4;
    }

    public void setHeldJobOnQueuePriority4(final int heldJobOnQueuePriority4) {
        this.heldJobOnQueuePriority4 = heldJobOnQueuePriority4;
    }

    public int getHeldJobOnQueuePriority5() {
        return this.heldJobOnQueuePriority5;
    }

    public void setHeldJobOnQueuePriority5(final int heldJobOnQueuePriority5) {
        this.heldJobOnQueuePriority5 = heldJobOnQueuePriority5;
    }

    public int getHeldJobOnQueuePriority6() {
        return this.heldJobOnQueuePriority6;
    }

    public void setHeldJobOnQueuePriority6(final int heldJobOnQueuePriority6) {
        this.heldJobOnQueuePriority6 = heldJobOnQueuePriority6;
    }

    public int getHeldJobOnQueuePriority7() {
        return this.heldJobOnQueuePriority7;
    }

    public void setHeldJobOnQueuePriority7(final int heldJobOnQueuePriority7) {
        this.heldJobOnQueuePriority7 = heldJobOnQueuePriority7;
    }

    public int getHeldJobOnQueuePriority8() {
        return this.heldJobOnQueuePriority8;
    }

    public void setHeldJobOnQueuePriority8(final int heldJobOnQueuePriority8) {
        this.heldJobOnQueuePriority8 = heldJobOnQueuePriority8;
    }

    public int getHeldJobOnQueuePriority9() {
        return this.heldJobOnQueuePriority9;
    }

    public void setHeldJobOnQueuePriority9(final int heldJobOnQueuePriority9) {
        this.heldJobOnQueuePriority9 = heldJobOnQueuePriority9;
    }

    public int getActiveJobPriority0() {
        return this.activeJobPriority0;
    }

    public void setActiveJobPriority0(final int activeJobPriority0) {
        this.activeJobPriority0 = activeJobPriority0;
    }

    public int getScheduledJobOnQueuePriority0() {
        return this.scheduledJobOnQueuePriority0;
    }

    public void setScheduledJobOnQueuePriority0(final int scheduledJobOnQueuePriority0) {
        this.scheduledJobOnQueuePriority0 = scheduledJobOnQueuePriority0;
    }

    public int getHeldJobOnQueuePriority0() {
        return this.heldJobOnQueuePriority0;
    }

    public void setHeldJobOnQueuePriority0(final int heldJobOnQueuePriority0) {
        this.heldJobOnQueuePriority0 = heldJobOnQueuePriority0;
    }

}
