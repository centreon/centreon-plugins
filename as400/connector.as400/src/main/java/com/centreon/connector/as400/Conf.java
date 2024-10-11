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

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * @author Lamotte Jean-Baptiste
 */
public class Conf {

    public static void loadConfiguration(final InputStream in) throws IOException {
        final Properties properties = new Properties();
        properties.load(in);

        String param;

        Conf.debug = Boolean.parseBoolean("" + properties.get("debug"));
        Conf.exception = Boolean.parseBoolean("" + properties.get("exception"));
        Conf.trace = Boolean.parseBoolean("" + properties.get("trace"));

        param = (String)properties.get("daemonListenerHost");
        if (param != null) {
            Conf.daemonListenerHost = param;
        }
        
        param = (String)properties.get("daemonNoRequestTimeout");
        if (param != null) {
            Conf.daemonNoRequestTimeout = Integer.parseInt(param);
        }
        param = (String)properties.get("daemonRequestParseTimeout");
        if (param != null) {
            Conf.daemonRequestParseTimeout = Integer.parseInt(param);
        }

        Conf.authUsername = (String)properties.get("authUsername");
        Conf.authPassword = (String)properties.get("authPassword");
    
        param = (String)properties.get("keyStoreType");
        if (param != null) {
            Conf.keyStoreType = param;
        }
        Conf.keyStoreFile = (String)properties.get("keyStoreFile");
        Conf.keyStorePassword = (String)properties.get("keyStorePassword");

        param = (String)properties.get("sslProtocol");
        if (param != null) {
            Conf.sslProtocol = param;
        }

        Conf.daemonSoLinger = Integer.parseInt("" + properties.get("daemonSoLinger"));
        Conf.as400SoLinger = Integer.parseInt("" + properties.get("as400SoLinger"));
        Conf.as400ReadTimeout = Integer.parseInt("" + properties.get("as400ReadTimeout"));
        Conf.as400LoginTimeout = Integer.parseInt("" + properties.get("as400LoginTimeout"));
        Conf.as400ResourceDuration = Integer.parseInt("" + properties.get("as400ResourceDuration"));
        Conf.workerQueueTimeout = Integer.parseInt("" + properties.get("workerQueueTimeout"));
        Conf.cacheTimeout = Integer.parseInt("" + properties.get("cacheTimeout"));
        Conf.msgqDbPath = "" + properties.get("pathMsgQDB");
    }

    public static boolean debug = true;
    static boolean exception = true;
    static boolean trace = true;

    public static String msgqDbPath = "/tmp/";

    public static String daemonListenerHost = "localhost";

    public static int daemonNoRequestTimeout = 5000;

    public static int daemonRequestParseTimeout = 5000;

    public static String authUsername = null;

    public static String authPassword = null;

    public static String keyStoreType = "PKCS12";

    public static String keyStoreFile = null;
    
    public static String keyStorePassword = null;

    public static String sslProtocol = "TLS";

    /**
     * Delai avant fermeture force d'une connexion mal ferme par les plugins de
     * check (en mode daemon) unite en seconde
     */
    public static int daemonSoLinger = 1;

    /**
     * Delai avant fermeture force d'une connexion mal ferme par l'AS/400 unite en
     * seconde
     */
    public static int as400SoLinger = 1;

    /**
     * Timeout lors de la reception d'une reponse de l'AS400 unite en milliseconde
     */
    public static int as400ReadTimeout = 5 * 60 * 1000;

    /**
     * Timeout lors de la connexion a un as/400 unite en milliseconde
     */
    public static int as400LoginTimeout = 10 * 1000;

    /**
     * Delai avant de supprimer une connection inactive a un as/400 unite en
     * millisecondes
     */
    public static long as400ResourceDuration = 120 * 60 * 1000;

    /**
     * duree maximale d'attente d'un check dans une queue unite en millisecondes
     */
    public static long workerQueueTimeout = 6 * 60 * 1000;

    /**
     * cache duration for disk and job (time before next refresh) duration in
     * milliseconds
     */
    public static long cacheTimeout = 60 * 1000;
}
