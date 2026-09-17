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

//! Persistent state between two plugin executions, for delta/rate metrics.
//!
//! SNMP counters (`ifInOctets`, ...) are monotonically increasing values:
//! turning them into rates (B/s, packets/s) requires the value and timestamp
//! of the previous run. This module stores one small JSON snapshot per
//! collect entry, keyed by target + entry name + OID.
//!
//! Security posture (lesson from the Perl audit, S5): state files are
//! created with mode `0600` and written atomically (temp file + rename) —
//! never world-readable, never half-written.

use crate::generic::error::Error::StatefileWrite;
use crate::generic::error::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tracing::{debug_span, warn};

/// Largest value a 32-bit SNMP counter can hold.
const U32_COUNTER_MAX: f64 = 4_294_967_295.0;

/// One persisted collection snapshot: the values of a collect entry,
/// keyed by full OID, plus the collection timestamp.
#[derive(Debug, Serialize, Deserialize, PartialEq)]
pub struct Snapshot {
    /// Unix epoch of the collection, in seconds.
    pub timestamp: f64,
    /// Collected numeric values, keyed by full OID (stable identity of an
    /// instance across runs — positions in a table are not).
    pub values: HashMap<String, f64>,
}

/// Reads and writes [`Snapshot`]s under a state directory.
pub struct StateStore {
    dir: PathBuf,
}

impl StateStore {
    /// Creates a store rooted at `dir` (mirror of the Perl
    /// `--statefile-dir`, default `/var/lib/centreon/centplugins`).
    pub fn new(dir: &Path) -> StateStore {
        StateStore {
            dir: dir.to_path_buf(),
        }
    }

    /// Builds the state key for a collect entry: same target + same entry
    /// name + same base OID share the same state, which is the intended
    /// behavior for a check re-executed by the poller.
    pub fn rate_key(target: &str, entry_name: &str, oid: &str) -> String {
        let raw = format!("rust-snmp_{}_{}_{}", target, entry_name, oid);
        raw.chars()
            .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
            .collect()
    }

    fn path_for(&self, key: &str) -> PathBuf {
        self.dir.join(format!("{}.json", key))
    }

    /// Loads the previous snapshot for `key`.
    ///
    /// Read problems are never fatal: a missing, unreadable or corrupt file
    /// is treated as "no previous run" (the plugin then rebuilds its buffer)
    /// — a poller must not go UNKNOWN because a cache file was damaged.
    pub fn load(&self, key: &str) -> Option<Snapshot> {
        let _span = debug_span!("state_read", key).entered();
        let path = self.path_for(key);
        let content = match std::fs::read_to_string(&path) {
            Ok(content) => content,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return None,
            Err(e) => {
                warn!(
                    "unreadable state file {:?} ({}), rebuilding buffer",
                    path, e
                );
                return None;
            }
        };
        match serde_json::from_str(&content) {
            Ok(snapshot) => Some(snapshot),
            Err(e) => {
                warn!("corrupt state file {:?} ({}), rebuilding buffer", path, e);
                None
            }
        }
    }

    /// Persists `snapshot` under `key`, atomically and in mode `0600`.
    ///
    /// A write failure IS fatal: without a persisted reference the next run
    /// would compute rates against a stale base — better a clean UNKNOWN
    /// now than silently wrong values forever.
    pub fn save(&self, key: &str, snapshot: &Snapshot) -> Result<()> {
        let _span = debug_span!("state_write", key).entered();
        let path = self.path_for(key);
        let write = || -> std::io::Result<()> {
            std::fs::create_dir_all(&self.dir)?;
            let tmp = self.dir.join(format!("{}.tmp.{}", key, std::process::id()));
            {
                use std::io::Write;
                let mut options = std::fs::OpenOptions::new();
                options.write(true).create(true).truncate(true);
                #[cfg(unix)]
                {
                    use std::os::unix::fs::OpenOptionsExt;
                    // Never world-readable: state may carry data an operator
                    // considers sensitive (audit S5).
                    options.mode(0o600);
                }
                let mut file = options.open(&tmp)?;
                file.write_all(
                    serde_json::to_string(snapshot)
                        .expect("Snapshot serialization cannot fail")
                        .as_bytes(),
                )?;
                file.sync_all()?;
            }
            // Atomic replacement: a concurrent reader sees either the old or
            // the new snapshot, never a truncated file.
            std::fs::rename(&tmp, &path)
        };
        write().map_err(|e| StatefileWrite {
            path: path.display().to_string(),
            reason: e.to_string(),
        })
    }
}

