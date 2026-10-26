# centreon-plugin-rust-snmp
 
`centreon-plugin-rust-snmp` is a generic SNMP plugin written in Rust. It is currently in **beta**.
 
The binary itself contains no monitoring logic for a given device. It reads a JSON file, called a
**collection**, which describes what to query, how to compute metrics and statuses, and how to
format the output. Adding or changing a check therefore means editing a collection: no
compilation is needed for that. Compiling is only needed to work on the engine itself.
 
User documentation:
 
- [Rust collections (how-to guide)](https://docs.centreon.com/pp/integrations/plugin-packs/getting-started/how-to-guides/rust-collections/)
- [Generic SNMP (Rust) connector](https://docs.centreon.com/pp/integrations/plugin-packs/procedures/applications-protocol-snmp-rs/)
# Prerequisites
 
To compile this project you have to install the Rust language. You can find
the installation instructions [here](https://www.rust-lang.org/tools/install).
 
Once done, you can compile it by running:
 
```bash
cargo build
```
 
# Static linking
 
`cargo build` links the binary against the glibc of your own machine. The packaged binary has to
run on every supported distribution, the oldest one being el8 with glibc 2.28 as of 2026, and glibc offers
no forward compatibility: a binary built against a recent glibc fails to start on an older one.
The CI therefore links statically against musl instead:
 
```bash
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
```
 
Use that command to reproduce a release binary locally. The CI fails the build if the produced
binary still carries a dynamic dependency.
 
A statically linked musl binary does not use the glibc Name Service Switch (NSS). Host names are
resolved by the musl resolver, which reads `/etc/hosts` and `/etc/resolv.conf` only, so the
`nsswitch.conf` backends such as sssd, LDAP or mDNS are ignored, unlike with the Perl plugins.
Targets given as IP addresses are unaffected, and so are host names resolvable through plain DNS.
 
# Running the plugin
 
From the sources:
 
```bash
cargo run -- -H localhost -v 2c -c public \
    --json rs-collections/applications-protocol-snmp/uptime.json
```
 
Once packaged, the binary is installed in `/usr/lib/centreon/plugins/` and the collections are
shipped by dedicated packages (for example `centreon-plugin-applications-protocol-snmp-rs`) into
`/usr/lib/centreon/plugins/rs-collections/<pack>/`:
 
```bash
/usr/lib/centreon/plugins/centreon-plugin-rust-snmp -H 10.0.0.1 -v 2c -c my-snmp-community \
    --json /usr/lib/centreon/plugins/rs-collections/applications-protocol-snmp/uptime.json
```
 
Useful options when writing or debugging a collection:
 
- `--check-format`: check the validity of the JSON file and exit
- `--check-response`: display the raw SNMP response
- `--list-counters`: list all available metrics
- `--help`: list all options
# Collections
 
The collections maintained by Centreon are in the [`rs-collections/`](rs-collections/) directory,
one subdirectory per pack.
 
The format is specified as a JSON schema:
`https://centreon.github.io/centreon-plugins/rs-collections/snmp/v0/rs-collection.schema.json`.
Referencing it in the `$schema` field enables completion and validation in most editors.
The full description of the format is in the
[how-to guide](https://docs.centreon.com/pp/integrations/plugin-packs/getting-started/how-to-guides/rust-collections/).
 
A collection describes three stages, run in this order:
 
1. `collect`: the SNMP queries sent to the device
2. `compute`: the metrics and aggregations computed from the collected values
3. `output`: how the result is displayed for each status
Example, `rs-collections/applications-protocol-snmp/uptime.json`:
 
```json
{
  "$schema": "https://centreon.github.io/centreon-plugins/rs-collections/snmp/v0/rs-collection.schema.json",
  "format_version": 0,
  "collect": {
    "snmp": [
      {
        "name": "hrSystemUptime",
        "oid": ".1.3.6.1.2.1.25.1.1.0",
        "query": "Get"
      }
    ]
  },
  "compute": {
    "metrics": [],
    "aggregations": [
      {
        "name": "system.uptime.seconds",
        "value": "{hrSystemUptime} / 100",
        "uom": "s",
        "min": 0,
        "threshold-suffix": "seconds"
      }
    ]
  },
  "output": {
    "ok": "OK: Uptime: {aggregations.system.uptime.seconds}s",
    "warning": "WARNING: ",
    "detail_warning": true,
    "critical": "CRITICAL: ",
    "detail_critical": true
  }
}
```
 
The `threshold-suffix` field defines the threshold options of the metric: here,
`--warning-seconds` and `--critical-seconds`.
 
For a table (`"query": "Walk"`) with one metric per instance and an aggregation over all
instances, see `rs-collections/applications-protocol-snmp/cpu.json`.
