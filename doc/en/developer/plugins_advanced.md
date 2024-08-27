# Plugins / Connectors advenced documentation

## IV. List of shared libraries in centreon directory

This chapter describes Centreon libraries which you can use in your development.

<div id='table_of_contents'/>

*******
Table of contents
1. [Output](#lib_output)
2. [Perfdata](#lib_perfdata)
3. [SNMP](#lib_snmp)
4. [Misc](#lib_misc)
5. [Statefile](#lib_statefile)
6. [HTTP](#lib_http)
7. [DBI](#lib_dbi)
8. [Model Classes Usage](#model_class_usage)
*******

<div id='lib_output'/>

### 1. Output

This library allows you to build output of your plugin.

#### 1.1 output_add

**Description**

This function adds a string to the output (it is printed when the `display()` method is called). If the status is different from 'ok', the output associated with 'ok' status is not printed.

**Parameters**

| Parameter | Type   | Default | Description                                 |
|-----------|--------|---------|---------------------------------------------|
| severity  | String | OK      | Status of the output. Accepted values: OK, WARNING, CRITICAL, UNKNOWN.                      |
| separator | String | \-      | Separator between status and output string. |
| short_msg | String |         | Short output (first line).                  |
| long_msg  | String |         | Long output (used with --verbose option).   |
| debug     | Int    |         | If set to 1, the message is displayed only when --debug option is passed  |

**Example**

This is an example of how to manage output:

```perl
$self->{output}->output_add(severity  => 'OK',
                            short_msg => 'All is ok');
$self->{output}->output_add(severity  => 'Critical',
                            short_msg => 'There is a critical problem');
$self->{output}->output_add(long_msg  => 'Port 1 is disconnected');

$self->{output}->display();
```

The displayed output is:

```
CRITICAL - There is a critical problem
Port 1 is disconnected
```

#### 1.2 perfdata_add

**Description**

Add performance data to output (print it with **display** method).
Performance data are displayed after '|'.

**Parameters**

| Parameter | Type   | Default | Description                            |
|-----------|--------|---------|----------------------------------------|
| label     | String |         | [legacy] Label of the performance data.         |
| nlabel     | String |         | Label of the performance data in a more standard and explicit fashion.         |
| value     | Int    |         | Value of the performance data.         |
| unit      | String |         | Unit of the performance data.          |
| warning   | String |         | Warning threshold.                     |
| critical  | String |         | Critical threshold.                    |
| min       | Int    |         | Minimum value of the performance data. |
| max       | Int    |         | Maximum value of the performance data. |

**Example**

This is an example of how to add performance data:

```perl

$self->{output}->output_add(severity  => 'OK',
                            short_msg => 'Memory is ok');
$self->{output}->perfdata_add(label    => 'memory_used',
                              value    => 30000000,
                              unit     => 'B',
                              warning  => '80000000',
                              critical => '90000000',
                              min      => 0,
                              max      => 100000000);

$self->{output}->display();
```
Output displays :

```
OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000
```

<div id='lib_perfdata'/>

### 2. Perfdata

This library allows you to manage performance data.

#### 2.1 get_perfdata_for_output

**Description**
Manage thresholds of performance data for output.

**Parameters**

| Parameter | Type         | Default | Description                                               |
|-----------|--------------|---------|-----------------------------------------------------------|
| **label** | String       |         | Threshold label.                                          |
| total     | Int          |         | Percent threshold to transform in global.                 |
| cast_int  | Int (0 or 1) |         | Cast absolute to int.                                     |
| op        | String       |         | Operator to apply to start/end value (uses with 'value'). |
| value     | Int          |         | Value to apply with 'op' option.                          |

**Example**

This is an example of how to manage performance data for output:

```perl
my $format_warning_perfdata  = $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => 1000000000, cast_int => 1);
my $format_critical_perfdata = $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => 1000000000, cast_int => 1);

$self->{output}->perfdata_add(label    => 'memory_used',
                              value    => 30000000,
                              unit     => 'B',
                              warning  => $format_warning_perfdata,
                              critical => $format_critical_perfdata,
                              min      => 0,
                              max      => 1000000000);

```

**tip**
In this example, instead of print warning and critical thresholds in 'percent', the function calculates and prints these in 'bytes'.

#### 2.2 threshold_validate

**Description**

Validate and affect threshold to a label.

**Parameters**

| Parameter | Type   | Default | Description      |
|-----------|--------|---------|------------------|
| label     | String |         | Threshold label. |
| value     | String |         | Threshold value. |

**Example**

This example checks if warning threshold is correct:

```perl

if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
  $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
  $self->{output}->option_exit();
}
```

**tip**
You can see the correct threshold format here: https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

#### 2.3 threshold_check

**Description**

Compare performance data value with threshold to determine status.

**Parameters**

| Parameter | Type         | Default | Description                                            |
|-----------|--------------|---------|--------------------------------------------------------|
| value     | Int          |         | Performance data value to compare.                     |
| threshold | String array |         | Threshold label to compare and exit status if reached. |

**Example**

This example checks if performance data reached thresholds:

```perl
$self->{perfdata}->threshold_validate(label => 'warning', value => 80);
$self->{perfdata}->threshold_validate(label => 'critical', value => 90);
my $prct_used = 85;

my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

$self->{output}->output_add(severity  => $exit,
                            short_msg => sprint("Used memory is %i%%", $prct_used));
$self->{output}->display();
```
Output displays :

```
  WARNING - Used memory is 85% |
```

#### 2.4 change_bytes

**Description**

Convert bytes to human readable unit.
Return value and unit.

**Parameters**

| Parameter | Type | Default | Description                        |
|-----------|------|---------|------------------------------------|
| value     | Int  |         | Performance data value to convert. |
| network   |      | 1024    | Unit to divide (1000 if defined).  |

**Example**

This example change bytes to human readable unit:

```perl

my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

print $value.' '.$unit."\n";
```
Output displays :

```
  100 KB
```

<div id='lib_snmp'/>

### 3. SNMP

This library allows you to use SNMP protocol in your plugin.
To use it, add the following line at the beginning of your **plugin.pm**:

```perl
use base qw(centreon::plugins::script_snmp);
```

#### 3.1 get_leef

**Description**

Return hash table of SNMP values for multiple OIDs (do not work with SNMP table).

**Parameters**

**Example**

This is an example of how to get 2 SNMP values:

```perl

my $oid_hrSystemUptime = '.1.3.6.1.2.1.25.1.1.0';
my $oid_sysUpTime = '.1.3.6.1.2.1.1.3.0';

my $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemUptime, $oid_sysUpTime ], nothing_quit => 1);

print $result->{$oid_hrSystemUptime}."\n";
print $result->{$oid_sysUpTime}."\n";
```

#### 3.2 load

**Description**

Load a range of OIDs to use with **get_leef** method.

**Parameters**

| Parameter       | Type         | Default | Description                                                    |
|-----------------|--------------|---------|----------------------------------------------------------------|
| **oids**        | String array |         | Array of OIDs to check.                                        |
| instances       | Int array    |         | Array of OID instances to check.                               |
| instance_regexp | String       |         | Regular expression to get instances from **instances** option. |
| begin           | Int          |         | Instance to begin                                              |
| end             | Int          |         | Instance to end                                                |

**Example**

This is an example of how to get 4 instances of a SNMP table by using **load** method:

```perl
my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

$self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

my $result = $self->{snmp}->get_leef(nothing_quit => 1);

use Data::Dumper;
print Dumper($result);
```
This is an example of how to get multiple instances dynamically (memory modules of Dell hardware) by using **load** method:

```perl
my $oid_memoryDeviceStatus = '.1.3.6.1.4.1.674.10892.1.1100.50.1.5';
my $oid_memoryDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.1100.50.1.8';
my $oid_memoryDeviceSize = '.1.3.6.1.4.1.674.10892.1.1100.50.1.14';
my $oid_memoryDeviceFailureModes = '.1.3.6.1.4.1.674.10892.1.1100.50.1.20';

my $result = $self->{snmp}->get_table(oid => $oid_memoryDeviceStatus);
$self->{snmp}->load(oids => [$oid_memoryDeviceLocationName, $oid_memoryDeviceSize, $oid_memoryDeviceFailureModes],
                    instances => [keys %$result],
                    instance_regexp => '(\d+\.\d+)$');

my $result2 = $self->{snmp}->get_leef();

use Data::Dumper;
print Dumper($result2);
```

#### 3.3 get_table

**Description**

Return hash table of SNMP values for SNMP table.

**Parameters**

| Parameter    | Type         | Default | Description                                             |
|--------------|--------------|---------|---------------------------------------------------------|
| **oid**      | String       |         | OID of the snmp table to check.                         |
| start        | Int          |         | First OID to check.                                     |
| end          | Int          |         | Last OID to check.                                      |
| dont_quit    | Int (0 or 1) | 0       | Don't quit even if an SNMP error occured.               |
| nothing_quit | Int (0 or 1) | 0       | Quit if no value is returned.                           |
| return_type  | Int (0 or 1) | 0       | Return a hash table with one level instead of multiple. |

**Example**

This is an example of how to get a SNMP table:

```perl
my $oid_rcDeviceError            = '.1.3.6.1.4.1.15004.4.2.1';
my $oid_rcDeviceErrWatchdogReset = '.1.3.6.1.4.1.15004.4.2.1.2.0';

my $results = $self->{snmp}->get_table(oid => $oid_rcDeviceError, start => $oid_rcDeviceErrWatchdogReset);

use Data::Dumper;
print Dumper($results);
```

#### 3.4 get_multiple_table

**Description**

Return hash table of SNMP values for multiple SNMP tables.

**Parameters**

| Parameter    | Type         | Default | Description                                                |
|--------------|--------------|---------|------------------------------------------------------------|
| oids         | Hash table   | -       | Hash table of OIDs to check (Can be set by 'load' method). |
| -            | -            | -       | Keys can be: "oid", "start", "end".                        |
| dont_quit    | Int (0 or 1) | 0       | Don't quit even if an SNMP error occured.                  |
| nothing_quit | Int (0 or 1) | 0       | Quit if no value is returned.                              |
| return_type  | Int (0 or 1) | 0       | Return a hash table with one level instead of multiple.    |      

**Example**

This is an example of how to get 2 SNMP tables:

```perl
my $oid_sysDescr        = ".1.3.6.1.2.1.1.1";
my $aix_swap_pool       = ".1.3.6.1.4.1.2.6.191.2.4.2.1";

my $results = $self->{snmp}->get_multiple_table(oids => [
                                                      { oid => $aix_swap_pool},
                                                      { oid => $oid_sysDescr },
                                                ]);

use Data::Dumper;
print Dumper($results);
```

#### 3.5 get_hostname

**Description**

Get hostname parameter (useful to get hostname in mode).

**Parameters**

None.

**Example**

This is an example of how to get hostname parameter:

```perl
my $hostname = $self->{snmp}->get_hostname();
```

#### 3.6 get_port

**Description**


Get port parameter (useful to get port in mode).

**Parameters**

None.

**Example**

This is an example of how to get port parameter:

```perl
my $port = $self->{snmp}->get_port();
```

#### 3.7 oid_lex_sort

**Description**

Return sorted OIDs.

**Parameters**

| Parameter | Type         | Default | Description            |
|-----------|--------------|---------|------------------------|
| **-**     | String array |         | Array of OIDs to sort. |

**Example**

This example prints sorted OIDs:

```perl
foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
  print $oid;
}
```

<div id='lib_misc'/>

### 4. Misc

This library provides a set of miscellaneous methods.
To use it, you can directly use the path of the method:

```perl
centreon::plugins::misc::<my_method>;
```
--------------
#### 4.1 trim

**Description**

Strip whitespace from the beginning and end of a string.

**Parameters**

| Parameter | Type   | Default | Description      |
|-----------|--------|---------|------------------|
| **-**     | String |         | String to strip. |

**Example**

This is an example of how to use **trim** method:

```perl
my $word = '  Hello world !  ';
my $trim_word =  centreon::plugins::misc::trim($word);

print $word."\n";
print $trim_word."\n";
```
Output displays :

```
Hello world !
```

#### 4.2 change_seconds

**Description**

Convert seconds to human readable text.

**Parameters**

| Parameter | Type | Default | Description                   |
|-----------|------|---------|-------------------------------|
| **-**     | Int  |         | Number of seconds to convert. |

**Example**

This is an example of how to use **change_seconds** method:

```perl
my $seconds = 3750;
my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

print 'Human readable time : '.$human_readable_time."\n";
```
Output displays :

```
Human readable time : 1h 2m 30s
```

#### 4.3 backtick

**Description**

Execute system command.

**Parameters**

| Parameter       | Type         | Default | Description                             |
|-----------------|--------------|---------|-----------------------------------------|
| **command**     | String       |         | Command to execute.                     |
| arguments       | String array |         | Command arguments.                      |
| timeout         | Int          | 30      | Command timeout.                        |
| wait_exit       | Int (0 or 1) | 0       | Command process ignore SIGCHLD signals. |
| redirect_stderr | Int (0 or 1) | 0       | Print errors in output.                 |

**Example**

This is an example of how to use **backtick** method:

```perl
my ($error, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                    command => 'ls /home',
                                    timeout => 5,
                                    wait_exit => 1
                                    );

print $stdout."\n";
```
Output displays files in '/home' directory.


#### 4.4 execute

**Description**

Execute command remotely.

**Parameters**

| Parameter       | Type   | Default | Description                                                     |
|-----------------|--------|---------|-----------------------------------------------------------------|
| **output**      | Object |         | Plugin output ($self->{output}).                                |
| **options**     | Object |         | Plugin options ($self->{option_results}) to get remote options. |
| sudo            | String |         | Use sudo command.                                               |
| **command**     | String |         | Command to execute.                                             |
| command_path    | String |         | Command path.                                                   |
| command_options | String |         | Command arguments.                                              |

**Example**

This is an example of how to use **execute** method.
We suppose ``--remote`` option is enabled:

```perl
my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                              options => $self->{option_results},
                                              sudo => 1,
                                              command => 'ls /home',
                                              command_path => '/bin/',
                                              command_options => '-l');
```
Output displays files in /home using ssh on a remote host.

#### 4.5 windows_execute

**Description**

Execute command on Windows.

**Parameters**

| Parameter       | Type   | Default | Description                          |
|-----------------|--------|---------|--------------------------------------|
| **output**      | Object |         | Plugin output ($self->{output}).     |
| **command**     | String |         | Command to execute.                  |
| command_path    | String |         | Command path.                        |
| command_options | String |         | Command arguments.                   |
| timeout         | Int    |         | Command timeout.                     |
| no_quit         | Int    |         | Don't quit even if an error occured. |

**Example**

This is an example of how to use **windows_execute** method.

```perl
my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                      timeout => 10,
                                                      command => 'ipconfig',
                                                      command_path => '',
                                                      command_options => '/all');
```
Output displays IP configuration on a Windows host.

<div id='lib_statefile'/>

### 5.Statefile

This library provides a set of methods to use a cache file.
To use it, add the following line at the beginning of your **mode**:

```perl
use centreon::plugins::statefile;
```

#### 5.1 read

**Description**

Read cache file.

**Parameters**

| Parameter         | Type   | Default | Description                  |
|-------------------|--------|---------|------------------------------|
| **statefile**     | String |         | Name of the cache file.      |
| **statefile_dir** | String |         | Directory of the cache file. |
| memcached         | String |         | Memcached server to use.     |

**Example**

This is an example of how to use **read** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

use Data::Dumper;
print Dumper($self->{statefile_value});
```
Output displays cache file and its parameters.

#### 5.2 get

**Description**

Get data from cache file.

**Parameters**

| Parameter | Type   | Default | Description                  |
|-----------|--------|---------|------------------------------|
| name      | String |         | Get a value from cache file. |

**Example**

This is an example of how to use **get** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

my $value = $self->{statefile_value}->get(name => 'property1');
print $value."\n";
```
Output displays value for 'property1' of the cache file.

#### 5.3 write

**Description**

Write data to cache file.

**Parameters**

| Parameter | Type   | Default | Description                  |
|-----------|--------|---------|------------------------------|
| data      | String |         | Data to write in cache file. |

**Example**

This is an example of how to use **write** method:

```perl
$self->{statefile_value} = centreon::plugins::statefile->new(%options);
$self->{statefile_value}->check_options(%options);
$self->{statefile_value}->read(statefile => 'my_cache_file',
                               statefile_dir => '/var/lib/centreon/centplugins'
                              );

my $new_datas = {};
$new_datas->{last_timestamp} = time();
$self->{statefile_value}->write(data => $new_datas);
```
Then, you can read the result in '/var/lib/centreon/centplugins/my_cache_file', timestamp is written in it.

<div id='lib_http'/>

### 6. HTTP

This library provides a set of methodss to use HTTP protocol.
To use it, add the following line at the beginning of your **mode**:

```perl
use centreon::plugins::http;
```

Some options must be set in **plugin.pm**:

| Option       | Type   | Description                                             |
|--------------|--------|---------------------------------------------------------|
| **hostname** | String | IP Addr/FQDN of the webserver host.                     |
| **port**     | String | HTTP port.                                              |
| **proto**    | String | Used protocol ('http' or 'https').                      |
| credentials  |        | Use credentials.                                        |
| ntlm         |        | Use NTLM authentication (if ``--credentials`` is used). |
| username     | String | Username (if ``--credentials`` is used).                |
| password     | String | User password (if ``--credentials`` is used).           |
| proxyurl     | String | Proxy to use.                                           |
| url_path     | String | URL to connect (start to '/').                          |

#### 6.1 connect

**Description**

Test a connection to an HTTP url.
Return content of the webpage.

**Parameters**

This method use plugin options previously defined.

**Example**

This is an example of how to use **connect** method.

We suppose these options are defined :
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

```perl
$self->{http} = centreon::plugins::http->new(output => $self->{output}, options => $self->{options});
$self->{http}->set_options(%{$self->{option_results}});
my $webcontent = $self->{http}->request();
print $webcontent;
```
Output displays content of the webpage '\http://google.com/'.

<div id='lib_dbi'/>

### 7. DBI

This library allows you to connect to databases.
To use it, add the following line at the beginning of your **plugin.pm**:

```perl
use base qw(centreon::plugins::script_sql);
```

#### 7.1 connect

**Description**

Connect to databases.

**Parameters**

| Parameter | Type         | Default | Description                        |
|-----------|--------------|---------|------------------------------------|
| dontquit  | Int (0 or 1) | 0       | Don't quit even if errors occured. |

**Example**

This is an example of how to use **connect** method.

The format of the connection string can have the following forms:

```
    DriverName:database_name
    DriverName:database_name@hostname:port
    DriverName:database=database_name;host=hostname;port=port
```
In plugin.pm:

```perl
$self->{sqldefault}->{dbi} = ();
$self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };
```
In your mode:

```perl
$self->{sql} = $options{sql};
my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);
```
Then, you are connected to the MySQL database.

#### 7.2 query

**Description**

Send query to database.

**Parameters**

| Parameter | Type   | Default | Description        |
|-----------|--------|---------|--------------------|
| query     | String |         | SQL query to send. |

**Example**

This is an example of how to use **query** method:

```perl
$self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Slow_queries'});
my ($name, $result) = $self->{sql}->fetchrow_array();

print 'Name : '.$name."\n";
print 'Value : '.$value."\n";
```
Output displays count of MySQL slow queries.

#### 7.3 fetchrow_array

**Description**

Return Array from sql query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_array** method:

```perl
$self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
my ($dummy, $result) = $self->{sql}->fetchrow_array();

print 'Uptime : '.$result."\n";
```
Output displays MySQL uptime.

#### 7.4 fetchall_arrayref

**Description**

Return Array from SQL query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_array** method:

```perl
$self->{sql}->query(query => q{
      SELECT SUM(DECODE(name, 'physical reads', value, 0)),
          SUM(DECODE(name, 'physical reads direct', value, 0)),
          SUM(DECODE(name, 'physical reads direct (lob)', value, 0)),
          SUM(DECODE(name, 'session logical reads', value, 0))
      FROM sys.v_$sysstat
});
my $result = $self->{sql}->fetchall_arrayref();

my $physical_reads = @$result[0]->[0];
my $physical_reads_direct = @$result[0]->[1];
my $physical_reads_direct_lob = @$result[0]->[2];
my $session_logical_reads = @$result[0]->[3];

print $physical_reads."\n";
```
Output displays physical reads on Oracle database.

#### 7.5 fetchrow_hashref

**Description**

Return Hash table from SQL query.

**Parameters**

None.

**Example**

This is an example of how to use **fetchrow_hashref** method:

```perl
$self->{sql}->query(query => q{
  SELECT datname FROM pg_database
});

while ((my $row = $self->{sql}->fetchrow_hashref())) {
  print $row->{datname}."\n";
}
```
Output displays Postgres databases.

<div id='model_class_usage'/>

### 8. Model Classes Usage

**Introduction**

With the experience of plugin development, we have created two classes:

* centreon::plugins::templates::counter
* centreon::plugins::templates::hardware

It was developed to have a more consistent code and less redundant code. 
According to context, you should use one of two classes for modes. 
Following classes can be used for whatever plugin type (SNMP, Custom, DBI,...).

**Class counter**

*When to use it ?*

If you have some counters (CPU Usage, Memory, Session...), you should use that 
class.
If you have only one global counter to check, it's maybe not useful to use it 
(but only for these case).

*Class methods*

List of methods:

* **new**: class constructor. Overload if you need to add some specific options 
or to use a statefile.
* **check_options**: overload if you need to check your specific options.
* **manage_selection**: overload is *mandatory*. Method to get informations for 
the equipment.
* **set_counters**: overload is **mandatory**. Method to configure counters.

**Class hardware**






TODO





[Table of content (1)](#table_of_contents)




#### 8.1. Example 1

We want to develop the following SNMP plugin:

* measure the current sessions and current SSL sessions usages.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Current sessions : %s',
                perfdatas => [
                    { label => 'sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' } ],
                output_template => 'Current ssl sessions : %s',
                perfdatas => [
                    { label => 'sessions_ssl', template => '%s', min => 0 },
                ],
            }
        },
    ];
  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    # OIDs are fake. Only for the example.
    my ($oid_sessions, $oid_sessions_ssl) = ('.1.2.3.4.0', '.1.2.3.5.0');
    
    my $result = $options{snmp}->get_leef(
      oids => [ $oid_sessions, $oid_sessions_ssl ],
      nothing_quit => 1
    );
    $self->{global} = {
      sessions => $result->{$oid_sessions},
      sessions_ssl => $result->{$oid_sessions_ssl}
    };
  }
```
Output may display:

```
  OK: Current sessions : 24 - Current ssl sessions : 150 | sessions=24;;;0; sessions_ssl=150;;;0;
```
As you can see, we create two arrays of hash tables in **set_counters** method. We use arrays to order the output.

* **maps_counters_type**: global configuration. Attributes list:

  * *name*: the name is really important. It will be used in hash **map_counters** and also in **manage_selection** as you can see.
  * *type*: 0 or 1. With 0 value, the output will be written in the short output. With the value 1, it depends if we have one or multiple instances.
  * *message_multiple*: only useful with *type* 1 value. The message will be displayed in short ouput if we have multiple instances selected.
  * *message_separator*: the string displayed between counters (Default: ', ').
  * *cb_prefix_output*, *cb_suffix_output*: name of a method (in a string) to callback. Methods will return a string to be displayed before or after **all** counters.
  * *cb_init*: name of a method (in a string) to callback. Method will return 0 or 1. With 1 value, counters are not checked.

* **maps_counters**: complex structure to configure counters. Attributes list:

  * *label*: name used for threshold options.
  * *type*: depend of data dimensions
    * 0 : global
    * 1 : instance
    * 2 : group
    * 3 : multiple
  * *threshold*: if we set the value to 0. There is no threshold check options (can be used if you want to set and check option yourself).
  * *set*: hash table:
  
    * *keys_values*: array of hashes. Set values used for the counter. Order is important (by default, the first value is used to check). 

      * *name*: attribute name. Need to match with attributes in **manage_selection** method!
      * *diff*: if we set the value to 1, we'll have the difference between two checks (need a statefile!).
      * *per_second*: if we set the value to 1, the *diff* values will be calculated per seconds (need a statefile!). No need to add diff attribute.
    
    * *output_template*: string to display. '%s' will be replaced by the first value of *keys_values*.
    * *output_use*: which value to be used in *output_template* (If not set, we use the first value of *keys_values*).
    * *output_change_bytes*: if we set the value to 1 or 2, we can use a second '%s' in *output_template* to display the unit. 1 = divide by 1024 (Bytes), 2 = divide by 1000 (bits).
    * *perfdata*: array of hashes. To configure perfdatas
    
      * *label*: name displayed.
      * *value*: value to used. It's the name from *keys_values*.
      * *template*: value format (could be for example: '%.3f').
      * *unit*: unit displayed.
      * *min*, *max*: min and max displayed. You can use a value from *keys_values*.
      * *label_extra_instance*: if we set the value to 1, perhaps we'll have a suffix concat with *label*.
      * *instance_use*: which value from *keys_values* to be used. To be used if *label_extra_instance* is 1.

#### 8.2. Example 2

We want to add the current number of sessions by virtual servers.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All Virtual servers are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-sessions', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'current sessions : %s',
                perfdatas => [
                    { label => 'total_sessions', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' } ],
                output_template => 'current ssl sessions : %s',
                perfdatas => [
                    { label => 'total_sessions_ssl', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{vs} = [
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => 'current sessions : %s',
                perfdatas => [
                    { label => 'sessions', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sessions-ssl', set => {
                key_values => [ { name => 'sessions_ssl' }, { name => 'display' } ],
                output_template => 'current ssl sessions : %s',
                perfdatas => [
                    { label => 'sessions_ssl', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
  }
  
  sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
  }
  
  sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    # OIDs are fake. Only for the example.
    my ($oid_sessions, $oid_sessions_ssl) = ('.1.2.3.4.0', '.1.2.3.5.0');
    
    my $result = $options{snmp}->get_leef(oids => [ $oid_sessions, $oid_sessions_ssl ],
                                          nothing_quit => 1);
    $self->{global} = { sessions => $result->{$oid_sessions},
                        sessions_ssl => $result->{$oid_sessions_ssl}
                      };
    my $oid_table_vs = '.1.2.3.10';
    my $mapping = {
        vsName        => { oid => '.1.2.3.10.1' },
        vsSessions    => { oid => '.1.2.3.10.2' },
        vsSessionsSsl => { oid => '.1.2.3.10.3' },
    };
    
    $self->{vs} = {};
    $result = $options{snmp}->get_table(oid => $oid_table_vs,
                                        nothing_quit => 1);
    foreach my $oid (keys %{$result->{ $oid_table_vs }}) {
        next if ($oid !~ /^$mapping->{vsName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $result->{$oid_table_vs}, instance => $instance);
        
        $self->{vs}->{$instance} = { display => $data->{vsName}, 
                                     sessions => $data->{vsSessions}, sessions_ssl => $data->{vsSessionsSsl}};
    }
  }
```
If we have at least 2 virtual servers:

```
  OK: Total current sessions : 24, current ssl sessions : 150 - All Virtual servers are ok | total_sessions=24;;;0; total_sessions_ssl=150;;;0; sessions_foo1=11;;;0; sessions_ssl_foo1=70;;;0; sessions_foo2=13;;;0; sessions_ssl_foo2=80;;;0;
  Virtual server 'foo1' current sessions : 11, current ssl sessions : 70
  Virtual server 'foo2' current sessions : 13, current ssl sessions : 80
```

#### 8.3. Example 3

The model can also be used to check strings (not only counters). So we want to check the status of a virtualserver.

```perl
  package my::module::name;
  
  use base qw(centreon::plugins::templates::counter);
  
  use strict;
  use warnings;
  
  sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All Virtual server status are ok' }
    ];    
    $self->{maps_counters}->{vs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output')
            }
        }
    ];
  }
  
  sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    
    if ($self->{result_values}->{status} =~ /problem/) {
        $status = 'critical';
    }
    return $status;
  }
  
  sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
  }
  
  sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
  }
  
  sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
  }
  
  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

  }
  
  sub manage_selection {
    my ($self, %options) = @_;

    my $oid_table_vs = '.1.2.3.10';
    my $mapping = {
        vsName        => { oid => '.1.2.3.10.1' },
        vsStatus      => { oid => '.1.2.3.10.4' },
    };
    
    $self->{vs} = {};
    my $result = $options{snmp}->get_table(oid => $oid_table_vs,
                                        nothing_quit => 1);
    foreach my $oid (keys %{$result->{ $oid_table_vs }}) {
        next if ($oid !~ /^$mapping->{vsName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $result->{$oid_table_vs}, instance => $instance);
        
        $self->{vs}->{$instance} = { display => $data->{vsName}, 
                                     status => $data->{vsStatus} };
    }
  }
```
The following example show 4 new attributes:

* *closure_custom_calc*: should be used to do more complex calculation.
* *closure_custom_output*: should be used to have a more complex output (An example: want to display the total, free and used value at the same time).
* *closure_custom_perfdata*: should be used to manage yourself the perfdata.
* *closure_custom_threshold_check*: should be used to manage yourself the threshold check.

[Table of content (1)](#table_of_contents)