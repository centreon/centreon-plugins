# centreon-plugins Automated tests

## Robot tests

In this project robot Framework is used to order the integration tests.

### install snmpsim

See docker image in ./github/docker/testing/ to find the right package to install and the method to install it.
Once snmpsim is installed, you need to create the snmp user : 

````bash
useradd snmp
mkdir -p /var/lib/snmp/cert_indexes/
chown snmp:snmp -R /var/lib/snmp/cert_indexes/
````

### Run all tests

Mockoon is used to mock http services. It is started by robot automatically if needed.

Snmpsim have to be started by hand, you can use this command from the root of the project (one level above this file) :

```bash
sudo snmpsim-command-responder --logging-method=null --agent-udpv4-endpoint=127.0.0.1:2024 --process-user=snmp --process-group=snmp --data-dir='./tests' &
# to test it :  snmpwalk -v2c -c hardware/server/lenovo/xcc/snmp/system-health-ok 127.0.0.1:2024
```

test should be run with the "robot" binary, indicating the path to the test file to run. 
robot consider every file with .robot extension and try to execute every test case in it. 

```bash
robot tests/
```

you can filter the tests run by specifying -e to exclude and -i to include a specific tag before the file path, or change the path to sub directories or specific files.

### perl connector

By default, plugins are run as a perl script with the centreon_plugins.pl script. If you have fatpacked the plugins
you can use the option `CENTREON_PLUGINS:/path/to/your/fatpacked.pl` to run the fatpacked version of the plugins.
The fatpacked version will be run with the perl connector instead of being run as a perl script.

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
