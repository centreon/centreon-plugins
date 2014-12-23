***********
Description
***********

This document introduces the best practices in the development of "centreon-plugins".

As all plugins are written in Perl, “there is more than on way to do it”.
But to not reinvent the wheel, you should first take a look at the “example” directory, you will get an overview of how to build your own plugin and associated modes.

The lastest version is available on following git repository: http://git.centreon.com/centreon-plugins.git

***********
Quick Start
***********

------------------
Directory creation
------------------

First of all, you need to create a directory on the git to store the new plugin.

Root directories are organized by section :

* Application       : apps
* Database          : database
* Hardware          : hardware
* network equipment : network
* Operating System  : os
* Storage equipment : storage

According to the monitored object, there exists an organization which can use :

* Type
* Constructor
* Model
* Monitoring Protocol

For example, if you want to add a plugin to monitor Linux by SNMP, you need to create this directory :
::

  mkdir -p os/linux/snmp

You also need to create a "mode" directory for futures modes :
::

  mkdir os/linux/snmp/mode

---------------
Plugin creation
---------------

Once the directory is created, create the plugin file inside it :
::

  touch plugin.pm

Then, edit plugin.pm to add **license terms** by copying it from an other plugin. Don't forget to put your name at the end of it :
::

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name : it matches your plugin directory.
::

  package path::to::plugin;

Declare used libraries (**strict** and **warnings** are mandatory). Centreon libraries are described later :
::

  use strict;
  use warnings;
  use base qw(**centreon_library**);

The plugin need a **new** function to instantiate the object :
::

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...
        
        return $self;
  }

Plugin version must be declared in the **new** function :
::

  $self->{version} = '0.1';

Several modes can be declared in the **new** function :
::

  %{$self->{modes}} = (
                        'mode1'    => '<plugin_path>::mode::mode1',
                        'mode2'    => '<plugin_path>::mode::mode2',
                        ...
                        );

Then, Declare the module :
::

  1;

A description of the plugin is needed to generate the documentation :
::

  __END__
  
  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.
  
  =cut


.. tip::
  you can copy-paste an other plugin.pm and adapt some lines (package, arguments...).

.. tip::
  plugin has ".pm" extension because it's a perl module. So don't forget to add **1;** at then end of the file


-------------
Mode creation
-------------

Once **plugin.pm** is created and modes are declared in it, create modes in the **mode directory** :
::

  cd mode
  touch mode1.pm

Then, edit mode1.pm to add **license terms** by copying it from an other plugin. Don't forget to put your name at the end of it :
::

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name : it matches your mode directory.
::

  package path::to::plugin::mode::mode1;

Declare used libraries (always the same) :
::

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

The mode need a **new** function to instantiate the object :
::

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

Mode version must be declared in the **new** function :
::

  $self->{version} = '1.0';

Several options can be declared in the **new** function :
::

  $options{options}->add_options(arguments =>
                                {
                                  "option1:s" => { name => 'option1' },
                                  "option2:s" => { name => 'option2', default => 'value1' },
                                  "option3"   => { name => 'option3' },
                                });

This the description of arguments of this example :

* option1 : String value
* option2 : String value with default value "value1"
* option3 : Boolean value

.. tip::
  You can have more informations about options format here : http://perldoc.perl.org/Getopt/Long.html

The mode need a **check_options** function to validate options :
::

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

For example, Warning and Critical thresholds must be validate in **check_options** function :
::

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
  }

In this example, help is printed if thresholds have not a correct format.

Then comes the **run** function, where you perform measurement, check thresholds, display output and format perfdatas.
This is an example to check a snmp value :
::

  sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();

    my $result = $self->{snmp}->get_leef(oids => [$self->{option_results}->{oid}], nothing_quit => 1);
    my $value = $result->{$self->{option_results}->{oid}};

    my $exit = $self->{perfdata}->threshold_check(value => $value,
                               threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("SNMP Value is %s.", $value));

    $self->{output}->perfdata_add(label => 'value', unit => undef,
                                  value => $value,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => undef, max => undef);

    $self->{output}->display();
    $self->{output}->exit();
  }

In this example, we check a snmp OID that we compare to wargning and critical thresholds.
There are the function which we use :

* get_leef        : get a snmp value from an OID
* threshold_check : compare snmp value to warning and critical thresholds
* output_add      : add output
* perfdata_add    : add perfdata to output
* display         : display output
* exit            : exit

Then, declare the module :
::

  1;

A description of the mode and its arguments is needed to generate the documentation :
::

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut


---------------
Commit and push
---------------

Before commit the plugin, you need to create an **enhancement ticket** on the centreon-plugins forge : http://forge.centreon.com/projects/centreon-plugins

Once plugin and modes are developed, you can commit and push your work :
::

  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push

*******************
Libraries reference
*******************

This chapter describes centreon libraries which you can use in your development.

