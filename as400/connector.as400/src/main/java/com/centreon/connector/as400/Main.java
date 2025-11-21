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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.PosixParser;

import com.ibm.as400.access.Trace;
import com.centreon.connector.as400.daemon.Daemon;
import com.centreon.connector.as400.dispatcher.client.impl.ClientDispatcherImpl;
import com.centreon.connector.as400.parser.OptionFactory;

/**
 * @author Lamotte Jean-Baptiste
 */
class Main {
    static public final String CONNECTOR_LOG = "CONNECTOR_LOG";
    static public final String CONNECTOR_ETC = "CONNECTOR_ETC";

    static private String etcDir;

    static public String getEtcDir() {
        return etcDir;
    }

    private static void checkProperties() {
        etcDir = System.getProperty(Main.CONNECTOR_ETC, "/etc/centreon-as400/");
        String logDir = System.getProperty(Main.CONNECTOR_LOG, "/var/log/centreon-as400/");

        try {
            final File file = new File(etcDir + "log4j2.xml");
            if (!file.exists()) {
                ConnectorLogger.getInstance().fatal(etcDir + "log4j2.xml doesnt exist. Engine stopped");
                System.exit(0);
            }

            ConnectorLogger.getInstance().info("[Logs] Logs configuration file : " + file.getAbsolutePath());

        } catch (final Exception e) {
            ConnectorLogger.getInstance().fatal("", e);
        }

        System.setErr(System.out);

        try {
            ConnectorLogger.getInstance().info("[Config] Configuration file : " + etcDir + "config.properties");
            Conf.loadConfiguration(new FileInputStream(etcDir + "config.properties"));
        } catch (final IOException e) {
            ConnectorLogger.getInstance().fatal("", e);
            System.exit(0);
        }

        if (Conf.trace == true) {
            try {
                final String traceLog = logDir + "/trace.log";
                ConnectorLogger.getInstance().debug("Advanced trace log file : " + traceLog);

                Trace.setFileName(traceLog);
                Trace.setTraceAllOn(false);
                Trace.setTraceOn(true);
                Trace.setTraceErrorOn(true);
                Trace.setTraceWarningOn(true);
                Trace.setTraceInformationOn(true);

            } catch (final Exception e) {
                ConnectorLogger.getInstance().debug("", e);
            }
        }
    }

    private static void daemon(final CommandLine cmd) {
        try {
            int port = 8091;

            if (cmd.hasOption("port")) {
                port = Integer.parseInt(cmd.getOptionValue("port"));
            }
            final Daemon core = new Daemon();
            core.start(port);
        } catch (IOException ioe) {
            System.out.println("Couldn't start server: " + ioe);
        } catch (InterruptedException ie) {
            System.out.println("Interrupted exception: " + ie);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().fatal("Couldn't start server", e);
        } finally {
            System.exit(0);
        }
    }

    /**
     * Gets the help.
     *
     * @return the help
     */

    private static String getHelp() {
        final HelpFormatter formatter = new HelpFormatter();
        String exemple = "--port <port>\n";
        exemple += "\n";

        formatter.printHelp(" ", exemple, OptionFactory.getOptions(), "");

        return "";
    }

    /**
     * The main method.
     *
     * @param args the arguments
     */
    public static void main(final String[] args) {

        Runtime.getRuntime().addShutdownHook(new Thread() {

            @Override
            public void run() {
                ConnectorLogger.getInstance().info("Shutdown Centreon-Connector");
                super.run();
            }

        });

        Main.checkProperties();

        try {

            final CommandLineParser parser = new PosixParser();
            final CommandLine cmd = parser.parse(OptionFactory.getOptions(), args);
    
            Main.daemon(cmd);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().fatal("", e);
            Main.getHelp();
        }
    }

}
