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

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name : it matches your plugin directory.

.. code-block:: perl

  package path::to::plugin;

Declare used libraries (**strict** and **warnings** are mandatory). Centreon libraries are described later :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(**centreon_library**);

The plugin need a **new** function to instantiate the object :

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...
        
        return $self;
  }

Plugin version must be declared in the **new** function :

.. code-block:: perl

  $self->{version} = '0.1';

Several modes can be declared in the **new** function :

.. code-block:: perl

  %{$self->{modes}} = (
                        'mode1'    => '<plugin_path>::mode::mode1',
                        'mode2'    => '<plugin_path>::mode::mode2',
                        ...
                        );

Then, Declare the module :

.. code-block:: perl

  1;

A description of the plugin is needed to generate the documentation :

.. code-block:: perl

  __END__
  
  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.
  
  =cut


.. tip::
  you can copy-paste an other plugin.pm and adapt some lines (package, arguments...).

.. tip::
  plugin has ".pm" extension because it's a perl module. So don't forget to add **1;** at the end of the file


-------------
Mode creation
-------------

Once **plugin.pm** is created and modes are declared in it, create modes in the **mode directory** :
::

  cd mode
  touch mode1.pm

Then, edit mode1.pm to add **license terms** by copying it from an other plugin. Don't forget to put your name at the end of it :

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name : it matches your mode directory.

.. code-block:: perl

  package path::to::plugin::mode::mode1;

Declare used libraries (always the same) :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

The mode need a **new** function to instantiate the object :

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

Mode version must be declared in the **new** function :

.. code-block:: perl

  $self->{version} = '1.0';

Several options can be declared in the **new** function :

.. code-block:: perl

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

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

For example, Warning and Critical thresholds must be validate in **check_options** function :

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

  1;

A description of the mode and its arguments is needed to generate the documentation :

.. code-block:: perl

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
| separator       | String          |    \-       | Separator between status and output string.             |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| short_msg       | String          |             | Short output (first line).                              |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| long_msg        | String          |             | Long output (used with --verbose option).               |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to manage output :

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

  my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

  $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

  my $result = $self->{snmp}->get_leef(nothing_quit => 1);

  use Data::Dumper;
  print Dumper($result);

This is an example of how to get multiple instances dynamically (memory modules of dell hardware) by using **load** function :

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

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

.. code-block:: perl

  foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
    print $oid;
  }


----
Misc
----

This library provides a set of miscellaneous functions.
To use it, you can directly use the path of the function :

.. code-block:: perl

  centreon::plugins::misc::<my_function>;


trim
----

Description
^^^^^^^^^^^

Strip whitespace from the beginning and end of a string.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | String          |             | String to strip.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use trim function :

.. code-block:: perl

  my $word = '  Hello world !  ';
  my $trim_word =  centreon::plugins::misc::trim($word);

  print $word."\n";
  print $trim_word."\n";

Output displays :
::

    Hello world !  
  Hello world !


change_seconds
--------------

Description
^^^^^^^^^^^

Convert seconds to human readable text.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | Int             |             | Number of seconds to convert.                           |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use change_seconds function :

.. code-block:: perl

  my $seconds = 3750;
  my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

  print 'Human readable time : '.$human_readable_time."\n";

Output displays :
::

  Human readable time : 1h 2m 30s


backtick
--------

Description
^^^^^^^^^^^

Execute system command.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| **command**     | String          |             | Command to execute.                                     |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| arguments       | String array    |             | Command arguments.                                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| timeout         | Int             |     30      | Command timeout.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| wait_exit       | Int (0 or 1)    |     0       | Command process ignore SIGCHLD signals.                 |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| redirect_stderr | Int (0 or 1)    |     0       | Print errors in output.                                 |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use backtick function :

.. code-block:: perl

  my ($error, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                      command => 'ls /home',
                                      timeout => 5,
                                      wait_exit => 1
                                      );

  print $stdout."\n";

Output displays files in '/home' directory.


execute
-------

Description
^^^^^^^^^^^

Execute command remotely.

Parameters
^^^^^^^^^^

+------------------+-----------------+-------------+-----------------------------------------------------------------+
|  Parameter       |    Type         |   Default   |          Description                                            |
+==================+=================+=============+=================================================================+
| **output**       | Object          |             | Plugin output ($self->{output}).                                |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| **options**      | Object          |             | Plugin options ($self->{option_results}) to get remote options. |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| sudo             | String          |             | Use sudo command.                                               |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| **command**      | String          |             | Command to execute.                                             |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_path     | String          |             | Command path.                                                   |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_options  | String          |             | Command arguments.                                              |
+------------------+-----------------+-------------+-----------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use execute function.
We suppose --remote option is enable :

.. code-block:: perl

  my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                options => $self->{option_results},
                                                sudo => 1,
                                                command => 'ls /home',
                                                command_path => '/bin/',
                                                command_options => '-l');

Output displays files in /home using ssh on a remote host.


windows_execute
---------------

Description
^^^^^^^^^^^

Execute command on Windows.

Parameters
^^^^^^^^^^

