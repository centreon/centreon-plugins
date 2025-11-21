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

package com.centreon.connector.as400.check.handler.impl.disk;

/**
 * @author Lamotte Jean-Baptiste
 */
public class Yasp0300Data {
    private int aspNumber;
    private String diskType;
    private String diskModel;
    private String diskSerialNumber;
    private String resourceName;
    private int diskUnitNumber;
    private int diskCapacity;
    private int diskStorageAvailable;
    private int diskStorageReservedForSystem;
    private String mirroredUnitProtected;
    private String mirroredUnitReported;
    private String mirroredUnitStatus;
    private String reserved;
    private int unitControl;
    private int blockTransferredToMainStorage;
    private int blockTransferredFromMainStorage;
    private int requestForDataToMainStorage;
    private int requestForDataForMainStorage;
    private int requestForPermanentFromMainStorage;
    private int sampleCount;
    private int notBusyCount;
    private String compressionStatus;
    private String diskProtectionType;
    private String compressedUnit;
    private String storageAllocationRestrictedUnit;
    private String availabilityParitySetUnit;
    private String multipleConnectionUnit;

    public int getAspNumber() {
        return this.aspNumber;
    }

    public String getAvailabilityParitySetUnit() {
        return this.availabilityParitySetUnit;
    }

    public int getBlockTransferredFromMainStorage() {
        return this.blockTransferredFromMainStorage;
    }

    public int getBlockTransferredToMainStorage() {
        return this.blockTransferredToMainStorage;
    }

    public String getCompressedUnit() {
        return this.compressedUnit;
    }

    public String getCompressionStatus() {
        return this.compressionStatus;
    }

    public int getDiskCapacity() {
        return this.diskCapacity;
    }

    public String getDiskModel() {
        return this.diskModel;
    }

    public String getDiskProtectionType() {
        return this.diskProtectionType;
    }

    public String getDiskSerialNumber() {
        return this.diskSerialNumber;
    }

    public int getDiskStorageAvailable() {
        return this.diskStorageAvailable;
    }

    public int getDiskStorageReservedForSystem() {
        return this.diskStorageReservedForSystem;
    }

    public String getDiskType() {
        return this.diskType;
    }

    public int getDiskUnitNumber() {
        return this.diskUnitNumber;
    }

    public String getMirroredUnitProtected() {
        return this.mirroredUnitProtected;
    }

    public String getMirroredUnitReported() {
        return this.mirroredUnitReported;
    }

    public String getMirroredUnitStatus() {
        return this.mirroredUnitStatus;
    }

    public String getMultipleConnectionUnit() {
        return this.multipleConnectionUnit;
    }

    public int getNotBusyCount() {
        return this.notBusyCount;
    }

    public int getRequestForDataForMainStorage() {
        return this.requestForDataForMainStorage;
    }

    public int getRequestForDataToMainStorage() {
        return this.requestForDataToMainStorage;
    }

    public int getRequestForPermanentFromMainStorage() {
        return this.requestForPermanentFromMainStorage;
    }

    public String getReserved() {
        return this.reserved;
    }

    public String getResourceName() {
        return this.resourceName;
    }

    public int getSampleCount() {
        return this.sampleCount;
    }

    public String getStorageAllocationRestrictedUnit() {
        return this.storageAllocationRestrictedUnit;
    }

    public int getUnitControl() {
        return this.unitControl;
    }

    public String getUnitControlString() {
        /*
         * 0 There is no unit control value. 1 The disk unit is active. 2 The disk unit
         * has failed. 3 Some other disk unit in the disk subsystem has failed. 4 There
         * is a hardware failure within the disk subsystem that affects performance, but
         * does not affect the function of the disk unit. 5 There is a hardware failure
         * within the disk subsystem that does not affect the function or performance of
         * the disk unit. 6 The disk unit's parity protection is being rebuilt. 7 The
         * disk unit is not ready. 8 The disk unit is write protected. 9 The disk unit
         * is busy. 10 The disk unit is not operational. 11 The disk unit has returned a
         * status that is not recognizable by the system. 12 The disk unit cannot be
         * accessed. 13 The disk unit is read/write protected.
         */
        if (this.getUnitControl() == 0) {
            return "There is no unit control value";
        } else if (this.getUnitControl() == 1) {
            return "The disk unit is active";
        } else if (this.getUnitControl() == 2) {
            return "The disk unit has failed";
        } else if (this.getUnitControl() == 3) {
            return "Some other disk unit in the disk subsystem has failed";
        } else if (this.getUnitControl() == 4) {
            return "There is a hardware failure within the disk subsystem that affects performance, but does not affect the function of the disk unit";
        } else if (this.getUnitControl() == 5) {
            return "There is a hardware failure within the disk subsystem that does not affect the function or performance of the disk unit";
        } else if (this.getUnitControl() == 6) {
            return "The disk unit's parity protection is being rebuilt";
        } else if (this.getUnitControl() == 7) {
            return "The disk unit is not ready";
        } else if (this.getUnitControl() == 8) {
            return "The disk unit is write protected";
        } else if (this.getUnitControl() == 9) {
            return "The disk unit is busy";
        } else if (this.getUnitControl() == 10) {
            return "The disk unit is not operational";
        } else if (this.getUnitControl() == 11) {
            return "The disk unit has returned a status that is not recognizable by the system";
        } else if (this.getUnitControl() == 12) {
            return "The disk unit cannot be accessed";
        } else if (this.getUnitControl() == 13) {
            return "The disk unit is read/write protected";
        } else {
            return "state unknown (" + this.getUnitControl() + ")";
        }
    }

