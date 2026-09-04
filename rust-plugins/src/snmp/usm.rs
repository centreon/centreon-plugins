//
// Copyright 2026-Present Centreon (http://www.centreon.com/)
//
// Centreon is a full-fledged industry-strength solution that meets
// the needs in IT infrastructure and application monitoring for
// service performance.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//! SNMPv3 User-based Security Model (USM).
//!
//! `rasn-snmp` provides the v3 ASN.1 message structures; everything that
//! makes them *secure* lives here:
//!
//! * key derivation — password → key ([RFC 3414 §A.2](https://www.rfc-editor.org/rfc/rfc3414#appendix-A.2))
//!   then localization to the authoritative engine;
//! * authentication — truncated HMAC over the whole encoded message
//!   (RFC 3414 for MD5/SHA-1, [RFC 7860](https://www.rfc-editor.org/rfc/rfc7860)
//!   for the SHA-2 family);
//! * privacy — DES-CBC (RFC 3414 §8) and AES-128-CFB
//!   ([RFC 3826](https://www.rfc-editor.org/rfc/rfc3826));
//! * engine discovery and time synchronization (RFC 3414 §4).
//!
//! Design note: authentication computes the HMAC over the message encoded
//! with the authentication parameters zeroed out, then patches the digest
//! back in place. The patch is a byte-substitution of the placeholder, which
//! is safe because the placeholder length equals the digest length — the
//! encoding (and therefore every length prefix) is unchanged.

use crate::generic::error::Error::{UsmFailure, UsmUnsupported};
use crate::generic::error::Result;
use hmac::{Hmac, KeyInit, Mac};
use rasn::types::{Integer, OctetString};
use rasn_snmp::v3::{HeaderData, Message, ScopedPdu, ScopedPduData, USMSecurityParameters};

/// Size of the buffer hashed by the password-to-key algorithm (RFC 3414 §A.2).
const PASSWORD_EXPANSION_BYTES: usize = 1_048_576;

/// SNMP security model identifier for USM (RFC 3411).
const SECURITY_MODEL_USM: u32 = 3;

/// Maximum message size we advertise to the agent.
const MAX_MESSAGE_SIZE: u32 = 65507;

/// Authentication protocol of a v3 user.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthProtocol {
    Md5,
    Sha1,
    Sha224,
    Sha256,
    Sha384,
    Sha512,
}

impl AuthProtocol {
    /// Parses the CLI spelling (mirror of the Perl `--authprotocol`).
    pub fn parse(name: &str) -> Result<AuthProtocol> {
        match name.to_ascii_uppercase().as_str() {
            "MD5" => Ok(AuthProtocol::Md5),
            "SHA" | "SHA1" => Ok(AuthProtocol::Sha1),
            "SHA224" => Ok(AuthProtocol::Sha224),
            "SHA256" => Ok(AuthProtocol::Sha256),
            "SHA384" => Ok(AuthProtocol::Sha384),
            "SHA512" => Ok(AuthProtocol::Sha512),
            other => Err(UsmUnsupported {
                what: format!("authentication protocol '{}'", other),
                supported: "MD5, SHA (SHA1), SHA224, SHA256, SHA384, SHA512",
            }),
        }
    }

    /// Length of the digest carried in `msgAuthenticationParameters`.
    ///
    /// 12 bytes for MD5/SHA-1 (RFC 3414 §6.3.1); for the SHA-2 family the
    /// RFC 7860 protocol *names* encode the truncation:
    /// `usmHMAC128SHA224` → 128 bits, `usmHMAC192SHA256` → 192 bits,
    /// `usmHMAC256SHA384` → 256 bits, `usmHMAC384SHA512` → 384 bits.
    fn tag_len(self) -> usize {
        match self {
            AuthProtocol::Md5 | AuthProtocol::Sha1 => 12,
            AuthProtocol::Sha224 => 16,
            AuthProtocol::Sha256 => 24,
            AuthProtocol::Sha384 => 32,
            AuthProtocol::Sha512 => 48,
        }
    }

    /// Hashes `data` with this protocol's digest function.
    fn digest(self, data: &[u8]) -> Vec<u8> {
        use md5::Digest;
        match self {
            AuthProtocol::Md5 => md5::Md5::digest(data).to_vec(),
            AuthProtocol::Sha1 => sha1::Sha1::digest(data).to_vec(),
            AuthProtocol::Sha224 => sha2::Sha224::digest(data).to_vec(),
            AuthProtocol::Sha256 => sha2::Sha256::digest(data).to_vec(),
            AuthProtocol::Sha384 => sha2::Sha384::digest(data).to_vec(),
            AuthProtocol::Sha512 => sha2::Sha512::digest(data).to_vec(),
        }
    }

