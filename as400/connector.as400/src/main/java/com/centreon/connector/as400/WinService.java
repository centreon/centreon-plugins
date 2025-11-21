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

package com.centreon.connector.as400;

/**
 * Launch the Engine from a variety of sources, either through a main() or
 * invoked through Apache Daemon.
 */
public class WinService {

    public static void main(final String[] args) throws Exception {
        WinService.start(new String[] { "--port", "8091" });
    }

    public static void start(final String[] args) throws Exception {
        final String[] tabArgs = new String[(args.length + 1)];

        tabArgs[0] = "service";
        int i = 1;
        for (final String str : args) {
            tabArgs[i] = str;
            i++;
        }

        final Thread thread = new Thread() {
            @Override
            public void run() {
                Main.main(tabArgs);
            }
        };
        thread.setDaemon(false);
        thread.start();

        // Main.main(new String[] {"service", "--daemon", "8090"});
        // System.out.println("Out:EngineLauncher#start");
        // ConnectorLogger.getInstance().info("EngineLauncher#start");

        /*
         * Thread thread = new Thread() {
         * 
         * @Override public void run() { while (true) { try { Thread.sleep(1000); }
         * catch (InterruptedException e) { e.printStackTrace(); }
         * System.out.println("Out:EngineLauncher#isRunning");
         * ConnectorLogger.getInstance().info("EngineLauncher#isRunning"); } }
         * 
         * };
         * 
         * thread.start();
         */
    }

    public static void stop(final String[] args) throws Exception {
        System.out.println("Out:EngineLauncher#stop");
        ConnectorLogger.getInstance().info("EngineLauncher#stop");
        System.exit(0);
    }

}
