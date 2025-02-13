# Prerequisites

To compile this project you have to install the Rust language. You can find
the installation instructions [here](https://www.rust-lang.org/tools/install).

Once done, you can compile it by running:

```bash
cargo build
```

# Description

## generic-snmp

To run the project, you can use the following command:

```bash
cargo run -- -H localhost -v 2c -c public -j test.json
```

## conn library

You have to install the Platypus library for Perl. You can do it by running:

```bash
cpanm FFI::Platypus::Lang::Rust
```

which installs the Perl bindings for Rust.

Then you have to compile the project (as described in the previous section).

Then, there is an example of Perl project using it in the perl directory you
can start with:

```
cd perl
./with-ffi.pl
```

# the generic-snmp program

This is the main program of this directory. It is a generic SNMP client that
can be used to query SNMP agents. Its goal is to be able to query any SNMP
agent, no matter the MIBs it supports, you just have to fill a JSON file and
it works.

Its API is work in progress, but you can already use it to query SNMP agents.

Here is an example of JSON file already supported:

```
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
```json

In this example, the output is built using several internal variables that are:
* status: the status of the query (OK, WARNING, CRITICAL, UNKNOWN)
* count: the number of variables returned by the query
* total_cpu_avg: here, it is the average of the CPU usage, but it is defined in the Agregation entry with the name label.

So you could also define others variables for the output.

In the query entry, there is also an `idx` variable that is an integer enumerating the entries og the query. It is used to build the name of the variable in the output. It starts from 0.
