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

package com.centreon.connector.as400.dispatcher.check;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * @author Lamotte Jean-Baptiste
 */
public class ResponseData {
    public static final int statusOk = 0;
    public static final int statusError = 1;

    private long requestDuration = 0;
    private int code = 0;
    private String message = null;
    private ArrayList result = new ArrayList();

    public ResponseData() {
    }

    public ResponseData(final int code, final String message) {
        this.message = message;
        this.code = code;
    }

    public int getCode() {
        return this.code;
    }

    public void setCode(final int code) {
        this.code = code;
    }

    public ArrayList getResult() {
        return this.result;
    }

    public Object getAttrResult(int index, String attr) {
        HashMap<String, Object> attrs = (HashMap<String, Object>)this.result.get(index);
        return attrs.get(attr);
    }

    public void setResult(final ArrayList result) {
        this.result = result;
    }

    public String getMessage() {
        return this.message;
    }

    public void setMessage(final String message) {
        this.message = message;
    }

    public long getRequestDuration() {
        return this.requestDuration;
    }

    public void setRequestDuration(final long requestDuration) {
        this.requestDuration = requestDuration;
    }
}
