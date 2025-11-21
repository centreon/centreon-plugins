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

import java.io.IOException;

import com.ibm.as400.access.AS400;
import com.ibm.as400.access.AS400Exception;
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.AS400Text;
import com.ibm.as400.access.BinaryConverter;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.ProgramCall;
import com.ibm.as400.access.ProgramParameter;

/**
 * @author Lamotte Jean-Baptiste
 */
public class DiskInfo {
    AS400 system = null;

    private static final ProgramParameter ERROR_CODE = new ProgramParameter(new byte[8]);

    byte[][] receiverVariables_ = new byte[4][];

    public DiskInfo(final AS400 system) {
        this.system = system;
    }

    public void load() throws AS400SecurityException, ErrorCompletingRequestException, InterruptedException, IOException,
            ObjectDoesNotExistException {
        this.load(1);
    }

    // Retrieve Disk Information (QYASRDI) API
    public void load(int format) throws AS400SecurityException, ErrorCompletingRequestException, InterruptedException,
            IOException, ObjectDoesNotExistException {
        // Check to see if the format has been loaded already.
        if (this.receiverVariables_[format] != null) {
            return;
        }
        if (format == 0) {
            format = 1;
        }

        final int receiverVariableLength = format == 1 ? 80 : format == 2 ? 148 : 2048;

        final AS400Text param3 = new AS400Text(8, this.system);
        // AS400Array param4 = new AS400Array(param3., system);

        final ProgramParameter[] parameters = new ProgramParameter[] {
                // 1 Receiver variable Output Char(*)
                new ProgramParameter(receiverVariableLength),
                // 2 Length of receiver variable Input Binary(4)
                new ProgramParameter(BinaryConverter.intToByteArray(receiverVariableLength)),
                // 3 Format name Input Char(8)
                new ProgramParameter(param3.toBytes("DMIN0100")),
                // 4 Disk unit resource name array Input Array of CHAR(10)
                new ProgramParameter(("*ALL      ").getBytes("ASCII")),
                // 5 Number of disk unit resource names Input Binary(4)
                new ProgramParameter(BinaryConverter.intToByteArray(1)), DiskInfo.// 6
                // Error
                // code
                // I/O
                // Char(*)
                        ERROR_CODE };

        final ProgramCall pc = new ProgramCall(this.system, "/QSYS.LIB/QYASRDI.PGM", parameters);
        // QWCRSSTS is not thread safe.
        boolean repeatRun;
        do {
            repeatRun = false;
            if (!pc.run()) {
                throw new AS400Exception(pc.getMessageList());
            }

            this.receiverVariables_[format] = parameters[0].getOutputData();

            final int bytesAvailable = BinaryConverter.byteArrayToInt(this.receiverVariables_[format], 0);
            final int bytesReturned = BinaryConverter.byteArrayToInt(this.receiverVariables_[format], 4);
            if (bytesReturned < bytesAvailable) {
                repeatRun = true;
                parameters[0] = new ProgramParameter(bytesAvailable);
                parameters[1] = new ProgramParameter(BinaryConverter.intToByteArray(bytesAvailable));
            }
        } while (repeatRun);
        this.receiverVariables_[0] = this.receiverVariables_[format];
    }
}