    /// Streaming variant of [`Self::digest`] used by the password-to-key
    /// expansion, which hashes 1 MB without materializing it.
    fn digest_expanded(self, password: &[u8]) -> Vec<u8> {
        fn feed<D: md5::Digest>(password: &[u8]) -> Vec<u8> {
            let mut hasher = D::new();
            let mut written = 0usize;
            let mut chunk = Vec::with_capacity(64);
            let mut cursor = 0usize;
            while written < PASSWORD_EXPANSION_BYTES {
                chunk.clear();
                while chunk.len() < 64 && written + chunk.len() < PASSWORD_EXPANSION_BYTES {
                    chunk.push(password[cursor % password.len()]);
                    cursor += 1;
                }
                hasher.update(&chunk);
                written += chunk.len();
            }
            hasher.finalize().to_vec()
        }
        match self {
            AuthProtocol::Md5 => feed::<md5::Md5>(password),
            AuthProtocol::Sha1 => feed::<sha1::Sha1>(password),
            AuthProtocol::Sha224 => feed::<sha2::Sha224>(password),
            AuthProtocol::Sha256 => feed::<sha2::Sha256>(password),
            AuthProtocol::Sha384 => feed::<sha2::Sha384>(password),
            AuthProtocol::Sha512 => feed::<sha2::Sha512>(password),
        }
    }

    /// Computes the truncated HMAC of `data` with the localized key.
    fn hmac(self, key: &[u8], data: &[u8]) -> Vec<u8> {
        fn mac<D>(key: &[u8], data: &[u8]) -> Vec<u8>
        where
            D: hmac::EagerHash,
        {
            let mut mac =
                <Hmac<D> as KeyInit>::new_from_slice(key).expect("HMAC accepts keys of any length");
            mac.update(data);
            mac.finalize().into_bytes().to_vec()
        }
        let full = match self {
            AuthProtocol::Md5 => mac::<md5::Md5>(key, data),
            AuthProtocol::Sha1 => mac::<sha1::Sha1>(key, data),
            AuthProtocol::Sha224 => mac::<sha2::Sha224>(key, data),
            AuthProtocol::Sha256 => mac::<sha2::Sha256>(key, data),
            AuthProtocol::Sha384 => mac::<sha2::Sha384>(key, data),
            AuthProtocol::Sha512 => mac::<sha2::Sha512>(key, data),
        };
        full[..self.tag_len()].to_vec()
    }
}

/// Privacy (encryption) protocol of a v3 user.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrivProtocol {
    /// CBC-DES, RFC 3414 §8.
    Des,
    /// CFB128-AES-128, RFC 3826.
    Aes128,
}

impl PrivProtocol {
    /// Parses the CLI spelling (mirror of the Perl `--privprotocol`).
    pub fn parse(name: &str) -> Result<PrivProtocol> {
        match name.to_ascii_uppercase().as_str() {
            "DES" => Ok(PrivProtocol::Des),
            "AES" | "AES128" => Ok(PrivProtocol::Aes128),
            other => Err(UsmUnsupported {
                what: format!("privacy protocol '{}'", other),
                // AES-192/256 exist only as expired drafts with two
                // incompatible key-extension variants (Blumenthal, Reeder);
                // implementing the wrong one silently fails to interoperate.
                supported: "DES, AES (AES128)",
            }),
        }
    }

    /// Number of key bytes consumed from the localized key.
    fn key_len(self) -> usize {
        match self {
            PrivProtocol::Des => 16, // 8 key bytes + 8 pre-IV bytes
            PrivProtocol::Aes128 => 16,
        }
    }
}

/// Credentials and derived keys of a v3 user, localized to one engine.
#[derive(Debug, Clone)]
pub struct UsmUser {
    pub name: String,
    pub auth: Option<(AuthProtocol, String)>,
    pub priv_: Option<(PrivProtocol, String)>,
    /// SNMP context name (mirror of the Perl `--contextname`). Selects the
    /// view of the MIB inside the engine; empty for the default context.
    pub context_name: String,
    /// SNMP context engine ID (mirror of the Perl `--contextengineid`).
    /// Empty means "the authoritative engine", which is the usual case.
    pub context_engine_id: Option<Vec<u8>>,
}