+------------------+-----------------+-------------+-----------------------------------------------------------------+
|  Parameter       |    Type         |   Default   |          Description                                            |
+==================+=================+=============+=================================================================+
| **output**       | Object          |             | Plugin output ($self->{output}).                                |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| **command**      | String          |             | Command to execute.                                             |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_path     | String          |             | Command path.                                                   |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_options  | String          |             | Command arguments.                                              |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| timeout          | Int             |             | Command timeout.                                                |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| no_quit          | Int             |             | Don't quit even if an error occured.                            |
+------------------+-----------------+-------------+-----------------------------------------------------------------+


Example
^^^^^^^

This is an example of how to use windows_execute function.

.. code-block:: perl

  my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                        timeout => 10,
                                                        command => 'ipconfig',
                                                        command_path => '',
                                                        command_options => '/all');

Output displays ip configuration on a Windows host.


---------
Statefile
---------

This library provides a set of functions to use a cache file.
To use it, Add the following line at the beginning of your **mode** :

.. code-block:: perl

  use centreon::plugins::statefile;


read
----

Description
^^^^^^^^^^^

Read cache file.

Parameters
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter        |    Type         |   Default   |          Description                                    |
+===================+=================+=============+=========================================================+
| **statefile**     | String          |             | Name of the cache file.                                 |
+-------------------+-----------------+-------------+---------------------------------------------------------+
| **statefile_dir** | String          |             | Directory of the cache file.                            |
+-------------------+-----------------+-------------+---------------------------------------------------------+
| memcached         | String          |             | Memcached server to use.                                |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use read function :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  use Data::Dumper;
  print Dumper($self->{statefile_value});

Output displays cache file and its parameters.


get
---

Description
^^^^^^^^^^^

Get data from cache file.

Parameters
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter        |    Type         |   Default   |          Description                                    |
+===================+=================+=============+=========================================================+
| name              | String          |             | Get a value from cache file.                            |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use get function :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $value = $self->{statefile_value}->get(name => 'property1');
  print $value."\n";

Output displays value for 'property1' of the cache file.


write
-----

Description
^^^^^^^^^^^

Write data to cache file.

Parameters
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter        |    Type         |   Default   |          Description                                    |
+===================+=================+=============+=========================================================+
| data              | String          |             | Data to write in cache file.                            |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use write function :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $new_datas = {};
  $new_datas->{last_timestamp} = time();
  $self->{statefile_value}->write(data => $new_datas);

Then, you can take a look to '/var/lib/centreon/centplugins/my_cache_file', timestamp is written in it.


----
Http
----

This library provides a set of functions to use HTTP protocol.
To use it, Add the following line at the beginning of your **mode** :

.. code-block:: perl

  use centreon::plugins::httplib;

Some options must be set in **plugin.pm** :

+-----------------+-----------------+---------------------------------------------------------+
|  Option         |    Type         |          Description                                    |
+=================+=================+=========================================================+
| **hostname**    | String          | IP Addr/FQDN of the webserver host.                     |
+-----------------+-----------------+---------------------------------------------------------+
| **port**        | String          | HTTP port.                                              |
+-----------------+-----------------+---------------------------------------------------------+
| **proto**       | String          | Used protocol ('http' or 'https').                      |
+-----------------+-----------------+---------------------------------------------------------+
| credentials     |                 | Use credentials.                                        | 
+-----------------+-----------------+---------------------------------------------------------+
| ntlm            |                 | Use NTLM authentication (if credentials is used).       |
+-----------------+-----------------+---------------------------------------------------------+
| username        | String          | Username (if credentials is used).                      |
+-----------------+-----------------+---------------------------------------------------------+
| password        | String          | User password (if credentials is used).                 |
+-----------------+-----------------+---------------------------------------------------------+
| proxyurl        | String          | Proxy to use.                                           |
+-----------------+-----------------+---------------------------------------------------------+
| url_path        | String          | URL to connect (start to '/').                          |
+-----------------+-----------------+---------------------------------------------------------+

connect
-------

Description
^^^^^^^^^^^

Strip whitespace from the beginning and end of a string.

Parameters
^^^^^^^^^^

This function use plugin options previously defined.

Example
^^^^^^^

This is an example of how to use connect function.
We suppose these options are defined :
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

.. code-block:: perl

  my $webcontent = centreon::plugins::httplib::connect($self);
  print $webcontent;

Output displays content of the webpage '\http://google.com/'.


---
Dbi
---

This library allows you to connect to databases.
To use it, Add the following line at the beginning of your **plugin.pm** :

.. code-block:: perl

  use base qw(centreon::plugins::script_sql);

connect
-------

Description
^^^^^^^^^^^

Connect to databases.

Parameters
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter        |    Type         |   Default   |          Description                                    |
+===================+=================+=============+=========================================================+
| dontquit          | Int (0 or 1)    |     0       | Don't quit even if errors occured.                      |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use connect function.

In plugin.pm :

.. code-block:: perl

  $self->{sqldefault}->{dbi} = ();
  $self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };

In your mode :

.. code-block:: perl

  $self->{sql} = $options{sql};
  my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);

Then, you are connected to the MySQL database.

