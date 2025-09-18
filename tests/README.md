# centreon-plugins Automated tests

## Robot tests

In this project robot Framework is used to order the integration tests.

### Docker

You can use the docker image in ./github/docker/testing/ to run the tests in a container depending on you OS of choice.
To build an image : 

```bash
docker  build -t plugin-bookworm -f Dockerfile.testing-plugins-bookworm .
```

To run it and run all tests in the tests/ folder, mounting the current folder to /centreon-plugins in the container : 

```bash
docker run -it --rm -v '$PWD:/centreon-plugins' plugin-bookworm
cd /centreon-plugins
```

### Snmpsim

This tool allows to simulate an snmp agent with predefined data.
It must be run manually before launching the tests.

to launch snmpsim use this from the root of the project (one level above this file) :
```bash
sudo snmpsim-command-responder --logging-method=null --agent-udpv4-endpoint=127.0.0.1:2024 --process-user=snmp --process-group=snmp --data-dir='./tests' &
# to test it :  snmpwalk -v2c -c hardware/server/lenovo/xcc/snmp/system-health-ok 127.0.0.1:2024
```

test should be run with the "robot" binary, indicating the path to the test file to run. 
robot consider every file with .robot extension and try to execute every test case in it. 

```bash
robot tests/ # add -v CENTREON_PLUGINS:/path/To/Plugin before the folder to use a specific plugin (for exemple a fatpacked one) instead of the one in the repo.
```
Available options to put before the path to tests/ :
- `-v CENTREON_PLUGINS`:/path/To/Plugin : to use a specific plugin (for exemple a fatpacked one) instead of the code from this repo.
- `-e notauto` : to exclude tests based on tag (for exemple if they need a specific hardware)
- `-i auto` : to include some test based on tag (please not that -i will exclude all tests without the specified tag)
- `--loglevel TRACE` : to get more info in the log.html file

### Centreon Connector

the centreon connector is used to launch the plugins and get the output without loading the plugin each time.
It's not enabled by default in production.
For robot tests, if the `CENTREON_PLUGINS` is left to default, the connector will not be used.
if `CENTREON_PLUGINS` is set, each tests suite will start the connector and use it to run plugins.

TODO : document a way to fatpack all plugins with nfpm and use them with .github/scripts/test-all-plugins.py as it is done in CI.

you can filter the tests run by specifying -e to exclude and -i to include a specific tag before the file path.

## Get new data

### Http

Any `curl -v` command should give enough info to create new tests/plugins on new http services.

If the plugin already exists, you can use the plugin to gater the data with the `--debug --verbose` options.

### Snmp

To get snmp data, you can use the snmpwalk command on the host you want to monitor. 
```bash
snmpwalk -ObentU -v2c -c 'public' localhost .1
```

## Anonymize tests

As most snmpwalk are provided by users, a script allow to anonymize the data and remove oid not used.
the option  `--no-anonymization` allow to not anonymize the data and only remove oid not used.

```bash
perl ./tests/scripts/slim_walk.pl --snmpwalk-path=tests/hardware/client.snmpwalk > smaller-file.snmpwalk
```

## unit tests

In this project perl test::v0 is used to run unit tests.

## test coverage
To check your test coverage you can use Deve::Cover
when launching any type of test, prepend this to your command : 

```bash
PERL5OPT=-MDevel::Cover
```

for exemple for robot : 

```bash
PERL5OPT=-MDevel::Cover robot tests/
```

It will create a cover_db/ folder to store all data, you can use the `cover` to generate a html report. 
```bash
cover
```

Then open the coverage.html file in the cover_db/ folder to navigate your code with coverage.
