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

public final class HexUtils {

    private static final char[] K_HEX_CHARS = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E',
            'F' };

    public static String bufferToHex(final byte[] buffer) {
        return HexUtils.bufferToHex(buffer, 0, buffer.length);
    }

    public static byte[] hexToBuffer(final String hex) {
        final byte[] bytes = new byte[hex.length() / 2];
        for (int i = 0; i < (hex.length() - 1); i += 2) {
            final String output = hex.substring(i, i + 2);
            bytes[i / 2] = (byte) Integer.parseInt(output, 16);
        }
        return bytes;
    }

    private static void appendHexPair(final byte b, final StringBuilder hexString) {
        final char highNibble = HexUtils.K_HEX_CHARS[(b & 0xF0) >> 4];
        final char lowNibble = HexUtils.K_HEX_CHARS[b & 0x0F];
        hexString.append(highNibble);
        hexString.append(lowNibble);
    }

    private static String bufferToHex(final byte[] buffer, final int startOffset, final int length) {
        final StringBuilder hexString = new StringBuilder(2 * length);
        final int endOffset = startOffset + length;
        for (int i = startOffset; i < endOffset; i++) {
            HexUtils.appendHexPair(buffer[i], hexString);
        }
        return hexString.toString();
    }

    private HexUtils() {
    }

}
