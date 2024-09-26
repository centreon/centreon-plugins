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

import java.security.GeneralSecurityException;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import com.centreon.connector.as400.ConnectorLogger;

public final class BlowFishUtils {

    private static final String BLOWFISH = "Blowfish"; //$NON-NLS-1$
    private static final String TRANSFORMATION = "Blowfish/CBC/PKCS5Padding"; //$NON-NLS-1$
    private static final byte[] KEY = "3fe7b4d9e0b50a".getBytes(StringUtils.CHARSET); //$NON-NLS-1$
    private static final byte[] IV_BYTES = "00000000".getBytes(StringUtils.CHARSET); //$NON-NLS-1$

    public static final String decrypt(final String cryptedMessage) {
        if (cryptedMessage == null) {
            return StringUtils.EMPTY_STRING;
        }
        try {
            final byte[] buffer = HexUtils.hexToBuffer(cryptedMessage);
            return new String(BlowFishUtils.decrypt(buffer, BlowFishUtils.KEY), StringUtils.CHARSET);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            return StringUtils.EMPTY_STRING;
        }
    }

    public static final String encrypt(final String message) {
        if (message == null) {
            return StringUtils.EMPTY_STRING;
        }
        try {
            final byte[] crypted = BlowFishUtils.encrypt(message.getBytes(StringUtils.CHARSET), BlowFishUtils.KEY);
            return HexUtils.bufferToHex(crypted);
        } catch (final Exception e) {
            ConnectorLogger.getInstance().error("", e);
            return StringUtils.EMPTY_STRING;
        }
    }

    private static final byte[] decrypt(final byte[] encrypted, final byte[] key) throws GeneralSecurityException {
        final SecretKeySpec skeySpec = new SecretKeySpec(key, BlowFishUtils.BLOWFISH);
        final Cipher cipher = Cipher.getInstance(BlowFishUtils.TRANSFORMATION);
        final IvParameterSpec ivs = new IvParameterSpec(BlowFishUtils.IV_BYTES);
        cipher.init(Cipher.DECRYPT_MODE, skeySpec, ivs);
        return cipher.doFinal(encrypted);
    }

    private static final byte[] encrypt(final byte[] messageBytes, final byte[] key) throws GeneralSecurityException {
        final SecretKeySpec skeySpec = new SecretKeySpec(key, BlowFishUtils.BLOWFISH);
        final Cipher cipher = Cipher.getInstance(BlowFishUtils.TRANSFORMATION);
        final IvParameterSpec ivs = new IvParameterSpec(BlowFishUtils.IV_BYTES);
        cipher.init(Cipher.ENCRYPT_MODE, skeySpec, ivs);
        return cipher.doFinal(messageBytes);
    }

    private BlowFishUtils() {
        // hide
    }
}