/// Security level derived from the configured credentials (RFC 3411).
/// The variant names are the RFC's own spelling — kept verbatim so that code
/// and specification read the same.
#[allow(clippy::enum_variant_names)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SecurityLevel {
    NoAuthNoPriv,
    AuthNoPriv,
    AuthPriv,
}

impl UsmUser {
    /// Security level implied by the credentials. Privacy without
    /// authentication is forbidden by the model (RFC 3414 §1.4).
    pub fn level(&self) -> Result<SecurityLevel> {
        match (&self.auth, &self.priv_) {
            (None, None) => Ok(SecurityLevel::NoAuthNoPriv),
            (Some(_), None) => Ok(SecurityLevel::AuthNoPriv),
            (Some(_), Some(_)) => Ok(SecurityLevel::AuthPriv),
            (None, Some(_)) => Err(UsmFailure {
                reason: "privacy requires authentication (authPriv): provide --authprotocol and --authpassphrase".to_string(),
            }),
        }
    }
}

/// Keys localized to a specific authoritative engine.
#[derive(Debug, Clone)]
pub struct LocalizedKeys {
    pub auth: Option<(AuthProtocol, Vec<u8>)>,
    pub priv_: Option<(PrivProtocol, Vec<u8>)>,
}

/// Derives a key from a passphrase (RFC 3414 §A.2): the passphrase is
/// repeated to fill 1 MB, hashed, then localized to the engine by hashing
/// `Ku || engineID || Ku`.
pub fn localize_key(proto: AuthProtocol, passphrase: &str, engine_id: &[u8]) -> Vec<u8> {
    let ku = proto.digest_expanded(passphrase.as_bytes());
    let mut buf = Vec::with_capacity(ku.len() * 2 + engine_id.len());
    buf.extend_from_slice(&ku);
    buf.extend_from_slice(engine_id);
    buf.extend_from_slice(&ku);
    proto.digest(&buf)
}

impl UsmUser {
    /// Localizes every configured key to `engine_id`.
    ///
    /// The privacy key is derived with the **authentication** digest — the
    /// privacy protocol only says how many bytes are consumed (RFC 3414 §8.1.1).
    pub fn localize(&self, engine_id: &[u8]) -> Result<LocalizedKeys> {
        let auth = self
            .auth
            .as_ref()
            .map(|(proto, pass)| (*proto, localize_key(*proto, pass, engine_id)));
        let priv_ = match (&self.priv_, &self.auth) {
            (Some((pproto, ppass)), Some((aproto, _))) => {
                let key = localize_key(*aproto, ppass, engine_id);
                if key.len() < pproto.key_len() {
                    // Only reachable with AES-192/256, which parse() rejects.
                    return Err(UsmFailure {
                        reason: format!(
                            "localized key too short for the privacy protocol ({} < {} bytes)",
                            key.len(),
                            pproto.key_len()
                        ),
                    });
                }
                Some((*pproto, key[..pproto.key_len()].to_vec()))
            }
            _ => None,
        };
        Ok(LocalizedKeys { auth, priv_ })
    }
}

/// Authoritative engine parameters, discovered then reused for the session.
#[derive(Debug, Clone, Default)]
pub struct EngineParams {
    pub id: Vec<u8>,
    pub boots: u32,
    pub time: u32,
}

/// Builds the message flags byte (RFC 3412 §6.4).
fn flags_byte(level: SecurityLevel, reportable: bool) -> u8 {
    let mut flags = match level {
        SecurityLevel::NoAuthNoPriv => 0b000,
        SecurityLevel::AuthNoPriv => 0b001,
        SecurityLevel::AuthPriv => 0b011,
    };
    if reportable {
        flags |= 0b100;
    }
    flags
}

/// A unique salt per outgoing encrypted message. Uniqueness (not
/// unpredictability) is what RFC 3414/3826 require of the salt.
fn next_salt() -> u64 {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let seed = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos() as u64)
        .unwrap_or(0);
    seed ^ (u64::from(std::process::id()) << 32) ^ n
}

