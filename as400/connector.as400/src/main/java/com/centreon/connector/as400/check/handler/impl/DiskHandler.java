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
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;

import com.ibm.as400.access.AS400SecurityException;
import com.centreon.connector.as400.check.handler.IDiskHandler;
import com.centreon.connector.as400.check.handler.impl.disk.QyaspolYasp0300PcmlHandler;
import com.centreon.connector.as400.check.handler.impl.disk.Yasp0300Data;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
public class DiskHandler extends AbstractHandler implements IDiskHandler {

    private QyaspolYasp0300PcmlHandler qyaspolPcmlHandler = null;

    public DiskHandler(final String host, final String login, final String password)
            throws AS400SecurityException, IOException {
        super(host, login, password);
        this.qyaspolPcmlHandler = new QyaspolYasp0300PcmlHandler(host, login, password);
    }

    @Override
    public ResponseData listDisks(final String diskName) throws Exception {
        final ResponseData data = new ResponseData();

        List<Yasp0300Data> disks = null;

        if (diskName == null) {
            disks = this.qyaspolPcmlHandler.getDisksList();
        } else {
            final Yasp0300Data disk = this.qyaspolPcmlHandler.getDiskByResourceName(diskName);
            if (disk == null) {
                return new ResponseData(ResponseData.statusError, "Disk " + diskName + " not found");
            }
            disks = new ArrayList<Yasp0300Data>();
            disks.add(disk);
        }

        /*
         * 0 -  There is no unit control value (noUnitControl)
         * 1 -  The disk unit is active (active)
         * 2 -  The disk unit has failed (failed)
         * 3 -  Some other disk unit in the disk subsystem has failed (otherDiskSubFailed)
         * 4 -  There is a hardware failure within the disk subsystem that affects performance, but does not affect the function of the disk unit (hwFailurePerf)
         * 5 -  There is a hardware failure within the disk subsystem that does not affect the function or performance of the disk unit (hwFailureOk)
         * 6 -  The disk unit's parity protection is being rebuilt (rebuilding)
         * 7 -  The disk unit is not ready (noReady)
         * 8 -  The disk unit is write protected (writeProtected)
         * 9 -  The disk unit is busy. (busy)
         * 10 - The disk unit is not operational (notOperational)
         * 11 - The disk unit has returned a status that is not recognizable by the system (unknownStatus)
         * 12 - The disk unit cannot be accessed (noAccess)
         * 13 - The disk unit is read/write protected (rwProtected)
         */
        for (final Yasp0300Data disk : disks) {
            HashMap<String, Object> attrs = new HashMap<String, Object>();

            attrs.put("status", disk.getUnitControl());
            attrs.put("name", disk.getResourceName());
            attrs.put("totalSpace", disk.getDiskCapacity() * 1024d * 1024d);
            attrs.put("reservedSpace", disk.getDiskStorageReservedForSystem() * 1024d * 1024d);
            attrs.put("freeSpace", disk.getDiskStorageAvailable() * 1024d * 1024d);
            data.getResult().add(attrs);
        }

        return data;
    }
}
