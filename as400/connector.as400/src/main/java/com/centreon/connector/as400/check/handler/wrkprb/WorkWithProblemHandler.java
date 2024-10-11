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

package com.centreon.connector.as400.check.handler.wrkprb;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.List;
import java.util.HashMap;

import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;

import com.centreon.connector.as400.check.handler.wrkprb.CheckAS400Lang;
import com.centreon.connector.as400.ConnectorLogger;
import com.centreon.connector.as400.check.handler.impl.AbstractHandler;
import com.centreon.connector.as400.dispatcher.check.ResponseData;

@SuppressWarnings("unused")
public class WorkWithProblemHandler extends AbstractHandler {

    private static int INSTANCE_ID = 0;
    private static long LOGIN_COUNT = 0;
    private static long LOGOUT_COUNT = 0;
    private static final int LOG_TRACE = 0;
    private static final int LOG_DEBUG = 1;
    private static final int LOG_WARN = 2;
    private static final int LOG_ERROR = 3;

    private static final int OK = 0;
    private static final int WARN = 1;
    private static final int CRITICAL = 2;
    private static final int UNKNOWN = 3;
    // These constants are for the wait recieve, controlling
    // any other logic that it should turn on. For example checking
    // for invalid login.
    private final static int NONE = 0;
    private final static int LOGIN = 1;
    private final static int GETOUTQ = 2;
    private final static int GETJOB = 3;
    private final static int GETSBSD = 4;
    private final static int GETFD = 5;

    private CheckAS400Lang AS400Lang;
    private SSLSocket sslSocket;
    private Socket ioSocket;
    private PrintWriter ioWriter;
    private BufferedReader ioReader;
    private final boolean SSL = false;
    private final String logPrefix;

    public WorkWithProblemHandler(final String host, final String login, final String password) {
        super(host, login, password);
        this.logPrefix = "[" + WorkWithProblemHandler.INSTANCE_ID++ + "]";
    }

    private synchronized static long getAndIncrementLoginCount() {
        return WorkWithProblemHandler.LOGIN_COUNT++;
    }

    private synchronized static long getAndIncrementLogoutCount() {
        return WorkWithProblemHandler.LOGOUT_COUNT++;
    }

    public ResponseData getProblems(String lang) {
        ResponseData response = null;

        this.AS400Lang = new CheckAS400Lang(lang);
        ConnectorLogger.getInstance().debug(this.logPrefix + "Establishing connection to server...");
        if (this.open()) {
            ConnectorLogger.getInstance().debug(this.logPrefix + "done.\nLogging in...");
            boolean loggedIn = false;
            try {
                loggedIn = this.login();
            } catch (final Exception e) {
                ConnectorLogger.getInstance().debug(this.logPrefix + e.getMessage(), e);
                response = new ResponseData(ResponseData.statusError, e.getMessage());
                this.close();
                return response;
            }
            if (loggedIn) {
                ConnectorLogger.getInstance()
                        .debug(this.logPrefix + "LoginCount = " + WorkWithProblemHandler.getAndIncrementLoginCount());
                ConnectorLogger.getInstance().debug(this.logPrefix + "Login completed.\nSending command (WRKPRB)...");

                this.send("WRKPRB\r");
                String result = null;
                try {
                    result = this.waitReceive("F3=", WorkWithProblemHandler.NONE);
                } catch (final Exception e) {
                    this.logout();
                    response = new ResponseData(ResponseData.statusError, e.getMessage());
                    ConnectorLogger.getInstance().error(e.getMessage(), e);
                    return response;
                }

                if (result != null) {
                    HashMap<String, Object> attrs = new HashMap<String, Object>();
                    response = new ResponseData();

                    attrs.put("result", result);
                    response.getResult().add(attrs);
                    ConnectorLogger.getInstance().debug(this.logPrefix + "Finished.");
                } else {
                    response = new ResponseData(ResponseData.statusError, "Unexpected output on command");
                }

                this.logout();
            } else {
                this.logout();
                response = new ResponseData(ResponseData.statusError, "Unexpected output on login");
            }
        } else {
            response = new ResponseData(ResponseData.statusError, "Could not open connection to AS400");
        }

        return response;
    }