/// Encrypts a scoped PDU, returning the ciphertext and the privacy parameters.
fn encrypt(
    proto: PrivProtocol,
    key: &[u8],
    engine: &EngineParams,
    plaintext: &[u8],
) -> Result<(Vec<u8>, Vec<u8>)> {
    use cipher::{BlockModeEncrypt, InnerIvInit, KeyInit as CipherKeyInit, KeyIvInit};
    match proto {
        PrivProtocol::Des => {
            // RFC 3414 §8.1.1.1: key = first 8 bytes, pre-IV = last 8 bytes,
            // salt = engineBoots || local counter, IV = pre-IV XOR salt.
            let salt_low = next_salt() as u32;
            let mut salt = [0u8; 8];
            salt[..4].copy_from_slice(&engine.boots.to_be_bytes());
            salt[4..].copy_from_slice(&salt_low.to_be_bytes());
            let mut iv = [0u8; 8];
            for (i, byte) in iv.iter_mut().enumerate() {
                *byte = key[8 + i] ^ salt[i];
            }
            // CBC requires whole blocks: pad with zeros (RFC 3414 §8.1.1.2,
            // the padding is discarded by the ASN.1 length on decode).
            let mut buf = plaintext.to_vec();
            while !buf.len().is_multiple_of(8) {
                buf.push(0);
            }
            let encryptor =
                cbc::Encryptor::<des::Des>::new_from_slices(&key[..8], &iv).map_err(|_| {
                    UsmFailure {
                        reason: "invalid DES key or IV length".to_string(),
                    }
                })?;
            let len = buf.len();
            let mut out = buf.clone();
            encryptor
                .encrypt_padded::<cipher::block_padding::NoPadding>(&mut out, len)
                .map_err(|_| UsmFailure {
                    reason: "DES encryption failed".to_string(),
                })?;
            Ok((out, salt.to_vec()))
        }
        PrivProtocol::Aes128 => {
            // RFC 3826 §3.1.2.1: IV = engineBoots || engineTime || salt,
            // salt is a 64-bit unique value carried in privacy parameters.
            let salt = next_salt().to_be_bytes();
            let mut iv = [0u8; 16];
            iv[..4].copy_from_slice(&engine.boots.to_be_bytes());
            iv[4..8].copy_from_slice(&engine.time.to_be_bytes());
            iv[8..].copy_from_slice(&salt);
            // CFB128 over an arbitrary-length payload: the buffered variant
            // keeps the keystream position, no padding is added (RFC 3826).
            let mut out = plaintext.to_vec();
            let aes = aes::Aes128::new_from_slice(key).map_err(|_| UsmFailure {
                reason: "invalid AES key length".to_string(),
            })?;
            let mut cipher =
                cfb_mode::BufEncryptor::inner_iv_slice_init(aes, &iv).map_err(|_| UsmFailure {
                    reason: "invalid AES IV length".to_string(),
                })?;
            cipher.encrypt(&mut out);
            Ok((out, salt.to_vec()))
        }
    }
}

/// Decrypts a scoped PDU received from the agent.
fn decrypt(
    proto: PrivProtocol,
    key: &[u8],
    engine: &EngineParams,
    priv_params: &[u8],
    ciphertext: &[u8],
) -> Result<Vec<u8>> {
    use cipher::{BlockModeDecrypt, InnerIvInit, KeyInit as CipherKeyInit, KeyIvInit};
    match proto {
        PrivProtocol::Des => {
            if priv_params.len() != 8 {
                return Err(UsmFailure {
                    reason: "malformed DES privacy parameters".to_string(),
                });
            }
            let mut iv = [0u8; 8];
            for (i, byte) in iv.iter_mut().enumerate() {
                *byte = key[8 + i] ^ priv_params[i];
            }
            let decryptor =
                cbc::Decryptor::<des::Des>::new_from_slices(&key[..8], &iv).map_err(|_| {
                    UsmFailure {
                        reason: "invalid DES key or IV length".to_string(),
                    }
                })?;
            let mut out = ciphertext.to_vec();
            let plain = decryptor
                .decrypt_padded::<cipher::block_padding::NoPadding>(&mut out)
                .map_err(|_| UsmFailure {
                    reason: "DES decryption failed".to_string(),
                })?
                .to_vec();
            Ok(plain)
        }
        PrivProtocol::Aes128 => {
            if priv_params.len() != 8 {
                return Err(UsmFailure {
                    reason: "malformed AES privacy parameters".to_string(),
                });
            }
            let mut iv = [0u8; 16];
            iv[..4].copy_from_slice(&engine.boots.to_be_bytes());
            iv[4..8].copy_from_slice(&engine.time.to_be_bytes());
            iv[8..].copy_from_slice(priv_params);
            let mut out = ciphertext.to_vec();
            let aes = aes::Aes128::new_from_slice(key).map_err(|_| UsmFailure {
                reason: "invalid AES key length".to_string(),
            })?;
            let mut cipher =
                cfb_mode::BufDecryptor::inner_iv_slice_init(aes, &iv).map_err(|_| UsmFailure {
                    reason: "invalid AES IV length".to_string(),
                })?;
            cipher.decrypt(&mut out);
            Ok(out)
        }
    }
}