------
Output
------

This library allows you to change output of your plugin.

output_add
----------

Description
^^^^^^^^^^^

Add string to output (print it with **display** function).
If status is different than 'ok', output associated with 'ok' status is not printed.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| severity        | String          |    OK       | Status of the output.                                   |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| separator       | String          |    '-'      | Separator between status and output string.             |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| short_msg       | String          |             | Short output (first line).                              |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| long_msg        | String          |             | Long output (used with --verbose option).               |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to manage output :
::

  $self->{output}->output_add(severity  => 'OK',
                              short_msg => 'All is ok');
  $self->{output}->output_add(severity  => 'Critical',
                              short_msg => 'There is a critical problem');
  $self->{output}->output_add(long_msg  => 'Port 1 is disconnected');

  $self->{output}->display();

Output displays :
::

  CRITICAL - There is a critical problem
  Port 1 is disconnected


perfdata_add
------------

Description
^^^^^^^^^^^

Add performance data to output (print it with **display** function).
Performance data are displayed after '|'.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| label           | String          |             | Label of the performance data.                          |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| value           | Int             |             | Value of the performance data.                          |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| unit            | String          |             | Unit of the performance data.                           |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| warning         | String          |             | Warning threshold.                                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| critical        | String          |             | Critical threshold.                                     |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| min             | Int             |             | Minimum value of the performance data.                  |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| max             | Int             |             | Maximum value of the performance data.                  |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to add performance data :
::

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

Output displays :
::

  OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000


-------
Perdata
-------

This library allows you to manage performance data.

get_perfdata_for_output
-----------------------

Description
^^^^^^^^^^^

Manage thresholds of performance data for output.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+-----------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                      |
+=================+=================+=============+===========================================================+
| **label**       | String          |             | Threshold label.                                          |
+-----------------+-----------------+-------------+-----------------------------------------------------------+
| total           | Int             |             | Percent threshold to transform in global.                 |
+-----------------+-----------------+-------------+-----------------------------------------------------------+
| cast_int        | Int (0 or 1)    |             | Cast absolute to int.                                     |
+-----------------+-----------------+-------------+-----------------------------------------------------------+
| op              | String          |             | Operator to apply to start/end value (uses with 'value'). |
+-----------------+-----------------+-------------+-----------------------------------------------------------+
| value           | Int             |             | Value to apply with 'op' option.                          |
+-----------------+-----------------+-------------+-----------------------------------------------------------+


Example
^^^^^^^

This is an example of how to manage performance data for output :
::

  my $format_warning_perfdata  = $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => 1000000000, cast_int => 1);
  my $format_critical_perfdata = $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => 1000000000, cast_int => 1);

  $self->{output}->perfdata_add(label    => 'memory_used',
                                value    => 30000000,
                                unit     => 'B',
                                warning  => $format_warning_perfdata,
                                critical => $format_critical_perfdata,
                                min      => 0,
                                max      => 1000000000);

.. tip::
  In this example, instead of print warning and critical thresholds in 'percent', the function calculates and prints these in 'bytes'.

threshold_validate
------------------

Description
^^^^^^^^^^^

Validate and affect threshold to a label.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| label           | String          |             | Threshold label.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| value           | String          |             | Threshold value.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This example checks if warning threshold is correct :
::

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
    $self->{output}->option_exit();
  }

.. tip::
  You can see the correct threshold format here : https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

threshold_check
---------------

Description
^^^^^^^^^^^

Check performance data value with threshold to determine status.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| value           | Int             |             | Performance data value to compare.                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| threshold       | String array    |             | Threshold label to compare and exit status if reached.  |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This example checks if performance data reached thresholds :
::

  $self->{perfdata}->threshold_validate(label => 'warning', value => 80);
  $self->{perfdata}->threshold_validate(label => 'critical', value => 90);
  my $prct_used = 85;

  my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

  $self->{output}->output_add(severity  => $exit,
                              short_msg => sprint("Used memory is %i%%", $prct_used));  
  $self->{output}->display();

Output displays :
::

  WARNING - Used memory is 85% |

change_bytes
------------

Description
^^^^^^^^^^^

Convert bytes to human readable unit.
Return value and unit.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| value           | Int             |             | Performance data value to compare.                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| network         |                 | 1024        | Unit to divide (1000 if defined).                       |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This example change bytes to human readable unit :
::

  my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

  print $value.' '.$unit."\n";

Output displays :
::

  100 KB

----
Snmp
----

This library allows you to use snmp protocol in your plugin.
To use it, Add the following line at the beginning of your **plugin.pm** :
::

  use base qw(centreon::plugins::script_snmp);


get_leef
--------

Description
^^^^^^^^^^^