/// Converts a counter pair into a per-second rate.
///
/// * `dt <= 0` → `None` (two collections at the same instant, or clock gone
///   backwards: no meaningful rate).
/// * decreasing value → 32-bit wraparound correction when the previous value
///   still fit in 32 bits; otherwise the counter was reset (agent reboot)
///   and `None` is returned. Note the classic blind spot, shared with the
///   Perl implementation: a *reset* of a 32-bit counter is indistinguishable
///   from a wrap and produces one over-estimated sample.
pub fn compute_rate(old: f64, new: f64, dt: f64) -> Option<f64> {
    if dt <= 0.0 {
        return None;
    }
    let mut delta = new - old;
    if delta < 0.0 {
        if old <= U32_COUNTER_MAX {
            delta += U32_COUNTER_MAX + 1.0;
        }
        if delta < 0.0 {
            return None;
        }
    }
    Some(delta / dt)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rate_of_a_normal_increase() {
        assert_eq!(compute_rate(1000.0, 1600.0, 60.0), Some(10.0));
    }

    #[test]
    fn rate_needs_a_positive_time_delta() {
        assert_eq!(compute_rate(1000.0, 1600.0, 0.0), None);
        assert_eq!(compute_rate(1000.0, 1600.0, -5.0), None);
    }

    #[test]
    fn rate_corrects_a_32bit_wraparound() {
        // old close to 2^32, new wrapped to a small value.
        let old = 4_294_967_290.0;
        let new = 10.0;
        // delta = 10 - 4294967290 + 4294967296 = 16
        assert_eq!(compute_rate(old, new, 4.0), Some(4.0));
    }

    #[test]
    fn rate_treats_a_64bit_decrease_as_a_reset() {
        // old beyond 32 bits: a decrease cannot be a 32-bit wrap.
        let old = 10_000_000_000.0;
        assert_eq!(compute_rate(old, 5.0, 60.0), None);
    }

    #[test]
    fn state_roundtrip_is_atomic_and_private() {
        let dir = std::env::temp_dir().join(format!("state-test-{}", std::process::id()));
        let store = StateStore::new(&dir);
        let key = StateStore::rate_key("127.0.0.1:161", "if", "1.3.6.1.2.1.2.2.1");
        assert!(
            key.chars().all(|c| c.is_ascii_alphanumeric() || c == '_'),
            "key must be filesystem-safe: {}",
            key
        );

        assert!(store.load(&key).is_none(), "no state on first run");

        let snapshot = Snapshot {
            timestamp: 1000.0,
            values: HashMap::from([("1.3.6.1.2.1.2.2.1.10.1".to_string(), 42.0)]),
        };
        store.save(&key, &snapshot).expect("save should succeed");
        assert_eq!(store.load(&key), Some(snapshot));

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = std::fs::metadata(dir.join(format!("{}.json", key)))
                .expect("state file exists")
                .permissions()
                .mode();
            assert_eq!(mode & 0o777, 0o600, "state file must be private (0600)");
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn corrupt_state_is_a_fresh_start_not_a_crash() {
        let dir = std::env::temp_dir().join(format!("state-corrupt-{}", std::process::id()));
        std::fs::create_dir_all(&dir).expect("mkdir");
        std::fs::write(dir.join("k.json"), b"{ not json").expect("write");
        let store = StateStore::new(&dir);
        assert!(store.load("k").is_none());
        let _ = std::fs::remove_dir_all(&dir);
    }
}
