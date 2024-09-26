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

package com.centreon.connector.as400.utils;

import java.nio.charset.Charset;

import com.centreon.connector.as400.ConnectorLogger;

public final class StringUtils {

    public static final Charset CHARSET = Charset.forName("UTF-8"); //$NON-NLS-1$

    public static final String NEW_LINE = System.getProperty("line.separator"); //$NON-NLS-1$
    public static final String EMPTY_STRING = ""; //$NON-NLS-1$
    public static final String SLASH = "/"; //$NON-NLS-1$
    public static final String VIRGULE = ","; //$NON-NLS-1$

    public static boolean isNullEmptyOrBlank(final String string) {
        if (string == null) {
            return true;
        }
        if (string.length() == 0) {
            return true;
        }
        if (string.trim().length() == 0) {
            return true;
        }
        return "null".equalsIgnoreCase(string.trim()); //$NON-NLS-1$
    }

    public static boolean isOneNullEmptyOrBlank(final String... args) {
        for (final String arg : args) {
            if (StringUtils.isNullEmptyOrBlank(arg)) {
                return true;
            }
        }
        return false;
    }

    public static String nonNullString(final String string) {
        if (string == null) {
            return StringUtils.EMPTY_STRING;
        }
        return string;
    }

    public static double parseDouble(final String input) {
        return StringUtils.parseDouble(input, -1d);
    }

    public static double parseDouble(final String input, final double errorValue) {
        if ((input == null) || (input.length() == 0)) {
            return errorValue;
        }
        try {
            return Double.parseDouble(input);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            return errorValue;
        }
    }

    public static int parseInt(final String input) {
        return StringUtils.parseInt(input, -1);
    }

    public static int parseInt(final String input, final int errorValue) {
        if ((input == null) || (input.length() == 0)) {
            return errorValue;
        }
        try {
            return Integer.parseInt(input);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            return errorValue;
        }
    }

    public static long parseLong(final String input) {
        return StringUtils.parseLong(input, Long.MIN_VALUE);
    }

    public static long parseLong(final String input, final long errorValue) {
        if ((input == null) || (input.length() == 0)) {
            return errorValue;
        }
        try {
            return Long.parseLong(input);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            return errorValue;
        }
    }

    public static String toHex(final int value, final int length) {
        String hex = Integer.toHexString(value);
        while (hex.length() < length) {
            hex = '0' + hex;
        }
        return hex;
    }

    private StringUtils() {
        // hide constructor
    }

}