Return hash table table of SNMP values for multiple OIDs (Do not work with SNMP table).

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| **oids**        | String array    |             | Array of OIDs to check (Can be set by load function).   |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| dont_quit       | Int (0 or 1)    |     0       | Don't quit even if an snmp error occured.               |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| nothing_quit    | Int (0 or 1)    |     0       | Quit if no value is returned.                           |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 2 snmp values :
::

  my $oid_hrSystemUptime = '.1.3.6.1.2.1.25.1.1.0';
  my $oid_sysUpTime = '.1.3.6.1.2.1.1.3.0';

  my $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemUptime, $oid_sysUpTime ], nothing_quit => 1);

  print $result->{$oid_hrSystemUptime}."\n";
  print $result->{$oid_sysUpTime}."\n";


load
----

Description
^^^^^^^^^^^

Load a range of oids to use with **get_leef** function.

Parameters
^^^^^^^^^^

+-----------------+----------------------+--------------+----------------------------------------------------------------+
|  Parameter      |        Type          |   Default    |          Description                                           |
+=================+======================+==============+================================================================+
| **oids**        |  String array        |              | Array of OIDs to check.                                        |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| instances       |  Int array           |              | Array of OIDs to check.                                        |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| instance_regexp |  String              |              | Regular expression to get instances from **instances** option. |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| begin           |  Int                 |              | Instance to begin                                              |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| end             |  Int                 |              | Instance to end                                                |
+-----------------+----------------------+--------------+----------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 4 instances of a snmp table by using **load** function :
::

  my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

  $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

  my $result = $self->{snmp}->get_leef(nothing_quit => 1);

  use Data::Dumper;
  print Dumper($result);

This is an example of how to get multiple instances dynamically (memory modules of dell hardware) by using **load** function :
::

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


get_table
---------

Description
^^^^^^^^^^^

Return hash table of SNMP values for SNMP table.

Parameters
^^^^^^^^^^

+-----------------+----------------------+----------------+--------------------------------------------------------------+
|  Parameter      |        Type          |   Default      |          Description                                         |
+=================+======================+================+==============================================================+
| **oid**         |  String              |                | OID of the snmp table to check.                              |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| start           |  Int                 |                | First OID to check.                                          |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| end             |  Int                 |                | Last OID to check.                                           |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Don't quit even if an snmp error occured.                    |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quit if no value is returned.                                |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Return a hash table with one level instead of multiple.      |
+-----------------+----------------------+----------------+--------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get a snmp table :
::

  my $oid_rcDeviceError            = '.1.3.6.1.4.1.15004.4.2.1';
  my $oid_rcDeviceErrWatchdogReset = '.1.3.6.1.4.1.15004.4.2.1.2.0';

  my $results = $self->{snmp}->get_table(oid => $oid_rcDeviceError, start => $oid_rcDeviceErrWatchdogReset);

  use Data::Dumper;
  print Dumper($results);


get_multiple_table
------------------

Description
^^^^^^^^^^^

Return hash table of SNMP values for multiple SNMP tables.

Parameters
^^^^^^^^^^

+-----------------+----------------------+----------------+--------------------------------------------------------------+
|  Parameter      |        Type          |   Default      |          Description                                         |
+=================+======================+================+==============================================================+
| **oids**        |  Hash table          |                | Hash table of OIDs to check (Can be set by load function).   |
|                 |                      |                | Keys can be : "oid", "start", "end".                         |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Don't quit even if an snmp error occured.                    |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quit if no value is returned.                                |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Return a hash table with one level instead of multiple.      |
+-----------------+----------------------+----------------+--------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 2 snmp tables :
::

  my $oid_sysDescr        = ".1.3.6.1.2.1.1.1";
  my $aix_swap_pool       = ".1.3.6.1.4.1.2.6.191.2.4.2.1";

  my $results = $self->{snmp}->get_multiple_table(oids => [
                                                        { oid => $aix_swap_pool, start => 1 },
                                                        { oid => $oid_sysDescr },
                                                  ]);

  use Data::Dumper;
  print Dumper($results);


get_hostname
------------

Description
^^^^^^^^^^^

Get hostname parameter (useful to get hostname in mode).

Parameters
^^^^^^^^^^

None.

Example
^^^^^^^

This is an example of how to get hostname parameter :
::

  my $hostname = $self->{snmp}->get_hostname();


get_port
--------

Description
^^^^^^^^^^^

Get port parameter (useful to get port in mode).

Parameters
^^^^^^^^^^

None.

Example
^^^^^^^

This is an example of how to get port parameter :
::

  my $port = $self->{snmp}->get_port();


oid_lex_sort
------------

Description
^^^^^^^^^^^

Return sorted OIDs.

Parameters
^^^^^^^^^^

+-----------------+-------------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type           |   Default   |          Description                                    |
+=================+===================+=============+=========================================================+
| **-**           |  String array     |             | Array of OIDs to sort.                                  |
+-----------------+-------------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This example prints sorted OIDs :
::

  foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
    print $oid;
  }