/// Builds a fully-formed v3 message: scoped PDU optionally encrypted, USM
/// parameters filled, and the authentication digest computed over the final
/// encoding.
pub fn build_message(
    message_id: i32,
    user: &UsmUser,
    keys: &LocalizedKeys,
    engine: &EngineParams,
    scoped: ScopedPdu,
) -> Result<Vec<u8>> {
    let level = user.level()?;

    // 1. Privacy: encrypt the scoped PDU if the level requires it.
    let (scoped_data, priv_params) = match (level, &keys.priv_) {
        (SecurityLevel::AuthPriv, Some((proto, key))) => {
            let plaintext = rasn::der::encode(&scoped).map_err(|e| UsmFailure {
                reason: format!("could not encode the scoped PDU: {}", e),
            })?;
            let (ciphertext, params) = encrypt(*proto, key, engine, &plaintext)?;
            (
                ScopedPduData::EncryptedPdu(OctetString::from(ciphertext)),
                params,
            )
        }
        _ => (ScopedPduData::CleartextPdu(scoped), Vec::new()),
    };

    // 2. Authentication placeholder: zeroes of the exact digest length, so
    //    that patching the real digest in cannot change any DER length.
    let auth_placeholder = match &keys.auth {
        Some((proto, _)) if level != SecurityLevel::NoAuthNoPriv => vec![0u8; proto.tag_len()],
        _ => Vec::new(),
    };

    let security = USMSecurityParameters {
        authoritative_engine_id: OctetString::from(engine.id.clone()),
        authoritative_engine_boots: Integer::from(engine.boots),
        authoritative_engine_time: Integer::from(engine.time),
        user_name: OctetString::from(user.name.clone().into_bytes()),
        authentication_parameters: OctetString::from(auth_placeholder.clone()),
        privacy_parameters: OctetString::from(priv_params),
    };
    let security_bytes = rasn::der::encode(&security).map_err(|e| UsmFailure {
        reason: format!("could not encode the USM parameters: {}", e),
    })?;

    let message = Message {
        version: Integer::from(3),
        global_data: HeaderData {
            message_id: Integer::from(message_id),
            max_size: Integer::from(MAX_MESSAGE_SIZE),
            flags: OctetString::from(vec![flags_byte(level, true)]),
            security_model: Integer::from(SECURITY_MODEL_USM),
        },
        security_parameters: OctetString::from(security_bytes),
        scoped_data,
    };
    let encoded = rasn::der::encode(&message).map_err(|e| UsmFailure {
        reason: format!("could not encode the v3 message: {}", e),
    })?;

    // 3. HMAC over the whole message with a zeroed digest, patched back in.
    let Some((proto, key)) = &keys.auth else {
        return Ok(encoded);
    };
    if level == SecurityLevel::NoAuthNoPriv {
        return Ok(encoded);
    }
    let digest = proto.hmac(key, &encoded);
    let position = find_placeholder(&encoded, &auth_placeholder).ok_or_else(|| UsmFailure {
        reason: "could not locate the authentication placeholder in the encoded message"
            .to_string(),
    })?;
    let mut authenticated = encoded;
    authenticated[position..position + digest.len()].copy_from_slice(&digest);
    Ok(authenticated)
}

/// Locates the zeroed authentication placeholder in the encoded message.
///
/// The placeholder is preceded by its OCTET STRING header (`0x04 len`), which
/// makes the search specific enough: a run of N zero bytes with that exact
/// header cannot appear before the USM parameters, which are the only
/// zero-filled octet string of that length in a freshly built message.
fn find_placeholder(encoded: &[u8], placeholder: &[u8]) -> Option<usize> {
    if placeholder.is_empty() {
        return None;
    }
    let mut needle = Vec::with_capacity(placeholder.len() + 2);
    needle.push(0x04);
    needle.push(placeholder.len() as u8);
    needle.extend_from_slice(placeholder);
    encoded
        .windows(needle.len())
        .position(|window| window == needle)
        .map(|start| start + 2)
}

