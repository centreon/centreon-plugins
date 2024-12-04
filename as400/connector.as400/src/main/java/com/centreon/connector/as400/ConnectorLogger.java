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

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.LoggerContext;
import java.io.File;

/**
 * @author Lamotte Jean-Baptiste
 */
public class ConnectorLogger {

    private static ConnectorLogger instance = null;

    public synchronized static final ConnectorLogger getInstance() {
        if (ConnectorLogger.instance == null) {
            ConnectorLogger.instance = new ConnectorLogger(Main.getEtcDir());
        }
        return ConnectorLogger.instance;
    }

    private Logger logger = null;

    private ConnectorLogger(String etcDir) {
        if ((etcDir != null) && (etcDir.length() > 0)) {
            LoggerContext context = (org.apache.logging.log4j.core.LoggerContext) LogManager.getContext(false);
            File file = new File(etcDir + "log4j2.xml");
            context.setConfigLocation(file.toURI());
        } else {
            // DOMConfigurator.configure("log4j.xml");
        }
        this.logger = LogManager.getRootLogger();
    }

    public synchronized void debug(final String log) {
        this.logger.debug(log);
    }

    public synchronized void trace(final String log, final Throwable t) {
        this.logger.trace(log, t);
    }

    public synchronized void trace(final String log) {
        this.logger.trace(log);
    }

    public synchronized void debug(final String log, final Throwable t) {
        if (Conf.exception) {
            this.logger.debug(log, t);
        } else {
            this.logger.debug(log);
            this.logger.debug("    --> Message: " + t.getMessage());
            Throwable cause = null;
            if ((cause = t.getCause()) != null) {
                this.logger.debug("            --> Cause: " + cause.getMessage());
            }
        }
    }

    public synchronized void error(final String log) {
        this.logger.error(log);
    }

    public void error(final String log, final Throwable t) {
        if (Conf.exception) {
            this.logger.error(log, t);
        } else {
            this.logger.error(log);
            this.logger.error("    --> Message: " + t.getMessage());
            Throwable cause = null;
            if ((cause = t.getCause()) != null) {
                this.logger.error("            --> Cause: " + cause.getMessage());
            }
        }
    }

    public synchronized void fatal(final String log) {
        this.logger.fatal(log);
    }

    public synchronized void fatal(final String log, final Throwable t) {
        if (Conf.exception) {
            this.logger.fatal(log, t);
        } else {
            this.logger.fatal(log);
            this.logger.fatal("    --> Message: " + t.getMessage());
            Throwable cause = null;
            if ((cause = t.getCause()) != null) {
                this.logger.fatal("            --> Cause: " + cause.getMessage());
            }
        }
    }

    public synchronized Logger getLogger() {
        return this.logger;
    }

    public synchronized void info(final String log) {
        this.logger.info(log);
    }

    public synchronized void info(final String log, final Throwable t) {
        if (Conf.exception) {
            this.logger.info(log, t);
        } else {
            this.logger.info(log);
            this.logger.info("    --> Message: " + t.getMessage());
            Throwable cause = null;
            if ((cause = t.getCause()) != null) {
                this.logger.info("            --> Cause: " + cause.getMessage());
            }
        }
    }

    public synchronized void warn(final String log) {
        this.logger.warn(log);
    }

    public synchronized void warn(final String log, final Throwable t) {
        if (Conf.exception) {
            this.logger.warn(log, t);
        } else {
            this.logger.warn(log);
            this.logger.warn("    --> Message: " + t.getMessage());
            Throwable cause = null;
            if ((cause = t.getCause()) != null) {
                this.logger.warn("            --> Cause: " + cause.getMessage());
            }
        }
    }
}
