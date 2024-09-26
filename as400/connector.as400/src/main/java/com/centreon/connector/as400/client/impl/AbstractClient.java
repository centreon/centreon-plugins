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

package com.centreon.connector.as400.client.impl;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.centreon.connector.as400.dispatcher.check.InputData;

import com.centreon.connector.as400.client.IClient;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

/**
 * @author Lamotte Jean-Baptiste
 */
abstract class AbstractClient implements IClient {
    private InputData input = null;

    private String as400Host = null;
    private String as400Login = null;
    private String as400Password = null;
    private String as400CheckType = null;
    private String as400Args = null;
    private List<Map<String, String>> argList = new ArrayList<Map<String, String>>();

    @Override
    public abstract String getRawRequest();

    protected abstract void writeAnswer(String answer);

    public AbstractClient() {
    }

    @Override
    public String getAs400Host() {
        return this.input.getHost();
    }

    @Override
    public String getAs400Login() {
        return this.input.getLogin();
    }

    @Override
    public String getAs400Password() {
        return this.input.getPassword();
    }

    @Override
    public String getAs400CheckType() {
        return this.input.getCommand();
    }

    @Override
    public Object getAs400Arg(String key) {
        return this.input.getArg(key);
    }

    public List<Map<String , String>> getAs400ArgList(String key) {
        Object arg = this.input.getArg(key);
        if (arg == null) {
            return null;
        }

        Gson gson = new Gson();
        return gson.fromJson(arg.toString(), argList.getClass());
    }

    @Override
    public void parseRequest() throws Exception {
        Gson gson = new Gson();
        this.input = gson.fromJson(this.getRawRequest(), InputData.class);

        if (this.input.getHost() == null) {
            throw new Exception("Invalid option: As/400 host required");
        }
        if (this.input.getLogin() == null) {
            throw new Exception("Invalid option: As/400 login required");
        }
        if (this.input.getPassword() == null) {
            throw new Exception("Invalid option: As/400 password required");
        }
        if (this.input.getCommand() == null) {
            throw new Exception("Invalid option: As/400 command required");
        }
    }

    @Override
    public void writeAnswer(final ResponseData data) {
        Gson gson = new GsonBuilder().create();
        String json = gson.toJson(data);

        this.writeAnswer(json);
    }
}