/// Human explanation of a `usmStats` counter (RFC 3414 §5), the OID an agent
/// returns in a Report when it refuses a request.
fn usm_stats_reason(oid: &str) -> Option<&'static str> {
    // Trailing arcs are the instance/count suffix; match the counter prefix.
    let counter = oid.trim_start_matches('.');
    let known = [
        ("1.3.6.1.6.3.15.1.1.1", "unsupported security level"),
        (
            "1.3.6.1.6.3.15.1.1.2",
            "message not in the agent's time window (clock drift or agent reboot)",
        ),
        ("1.3.6.1.6.3.15.1.1.3", "unknown user name"),
        ("1.3.6.1.6.3.15.1.1.4", "unknown engine ID"),
        (
            "1.3.6.1.6.3.15.1.1.5",
            "wrong authentication digest (check --authprotocol and --authpassphrase)",
        ),
        (
            "1.3.6.1.6.3.15.1.1.6",
            "decryption error (check --privprotocol and --privpassphrase)",
        ),
    ];
    known
        .iter()
        .find(|(prefix, _)| counter.starts_with(prefix))
        .map(|(_, reason)| *reason)
}

/// Turns a Report PDU into a diagnosable error.
fn report_error(pdu: &rasn_snmp::v2::Pdus) -> Option<crate::generic::error::Error> {
    let rasn_snmp::v2::Pdus::Report(report) = pdu else {
        return None;
    };
    let oid = report
        .0
        .variable_bindings
        .first()
        .map(|vb| vb.name.to_string())
        .unwrap_or_default();
    Some(UsmFailure {
        reason: match usm_stats_reason(&oid) {
            Some(reason) => format!("agent refused the request: {}", reason),
            None => format!("agent refused the request (usmStats counter {})", oid),
        },
    })
}

/// Verifies the authentication digest of a received message and returns the
/// decrypted scoped PDU.
pub fn open_message(raw: &[u8], message: &Message, keys: &LocalizedKeys) -> Result<ScopedPdu> {
    let security: USMSecurityParameters = message
        .decode_security_parameters(rasn::Codec::Ber)
        .map_err(|e| UsmFailure {
            reason: format!("could not decode the USM parameters of the response: {}", e),
        })?;

    // An agent that refuses our credentials answers with an UNAUTHENTICATED
    // Report (it cannot sign with a key it does not share): read it before
    // the digest check, it names the exact cause.
    if let ScopedPduData::CleartextPdu(pdu) = &message.scoped_data
        && let Some(error) = report_error(&pdu.data)
    {
        return Err(error);
    }

    // Authentication: recompute the digest over the message with the
    // received digest zeroed out, and compare in constant time.
    if let Some((proto, key)) = &keys.auth {
        let received = security.authentication_parameters.to_vec();
        if received.len() != proto.tag_len() {
            return Err(UsmFailure {
                reason: "response carries no or malformed authentication digest".to_string(),
            });
        }
        let position = find_digest(raw, &received).ok_or_else(|| UsmFailure {
            reason: "could not locate the authentication digest in the response".to_string(),
        })?;
        let mut zeroed = raw.to_vec();
        zeroed[position..position + received.len()].fill(0);
        let expected = proto.hmac(key, &zeroed);
        // Constant-time comparison: a timing oracle on a MAC check is the
        // classic way to forge one byte at a time.
        let mut diff = 0u8;
        for (a, b) in expected.iter().zip(received.iter()) {
            diff |= a ^ b;
        }
        if diff != 0 {
            return Err(UsmFailure {
                reason: "authentication digest mismatch (wrong credentials, or tampered response)"
                    .to_string(),
            });
        }
    }

    match &message.scoped_data {
        ScopedPduData::CleartextPdu(pdu) => Ok(pdu.clone()),
        ScopedPduData::EncryptedPdu(ciphertext) => {
            let Some((proto, key)) = &keys.priv_ else {
                return Err(UsmFailure {
                    reason: "the agent encrypted its response but no privacy key is configured"
                        .to_string(),
                });
            };
            let engine = EngineParams {
                id: security.authoritative_engine_id.to_vec(),
                boots: integer_to_u32(&security.authoritative_engine_boots),
                time: integer_to_u32(&security.authoritative_engine_time),
            };
            let plaintext = decrypt(
                *proto,
                key,
                &engine,
                &security.privacy_parameters,
                ciphertext,
            )?;
            rasn::ber::decode(&plaintext).map_err(|e| UsmFailure {
                reason: format!(
                    "could not decode the decrypted scoped PDU: {} (wrong privacy passphrase?)",
                    e
                ),
            })
        }
    }
}

