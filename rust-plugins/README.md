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

# Description

## generic-snmp

To run the project, you can use the following command:

```bash
cargo run -- -H localhost -v 2c -c public -j test.json
```

# the generic-snmp program

This is the main program of this directory. It is a generic SNMP client that
can be used to query SNMP agents. Its goal is to be able to query any SNMP
agent, no matter the MIBs it supports, you just have to fill a JSON file and
it works.

Its API is work in progress, but you can already use it to query SNMP agents.

Here is an example of JSON file already supported:

```json
{
  "leaf": {
    "name": "cpu",
    "output": "{status}: {count} CPU(s) average usage is {total_cpu_avg} %",
    "entries": [
      { "Query": { "name": "cpu_{idx}", "oid": "1.3.6.1.2.1.25.3.3.1.2", "query": "Walk" }},
      { "Agregation": { "name": "total_cpu_avg", "op": "Average"}}
    ]
  }
}
```

In this example, the output is built using several internal variables that are:
* status: the status of the query (OK, WARNING, CRITICAL, UNKNOWN)
* count: the number of variables returned by the query
* total_cpu_avg: here, it is the average of the CPU usage, but it is defined in the Agregation entry with the name label.

So you could also define others variables for the output.

In the query entry, there is also an `idx` variable that is an integer enumerating the entries og the query. It is used to build the name of the variable in the output. It starts from 0.

# Development — quality gate

Before opening a pull request touching `rust-plugins/`, run:

```bash
./scripts/check.sh
```

It matches what the `lint` and `build` jobs of `.github/workflows/generic-plugins.yml`
enforce in CI (`cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`,
`cargo test`), plus a stricter local-only check: a scan proving that no
`panic!`/`unwrap()` is reachable outside `#[cfg(test)]` modules — a panic
reachable from untrusted input (a malformed JSON definition, a malicious SNMP
response) turns a reportable `UNKNOWN` into a plugin crash.

The toolchain is pinned by `rust-toolchain.toml` so everyone lints with the
same rustc/clippy/rustfmt versions.

If you use the repository's git hooks (`git config core.hooksPath .githooks`),
the gate also runs automatically on commit whenever a staged file is under
`rust-plugins/` (see `.githooks/pre-commit.d/25_rust_plugins.sh`).