    // open connection to server
    public boolean open() {
        try {
            if (this.SSL) {
                final SSLSocket sslSocket = (SSLSocket) SSLSocketFactory.getDefault().createSocket(this.host, 992);
                this.ioWriter = new PrintWriter(sslSocket.getOutputStream(), true);
                this.ioReader = new BufferedReader(new InputStreamReader(sslSocket.getInputStream()));
            } else {
                ConnectorLogger.getInstance().debug(this.logPrefix + "Create socket...");
                this.ioSocket = new Socket(this.host, 23);
                this.ioSocket.setSoTimeout(6000);
                ConnectorLogger.getInstance().debug(this.logPrefix + "Get outputstream");
                this.ioWriter = new PrintWriter(this.ioSocket.getOutputStream(), true);
                ConnectorLogger.getInstance().debug(this.logPrefix + "Read from socket");
                this.ioReader = new BufferedReader(new InputStreamReader(this.ioSocket.getInputStream()));
                ConnectorLogger.getInstance().debug(this.logPrefix + "Reading done");
            }

            this.send("\n\r");

            return true;
        } catch (final Exception e) {
            ConnectorLogger.getInstance().debug(this.logPrefix + "CRITICAL: Network error", e);
            return false;
        }
    }

    // write str to stream
    public void send(final String str) {
        this.ioWriter.print(str);
        this.ioWriter.flush();
    }

    public boolean login() throws Exception {

        ConnectorLogger.getInstance().debug(this.logPrefix + "  waiting for screen...");
        /* Wait for the login screen */
        if (this.waitReceive("IBM CORP", WorkWithProblemHandler.NONE) != null) {
            ConnectorLogger.getInstance().debug(this.logPrefix + "  sending login information for " + this.login + "...");
            int unameLength;
            unameLength = this.login.length();
            /* send login user/pass */
            this.send(this.login);
            if (unameLength != 10) {
                this.send("\t");
            }

            this.send(this.password + "\r");

            ConnectorLogger.getInstance().debug(this.logPrefix + "  waiting for login to process...");
            /* Wait and receive command screen */
            if (this.waitReceive("===>", WorkWithProblemHandler.LOGIN) != null)
                return true;
        }
        return false;
    }

    // close connection to server
    public boolean close() {
        try {
            if (this.SSL) {
                this.sslSocket.close();
            } else {
                if (this.ioSocket != null) {
                    this.ioSocket.close();
                }
            }
            if (this.ioReader != null) {
                this.ioReader.close();
            }
            if (this.ioWriter != null) {
                this.ioWriter.close();
            }
            return true;
        } catch (final IOException e) {
            ConnectorLogger.getInstance().debug(this.logPrefix + "CRITICAL: Network error", e);
            return false;
        }
    }

