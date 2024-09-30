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

public class CheckAS400Lang {
    // These constants are referenced during parsing so
    // that the correct phrases are found.

    // This is found at the bottom when you type dspjob (name of a job
    // that exists)
    public String SELECTION = "Selection";

    // This is the status of job or sbs when you type dspjob or dspsbsd
    public String ACTIVE = "ACTIVE";

    // This is the "DB Capability" dsplay when you type wrksyssts
    public String DB_CAPABILITY = "DB capability";

    // This is le display for the login screen
    public String LOGIN_SCREEN = "System  . . . . .";

    // Run dspmsg and it will display "No messages available" if there are no
    // messages
    public String NO_MESSAGES_AVAILABLE = "No messages available";

    // The "password has expired"/"password expires" messages are the messages
    // you get when you login with an account which has an expired/will expire
    // password.
    public String PASSWORD_HAS_EXPIRED = "Password has expired";
    public String PASSWORD_EXPIRES = "password expires";

    // The "Display Messages" is what you get after logging into an account
    // which displays any messages before continuing to the menu.
    public String DISPLAY_MESSAGES = "Display Messages";

    // Run wrkoutq blah* and it will say "(No output queues)"
    public String NO_OUTPUT_QUEUES = "No output queues";

    // If you type dspsbsd blah it will say "...not found..."
    public static String NOT_FOUND = "not found";

    // If you type dspjob QINTER, it should complain that there are duplicate
    // jobs and print at the bottom of the window "duplicate jobs found"
    public String DUPLICATE = "Duplicate";

    // if you type dspjob blah, it will respond Job //blah not found
    // Only put the Job // part.
    public String JOB = "Job //";

    // If try and execute a command that you are not allowed it will say
    // "library *LIBL not allowed"
    public String LIBRARY_NOT_ALLOWED = "library *LIBL not allowed";

    // On a login with an expired password we look for "Exit sign-on" on the
    // screen before we send the F3 to exit and disconnect.
    public static String EXIT_SIGNON = "Exit sign-on request";

    // If you type WRKACTJOB it may respond "No active jobs to display"
    // when there is no job like searched for in the sytem
    public String NO_JOB_TO_DISPLAY = "No active jobs to display";

    // Messages needing a reply OR Messages not needing a reply
    public String MSG_NEED_REPLY = "Messages needing a reply";
    public String MSG_NOT_NEED_REPLY = "Messages not needing a reply";

    // WRKDSKSTS The "Request/Compression/Bottom" message.
    public String REQUEST_WORD = "Request";
    public String DSK_STS_COMPRESSION = "Compression";
    public String LIST_END = "Bottom";

    public CheckAS400Lang(String lang) {
        if (lang != null && lang.equals("fr")) {
            this.setLangFr();
        } else {
            this.setLangEn();
        }
    }

    public void setLangFr() {
        this.SELECTION = "Selection";
        this.ACTIVE = "ACTIVE";
        this.DB_CAPABILITY = "DB capability";
        this.LOGIN_SCREEN = "System  . . . . .";
        this.NO_MESSAGES_AVAILABLE = "No messages available";
        this.PASSWORD_HAS_EXPIRED = "Password has expired";
        this.PASSWORD_EXPIRES = "password expires";
        this.DISPLAY_MESSAGES = "Display Messages";
        this.NO_OUTPUT_QUEUES = "No output queues";
        this.NOT_FOUND = "not found";
        this.DUPLICATE = "Duplicate";
        this.JOB = "Job //";
        this.LIBRARY_NOT_ALLOWED = "library *LIBL not allowed";
        this.EXIT_SIGNON = "Exit sign-on request";
        this.NO_JOB_TO_DISPLAY = "No active jobs to display";
        this.MSG_NEED_REPLY = "Messages needing a reply";
        this.MSG_NOT_NEED_REPLY = "Messages not needing a reply";
        this.REQUEST_WORD = "Request";
        this.DSK_STS_COMPRESSION = "Compression";
        this.LIST_END = "Bottom";
    }

    public void setLangEn() {
        this.SELECTION = "Selection";
        this.ACTIVE = "ACTIVE";
        this.DB_CAPABILITY = "DB capability";
        this.LOGIN_SCREEN = "System  . . . . .";
        this.NO_MESSAGES_AVAILABLE = "No messages available";
        this.PASSWORD_HAS_EXPIRED = "Password has expired";
        this.PASSWORD_EXPIRES = "password expires";
        this.DISPLAY_MESSAGES = "Display Messages";
        this.NO_OUTPUT_QUEUES = "No output queues";
        this.NOT_FOUND = "not found";
        this.DUPLICATE = "Duplicate";
        this.JOB = "Job //";
        this.LIBRARY_NOT_ALLOWED = "library *LIBL not allowed";
        this.EXIT_SIGNON = "Exit sign-on request";
        this.NO_JOB_TO_DISPLAY = "No active jobs to display";
        this.MSG_NEED_REPLY = "Messages needing a reply";
        this.MSG_NOT_NEED_REPLY = "Messages not needing a reply";
        this.REQUEST_WORD = "Request";
        this.DSK_STS_COMPRESSION = "Compression";
        this.LIST_END = "Bottom";
    }
};