    public void setAspNumber(final int aspNumber) {
        this.aspNumber = aspNumber;
    }

    public void setAvailabilityParitySetUnit(final String availabilityParitySetUnit) {
        this.availabilityParitySetUnit = availabilityParitySetUnit;
    }

    public void setBlockTransferredFromMainStorage(final int blockTransferredFromMainStorage) {
        this.blockTransferredFromMainStorage = blockTransferredFromMainStorage;
    }

    public void setBlockTransferredToMainStorage(final int blockTransferredToMainStorage) {
        this.blockTransferredToMainStorage = blockTransferredToMainStorage;
    }

    public void setCompressedUnit(final String compressedUnit) {
        this.compressedUnit = compressedUnit;
    }

    public void setCompressionStatus(final String compressionStatus) {
        this.compressionStatus = compressionStatus;
    }

    public void setDiskCapacity(final int diskCapacity) {
        this.diskCapacity = diskCapacity;
    }

    public void setDiskModel(final String diskModel) {
        this.diskModel = diskModel;
    }

    public void setDiskProtectionType(final String diskProtectionType) {
        this.diskProtectionType = diskProtectionType;
    }

    public void setDiskSerialNumber(final String diskSerialNumber) {
        this.diskSerialNumber = diskSerialNumber;
    }

    public void setDiskStorageAvailable(final int diskStorageAvailable) {
        this.diskStorageAvailable = diskStorageAvailable;
    }

    public void setDiskStorageReservedForSystem(final int diskStorageReservedForSystem) {
        this.diskStorageReservedForSystem = diskStorageReservedForSystem;
    }

    public void setDiskType(final String diskType) {
        this.diskType = diskType;
    }

    public void setDiskUnitNumber(final int diskUnitNumber) {
        this.diskUnitNumber = diskUnitNumber;
    }

    public void setMirroredUnitProtected(final String mirroredUnitProtected) {
        this.mirroredUnitProtected = mirroredUnitProtected;
    }

    public void setMirroredUnitReported(final String mirroredUnitReported) {
        this.mirroredUnitReported = mirroredUnitReported;
    }

    public void setMirroredUnitStatus(final String mirroredUnitStatus) {
        this.mirroredUnitStatus = mirroredUnitStatus;
    }

    public void setMultipleConnectionUnit(final String multipleConnectionUnit) {
        this.multipleConnectionUnit = multipleConnectionUnit;
    }

    public void setNotBusyCount(final int notBusyCount) {
        this.notBusyCount = notBusyCount;
    }

    public void setRequestForDataForMainStorage(final int requestForDataForMainStorage) {
        this.requestForDataForMainStorage = requestForDataForMainStorage;
    }

    public void setRequestForDataToMainStorage(final int requestForDataToMainStorage) {
        this.requestForDataToMainStorage = requestForDataToMainStorage;
    }

    public void setRequestForPermanentFromMainStorage(final int requestForPermanentFromMainStorage) {
        this.requestForPermanentFromMainStorage = requestForPermanentFromMainStorage;
    }

    public void setReserved(final String reserved) {
        this.reserved = reserved;
    }

    public void setResourceName(final String resourceName) {
        this.resourceName = resourceName;
    }

    public void setSampleCount(final int sampleCount) {
        this.sampleCount = sampleCount;
    }

    public void setStorageAllocationRestrictedUnit(final String storageAllocationRestrictedUnit) {
        this.storageAllocationRestrictedUnit = storageAllocationRestrictedUnit;
    }

    public void setUnitControl(final int unitControl) {
        this.unitControl = unitControl;
    }

}
