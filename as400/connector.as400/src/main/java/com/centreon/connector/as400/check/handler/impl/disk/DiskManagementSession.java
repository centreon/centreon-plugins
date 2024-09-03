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
import com.ibm.as400.access.AS400SecurityException;
import com.ibm.as400.access.ErrorCompletingRequestException;
import com.ibm.as400.access.ObjectDoesNotExistException;
import com.ibm.as400.access.ProgramCall;
import com.ibm.as400.access.ProgramParameter;

/**
 * @author Lamotte Jean-Baptiste
 */
public class DiskManagementSession {
    AS400 system = null;

    byte[] session;

    private static final ProgramParameter ERROR_CODE = new ProgramParameter(new byte[8]);

    public DiskManagementSession(final AS400 system) {
        this.system = system;
    }

    public byte[] getHandle() {
        return this.session;
    }

    // Retrieve Disk Information (QYASRDI) API
    public void load() throws AS400SecurityException, ErrorCompletingRequestException, InterruptedException, IOException,
            ObjectDoesNotExistException {

        final ProgramParameter[] parameters = new ProgramParameter[] {
                // 1 Session handle Output Char(8)
                new ProgramParameter(8), DiskManagementSession.// 2 Error code
                // I/O Char(*)
                        ERROR_CODE };

        new ProgramCall(this.system, "/QSYS.LIB/QYASSDMS.PGM", parameters);

        this.session = parameters[0].getOutputData();
    }
}