/// Reads the engine parameters out of a received message.
pub fn engine_of(message: &Message) -> Result<EngineParams> {
    let security: USMSecurityParameters = message
        .decode_security_parameters(rasn::Codec::Ber)
        .map_err(|e| UsmFailure {
            reason: format!("could not decode the USM parameters of the response: {}", e),
        })?;
    Ok(EngineParams {
        id: security.authoritative_engine_id.to_vec(),
        boots: integer_to_u32(&security.authoritative_engine_boots),
        time: integer_to_u32(&security.authoritative_engine_time),
    })
}

/// Locates a received digest inside the raw message (same reasoning as
/// [`find_placeholder`], matching the actual digest bytes).
fn find_digest(raw: &[u8], digest: &[u8]) -> Option<usize> {
    let mut needle = Vec::with_capacity(digest.len() + 2);
    needle.push(0x04);
    needle.push(digest.len() as u8);
    needle.extend_from_slice(digest);
    raw.windows(needle.len())
        .position(|window| window == needle)
        .map(|start| start + 2)
}

/// Best-effort conversion of an ASN.1 integer to `u32` (engine counters are
/// bounded by 2^31-1 per RFC 3414).
fn integer_to_u32(value: &Integer) -> u32 {
    u32::try_from(value).unwrap_or(0)
}

