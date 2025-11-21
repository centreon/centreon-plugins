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

package com.centreon.connector.as400.parser;

import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;

/**
 * @author Lamotte Jean-Baptiste
 */
public class OptionFactory {

    private OptionFactory() {

    }

    private static synchronized Options addAs400Options(final Options options) {

        OptionBuilder.withArgName("host");
        OptionBuilder.hasArg();
        OptionBuilder.withDescription("dns name or ip address");
        OptionBuilder.withLongOpt("host");
        final Option host = OptionBuilder.create('H');

        OptionBuilder.withArgName("login");
        OptionBuilder.hasArg();
        OptionBuilder.withDescription("login");
        OptionBuilder.withLongOpt("login");
        final Option login = OptionBuilder.create('l');

        OptionBuilder.withArgName("password");
        OptionBuilder.hasArg();
        OptionBuilder.withDescription("password");
        OptionBuilder.withLongOpt("password");
        final Option password = OptionBuilder.create('p');

        OptionBuilder.withArgName("check");
        OptionBuilder.hasArgs();
        OptionBuilder.withDescription("check command type");
        OptionBuilder.withLongOpt("check");
        final Option check = OptionBuilder.create('C');

        OptionBuilder.withArgName("args");
        OptionBuilder.hasArgs();
        OptionBuilder.withDescription("arguments for as400 request");
        OptionBuilder.withLongOpt("args");
        final Option args = OptionBuilder.create('A');

        options.addOption(host);
        options.addOption(login);
        options.addOption(password);
        options.addOption(check);
        options.addOption(args);

        return options;
    }

    /**
     * Gets the options.
     * 
     * @return the options
     */
    public static synchronized Options getOptions() {
        Options options = new Options();

        final Option daemon = Option.builder("D")
            .argName("port")
            .hasArg()
            .desc("Start the daemon on the specified port")
            .longOpt("port")
            .build();

        // Création des option générique
        final Option help = new Option("h", "help", false, "print this message");
        final Option version = new Option("v", "version", false, "print the version information and exit");
        final Option jmx = new Option("I", "as400", false, "Request type : as400");

        // Ajout des options de groupe unique
        final OptionGroup startType = new OptionGroup();
        startType.addOption(daemon);
        startType.addOption(jmx);
        startType.addOption(help);
        startType.addOption(version);
        startType.setRequired(true);
        options.addOptionGroup(startType);

        options = OptionFactory.addAs400Options(options);

        return options;
    }

}