    // Receives all info in stream until it sees the string 'str'.
    public String waitReceive(final String str, final int procedure) throws Exception {
        final StringBuilder buffer = new StringBuilder();
        boolean flag = true;

        ConnectorLogger.getInstance().debug(this.logPrefix + "    waiting for token " + str + "...");

        try {
            while (flag) {
                int ch;
                while ((ch = this.ioReader.read()) != -1) {
                    buffer.append((char) ch);

                    if (!this.ioReader.ready())
                        break;
                }
                ConnectorLogger.getInstance().trace("\n**BUFFER IS:**\n");
                final String convertedBuffer = ColorCodes.ParseColors(buffer.toString());
                ConnectorLogger.getInstance().trace(convertedBuffer);
                ConnectorLogger.getInstance().trace("\n**END OF BUFFER**\n");
                if (procedure == WorkWithProblemHandler.LOGIN) {
                    if (buffer.indexOf("CPF1107") != -1) {
                        this.close();
                        throw new Exception("CRITICAL - Login ERROR, Invalid password");
                    } else if (buffer.indexOf("CPF1120") != -1) {
                        this.close();
                        throw new Exception("CRITICAL - Login ERROR, Invalid username");
                    } else if (buffer.indexOf("/" + this.login.toUpperCase() + "/") != -1) {
                        ConnectorLogger.getInstance()
                                .debug(this.logPrefix + "      responding to allocated to another job message...");
                        this.send("\r");
                        buffer.setLength(0);
                    } else if (buffer.indexOf(this.AS400Lang.PASSWORD_HAS_EXPIRED) != -1) {
                        this.send((char) 27 + "3");
                        this.waitReceive("Exit sign-on request", WorkWithProblemHandler.NONE);
                        this.send("Y\r");
                        this.close();
                        throw new Exception("WARNING - Expired password, Please change it.");
                    } else if (buffer.indexOf("CPF1394") != -1) {
                        this.close();
                        throw new Exception("CRITICAL - Login ERROR, User profile " + this.login + " cannot sign on.");
                    } else if (buffer.indexOf(this.AS400Lang.PASSWORD_EXPIRES) != -1) {
                        ConnectorLogger.getInstance().debug(this.logPrefix + "      responding to password expires message...");
                        this.send("\r");
                        buffer.setLength(0);
                    } else if (buffer.indexOf(this.AS400Lang.DISPLAY_MESSAGES) != -1) {
                        ConnectorLogger.getInstance().debug(this.logPrefix + "      continuing through message display...");
                        this.send((char) 27 + "3");
                        buffer.setLength(0);
                    }
                } else if (procedure == WorkWithProblemHandler.GETOUTQ) {
                    if (buffer.indexOf(this.AS400Lang.NO_OUTPUT_QUEUES) != -1) {
                        this.logout();
                        throw new Exception("CRITICAL - outq does NOT exist");
                    }
                }
                // check for command not allowed errors
                if (procedure != WorkWithProblemHandler.LOGIN) {
                    if (buffer.indexOf(this.AS400Lang.LIBRARY_NOT_ALLOWED) != -1) {
                        this.send((char) 27 + "3");
                        this.logout();
                        throw new Exception("CRITICAL - Command NOT allowed");
                    }
                }
                if (buffer.indexOf(str) != -1)
                    flag = false;

            }
        } catch (final IOException e) {
            throw new Exception("CRITICAL: Network error:" + e);
        }

        ConnectorLogger.getInstance().debug(this.logPrefix + "    token received.");

        return buffer.toString();
    }

    public void logout() {
        // send F3
        ConnectorLogger.getInstance().debug(this.logPrefix + "Logging out...\n  sending F3...");
        this.send((char) 27 + "3");
        try {
            ConnectorLogger.getInstance().debug(this.logPrefix + "Wait for response...");
            this.waitReceive("===>", WorkWithProblemHandler.NONE);
            ConnectorLogger.getInstance().debug(this.logPrefix + "Response received. requesting signoff...");
            // send logout
            this.send("signoff *nolist\r");
            // waitReceive(";53H",NONE);
            ConnectorLogger.getInstance().debug(this.logPrefix + "Signoff sent. Wait for lockscreen...");
            waitReceive("IBM CORP", NONE);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error(e.getMessage(), e);
        } finally {
            this.close();
        }

        ConnectorLogger.getInstance().debug(this.logPrefix + "Job ending immediately");
        this.send("\r");
        // waitReceive(LANG.LOGIN_SCREEN, NONE);

        ConnectorLogger.getInstance().debug(this.logPrefix + "  terminating connection...");

        this.close();
        ConnectorLogger.getInstance().debug(this.logPrefix + "Logged out.");
        ConnectorLogger.getInstance()
                .debug(this.logPrefix + "LogoutCount = " + WorkWithProblemHandler.getAndIncrementLogoutCount());
    }
}