/// Builds the discovery message (RFC 3414 §4): empty engine ID and user, no
/// authentication — the agent answers with a Report carrying its engine ID.
pub fn discovery_message(message_id: i32, scoped: ScopedPdu) -> Result<Vec<u8>> {
    let security = USMSecurityParameters {
        authoritative_engine_id: OctetString::from_static(b""),
        authoritative_engine_boots: Integer::from(0),
        authoritative_engine_time: Integer::from(0),
        user_name: OctetString::from_static(b""),
        authentication_parameters: OctetString::from_static(b""),
        privacy_parameters: OctetString::from_static(b""),
    };
    let security_bytes = rasn::der::encode(&security).map_err(|e| UsmFailure {
        reason: format!("could not encode the discovery USM parameters: {}", e),
    })?;
    let message = Message {
        version: Integer::from(3),
        global_data: HeaderData {
            message_id: Integer::from(message_id),
            max_size: Integer::from(MAX_MESSAGE_SIZE),
            flags: OctetString::from(vec![flags_byte(SecurityLevel::NoAuthNoPriv, true)]),
            security_model: Integer::from(SECURITY_MODEL_USM),
        },
        security_parameters: OctetString::from(security_bytes),
        scoped_data: ScopedPduData::CleartextPdu(scoped),
    };
    rasn::der::encode(&message).map_err(|e| UsmFailure {
        reason: format!("could not encode the discovery message: {}", e),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    /// RFC 3414 §A.3.1: password "maplesyrup", engine ID
    /// 00 00 00 00 00 00 00 00 00 00 00 02, MD5 → known localized key.
    #[test]
    fn md5_key_localization_matches_rfc3414_vector() {
        let engine_id = [0u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2];
        let key = localize_key(AuthProtocol::Md5, "maplesyrup", &engine_id);
        assert_eq!(
            key,
            vec![
                0x52, 0x6f, 0x5e, 0xed, 0x9f, 0xcc, 0xe2, 0x6f, 0x89, 0x64, 0xc2, 0x93, 0x07, 0x87,
                0xd8, 0x2b
            ]
        );
    }

    /// RFC 3414 §A.3.2: same inputs, SHA-1.
    #[test]
    fn sha1_key_localization_matches_rfc3414_vector() {
        let engine_id = [0u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2];
        let key = localize_key(AuthProtocol::Sha1, "maplesyrup", &engine_id);
        assert_eq!(
            key,
            vec![
                0x66, 0x95, 0xfe, 0xbc, 0x92, 0x88, 0xe3, 0x62, 0x82, 0x23, 0x5f, 0xc7, 0x15, 0x1f,
                0x12, 0x84, 0x97, 0xb3, 0x8f, 0x3f
            ]
        );
    }

    #[test]
    fn digest_lengths_follow_rfc7860() {
        assert_eq!(AuthProtocol::Md5.tag_len(), 12);
        assert_eq!(AuthProtocol::Sha1.tag_len(), 12);
        assert_eq!(AuthProtocol::Sha224.tag_len(), 16);
        assert_eq!(AuthProtocol::Sha256.tag_len(), 24);
        assert_eq!(AuthProtocol::Sha384.tag_len(), 32);
        assert_eq!(AuthProtocol::Sha512.tag_len(), 48);
    }

    #[test]
    fn protocol_names_are_parsed_like_the_perl_options() {
        assert_eq!(AuthProtocol::parse("sha").unwrap(), AuthProtocol::Sha1);
        assert_eq!(AuthProtocol::parse("SHA256").unwrap(), AuthProtocol::Sha256);
        assert!(AuthProtocol::parse("sha3").is_err());
        assert_eq!(PrivProtocol::parse("aes").unwrap(), PrivProtocol::Aes128);
        assert_eq!(PrivProtocol::parse("DES").unwrap(), PrivProtocol::Des);
        // AES-192/256 must fail loudly rather than interoperate wrongly.
        let err = PrivProtocol::parse("aes256").unwrap_err().to_string();
        assert!(err.contains("AES128"), "got: {}", err);
    }

    #[test]
    fn usm_stats_counters_are_translated_to_human_causes() {
        assert!(
            usm_stats_reason("1.3.6.1.6.3.15.1.1.5.0")
                .unwrap()
                .contains("authpassphrase")
        );
        assert!(
            usm_stats_reason("1.3.6.1.6.3.15.1.1.3.0")
                .unwrap()
                .contains("unknown user")
        );
        assert!(
            usm_stats_reason("1.3.6.1.6.3.15.1.1.2.0")
                .unwrap()
                .contains("time window")
        );
        assert_eq!(usm_stats_reason("1.3.6.1.2.1.1.1.0"), None);
    }

    #[test]
    fn privacy_without_authentication_is_rejected() {
        let user = UsmUser {
            name: "u".to_string(),
            auth: None,
            priv_: Some((PrivProtocol::Aes128, "pass".to_string())),
            context_name: String::new(),
            context_engine_id: None,
        };
        assert!(user.level().is_err());
    }

    #[test]
    fn security_level_follows_the_configured_credentials() {
        let none = UsmUser {
            name: "u".to_string(),
            auth: None,
            priv_: None,
            context_name: String::new(),
            context_engine_id: None,
        };
        assert_eq!(none.level().unwrap(), SecurityLevel::NoAuthNoPriv);
        let auth = UsmUser {
            name: "u".to_string(),
            auth: Some((AuthProtocol::Sha1, "authpass".to_string())),
            priv_: None,
            context_name: String::new(),
            context_engine_id: None,
        };
        assert_eq!(auth.level().unwrap(), SecurityLevel::AuthNoPriv);
        let both = UsmUser {
            name: "u".to_string(),
            auth: Some((AuthProtocol::Sha1, "authpass".to_string())),
            priv_: Some((PrivProtocol::Aes128, "privpass".to_string())),
            context_name: String::new(),
            context_engine_id: None,
        };
        assert_eq!(both.level().unwrap(), SecurityLevel::AuthPriv);
    }

    fn roundtrip(proto: PrivProtocol, key_len: usize) {
        let key: Vec<u8> = (0..key_len as u8).collect();
        let engine = EngineParams {
            id: vec![1, 2, 3],
            boots: 7,
            time: 1234,
        };
        // Length chosen NOT to be a multiple of 8, to exercise DES padding.
        let plaintext: Vec<u8> = (0..30u8).collect();
        let (ciphertext, params) = encrypt(proto, &key, &engine, &plaintext).expect("encrypt");
        assert_ne!(ciphertext, plaintext, "ciphertext must differ from input");
        let decrypted = decrypt(proto, &key, &engine, &params, &ciphertext).expect("decrypt");
        assert_eq!(
            &decrypted[..plaintext.len()],
            &plaintext[..],
            "roundtrip must restore the plaintext"
        );
    }

    #[test]
    fn des_encryption_roundtrips() {
        roundtrip(PrivProtocol::Des, 16);
    }

    #[test]
    fn aes128_encryption_roundtrips() {
        roundtrip(PrivProtocol::Aes128, 16);
    }

    #[test]
    fn salts_are_unique_across_messages() {
        let a = next_salt();
        let b = next_salt();
        assert_ne!(a, b, "each encrypted message needs a fresh salt");
    }

    #[test]
    fn placeholder_is_located_after_its_octet_string_header() {
        let placeholder = vec![0u8; 12];
        let mut encoded = vec![0x30, 0x20, 0x02, 0x01, 0x03];
        encoded.push(0x04);
        encoded.push(12);
        let position = encoded.len();
        encoded.extend_from_slice(&placeholder);
        encoded.extend_from_slice(&[0xAA, 0xBB]);
        assert_eq!(find_placeholder(&encoded, &placeholder), Some(position));
    }
}
