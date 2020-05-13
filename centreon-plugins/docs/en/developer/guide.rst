***********
Description
***********

This document introduces the best practices in the development of "centreon-plugins".

As all plugins are written in Perl, “there is more than one way to do it”.
But to avoid reinventing the wheel, you should first take a look at the “example” directory, you will get an overview of how to build your own plugin and associated modes.

There are 3 chapters:

* :ref:`Quick Start <quick-start>`: Howto create file structure.
* :ref:`Libraries Reference <libraries_reference>`: API description.
* :ref:`Code Style Guidelines <code_style_guidelines>`: Follow it.
* :ref:`Model Classes Usage <model_classes_usage>`: description of classes you should use for your plugin.

The lastest version is available on following git repository: https://github.com/centreon/centreon-plugins.git

.. _quick-start:

***********
Quick Start
***********

------------------
Directory creation
------------------

First of all, you need to create a directory on the git to store the new plugin.

Root directories are organized by section:

* Application       : apps
* Database          : database
* Hardware          : hardware
* network equipment : network
* Operating System  : os
* Storage equipment : storage

According to the monitored object, it exists an organization which can use:

* Type
* Constructor
* Model
* Monitoring Protocol

For example, if you want to add a plugin to monitor Linux by SNMP, you need to create this directory:
::

  $ mkdir -p os/linux/snmp

You also need to create a "mode" directory for futures modes:
::

  $ mkdir os/linux/snmp/mode

---------------
Plugin creation
---------------

Once the directory is created, create the plugin file inside it:
::

  $ touch plugin.pm

Then, edit plugin.pm to add **license terms** by copying it from an other plugin. Don't forget to put your name at the end of it:

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name : it matches your plugin directory.

.. code-block:: perl

  package path::to::plugin;

Declare used libraries (**strict** and **warnings** are mandatory). Centreon libraries are described later:

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(**centreon_library**);

The plugin need a **new** constructor to instantiate the object:

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

Plugin version must be declared in the **new** constructor:

.. code-block:: perl

  $self->{version} = '0.1';

Several modes can be declared in the **new** constructor:

.. code-block:: perl

  $self->{modes} = {
      'mode1'    => '<plugin_path>::mode::mode1',
      'mode2'    => '<plugin_path>::mode::mode2',
      ...
  };

Then, declare the module:

.. code-block:: perl

  1;

A description of the plugin is needed to generate the documentation:

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut


.. tip::
  You can copy-paste an other plugin.pm and adapt some lines (package, arguments...).

.. tip::
  The plugin has ".pm" extension because it's a Perl module. So don't forget to add **1;** at the end of the file.

-------------
Mode creation
-------------

Once **plugin.pm** is created and modes are declared in it, create modes in the **mode** directory:
::

  cd mode
  touch mode1.pm

Then, edit mode1.pm to add **license terms** by copying it from an other mode. Don't forget to put your name at the end of it:

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Next, describe your **package** name: it matches your mode directory.

.. code-block:: perl

  package path::to::plugin::mode::mode1;

Declare used libraries (always the same):

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

The mode needs a **new** constructor to instantiate the object:

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

Mode version must be declared in the **new** constructor:

.. code-block:: perl

  $self->{version} = '1.0';

Several options can be declared in the **new** constructor:

.. code-block:: perl

  $options{options}->add_options(arguments => {
      "option1:s" => { name => 'option1' },
      "option2:s" => { name => 'option2', default => 'value1' },
      "option3"   => { name => 'option3' },
  });

Here is the description of arguments used in this example:

* option1 : String value
* option2 : String value with default value "value1"
* option3 : Boolean value

.. tip::
  You can have more informations about options format here: http://perldoc.perl.org/Getopt/Long.html

The mode need a **check_options** method to validate options:

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

For example, Warning and Critical thresholds must be validate in **check_options** method:

.. code-block:: perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
  }

In this example, help is printed if thresholds do not have a correct format.

Then comes the **run** method, where you perform measurement, check thresholds, display output and format performance datas.
This is an example to check a SNMP value:

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

In this example, we check a SNMP OID that we compare to warning and critical thresholds.
There are the methods which we use:

* get_leef        : get a SNMP value from an OID
* threshold_check : compare SNMP value to warning and critical thresholds
* output_add      : add output
* perfdata_add    : add perfdata to output
* display         : display output
* exit            : exit

Then, declare the module:

.. code-block:: perl

  1;

A description of the mode and its arguments is needed to generate the documentation:

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut

---------------
Commit and push
---------------

Before committing the plugin, you need to create an **enhancement ticket** on the centreon-plugins forge : http://forge.centreon.com/projects/centreon-plugins

Once plugin and modes are developed, you can commit (commit messages in english) and push your work:
::

  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push

.. _libraries_reference:
  
*******************
Libraries reference
*******************

This chapter describes Centreon libraries which you can use in your development.

------
Output
------

This library allows you to build output of your plugin.

output_add
----------

Description
^^^^^^^^^^^

Add string to output (print it with **display** method).
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

This is an example of how to manage output:

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

Add performance data to output (print it with **display** method).
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

This is an example of how to add performance data:

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

Output displays:
::

  OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000


--------
Perfdata
--------

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

This is an example of how to manage performance data for output:

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

This example checks if warning threshold is correct:

.. code-block:: perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
    $self->{output}->option_exit();
  }

.. tip::
  You can see the correct threshold format here: https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

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

This example checks if performance data reached thresholds:

.. code-block:: perl

  $self->{perfdata}->threshold_validate(label => 'warning', value => 80);
  $self->{perfdata}->threshold_validate(label => 'critical', value => 90);
  my $prct_used = 85;

  my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

  $self->{output}->output_add(severity  => $exit,
                              short_msg => sprint("Used memory is %i%%", $prct_used));
  $self->{output}->display();

Output displays:
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
| value           | Int             |             | Performance data value to convert.                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| network         |                 | 1024        | Unit to divide (1000 if defined).                       |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This example change bytes to human readable unit:

.. code-block:: perl

  my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

  print $value.' '.$unit."\n";

Output displays:
::

  100 KB

----
Snmp
----

This library allows you to use SNMP protocol in your plugin.
To use it, add the following line at the beginning of your **plugin.pm**:

.. code-block:: perl

  use base qw(centreon::plugins::script_snmp);


get_leef
--------

Description
^^^^^^^^^^^

Return hash table table of SNMP values for multiple OIDs (do not work with SNMP table).

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter      |    Type         |   Default   |          Description                                    |
+=================+=================+=============+=========================================================+
| **oids**        | String array    |             | Array of OIDs to check (Can be set by 'load' method).   |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| dont_quit       | Int (0 or 1)    |     0       | Don't quit even if an snmp error occured.               |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| nothing_quit    | Int (0 or 1)    |     0       | Quit if no value is returned.                           |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 2 SNMP values:

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

Load a range of OIDs to use with **get_leef** method.

Parameters
^^^^^^^^^^

+-----------------+----------------------+--------------+----------------------------------------------------------------+
|  Parameter      |        Type          |   Default    |          Description                                           |
+=================+======================+==============+================================================================+
| **oids**        |  String array        |              | Array of OIDs to check.                                        |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| instances       |  Int array           |              | Array of OID instances to check.                               |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| instance_regexp |  String              |              | Regular expression to get instances from **instances** option. |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| begin           |  Int                 |              | Instance to begin                                              |
+-----------------+----------------------+--------------+----------------------------------------------------------------+
| end             |  Int                 |              | Instance to end                                                |
+-----------------+----------------------+--------------+----------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 4 instances of a SNMP table by using **load** method:

.. code-block:: perl

  my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

  $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

  my $result = $self->{snmp}->get_leef(nothing_quit => 1);

  use Data::Dumper;
  print Dumper($result);

This is an example of how to get multiple instances dynamically (memory modules of Dell hardware) by using **load** method:

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
| dont_quit       |  Int (0 or 1)        |       0        | Don't quit even if an SNMP error occured.                    |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quit if no value is returned.                                |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Return a hash table with one level instead of multiple.      |
+-----------------+----------------------+----------------+--------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get a SNMP table:

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
| **oids**        |  Hash table          |                | Hash table of OIDs to check (Can be set by 'load' method).   |
|                 |                      |                | Keys can be: "oid", "start", "end".                          |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Don't quit even if an SNMP error occured.                    |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quit if no value is returned.                                |
+-----------------+----------------------+----------------+--------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Return a hash table with one level instead of multiple.      |
+-----------------+----------------------+----------------+--------------------------------------------------------------+

Example
^^^^^^^

This is an example of how to get 2 SNMP tables:

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

This is an example of how to get hostname parameter:

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

This is an example of how to get port parameter:

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

This example prints sorted OIDs:

.. code-block:: perl

  foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
    print $oid;
  }


----
Misc
----

This library provides a set of miscellaneous methods.
To use it, you can directly use the path of the method:

.. code-block:: perl

  centreon::plugins::misc::<my_method>;


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

This is an example of how to use **trim** method:

.. code-block:: perl

  my $word = '  Hello world !  ';
  my $trim_word =  centreon::plugins::misc::trim($word);

  print $word."\n";
  print $trim_word."\n";

Output displays :
::

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

This is an example of how to use **change_seconds** method:

.. code-block:: perl

  my $seconds = 3750;
  my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

  print 'Human readable time : '.$human_readable_time."\n";

Output displays:
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

This is an example of how to use **backtick** method:

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

This is an example of how to use **execute** method.
We suppose ``--remote`` option is enabled:

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

This is an example of how to use **windows_execute** method.

.. code-block:: perl

  my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                        timeout => 10,
                                                        command => 'ipconfig',
                                                        command_path => '',
                                                        command_options => '/all');

Output displays IP configuration on a Windows host.


---------
Statefile
---------

This library provides a set of methods to use a cache file.
To use it, add the following line at the beginning of your **mode**:

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

This is an example of how to use **read** method:

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

This is an example of how to use **get** method:

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

This is an example of how to use **write** method:

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $new_datas = {};
  $new_datas->{last_timestamp} = time();
  $self->{statefile_value}->write(data => $new_datas);

Then, you can read the result in '/var/lib/centreon/centplugins/my_cache_file', timestamp is written in it.


----
HTTP
----

This library provides a set of methodss to use HTTP protocol.
To use it, add the following line at the beginning of your **mode**:

.. code-block:: perl

  use centreon::plugins::http;

Some options must be set in **plugin.pm**:

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
| ntlm            |                 | Use NTLM authentication (if ``--credentials`` is used). |
+-----------------+-----------------+---------------------------------------------------------+
| username        | String          | Username (if ``--credentials`` is used).                |
+-----------------+-----------------+---------------------------------------------------------+
| password        | String          | User password (if ``--credentials`` is used).           |
+-----------------+-----------------+---------------------------------------------------------+
| proxyurl        | String          | Proxy to use.                                           |
+-----------------+-----------------+---------------------------------------------------------+
| url_path        | String          | URL to connect (start to '/').                          |
+-----------------+-----------------+---------------------------------------------------------+

connect
-------

Description
^^^^^^^^^^^

Test a connection to an HTTP url.
Return content of the webpage.

Parameters
^^^^^^^^^^

This method use plugin options previously defined.

Example
^^^^^^^

This is an example of how to use **connect** method.
We suppose these options are defined :
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

.. code-block:: perl

  $self->{http} = centreon::plugins::http->new(output => $self->{output}, options => $self->{options});
  $self->{http}->set_options(%{$self->{option_results}});
  my $webcontent = $self->{http}->request();
  print $webcontent;

Output displays content of the webpage '\http://google.com/'.


---
DBI
---

This library allows you to connect to databases.
To use it, add the following line at the beginning of your **plugin.pm**:

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

This is an example of how to use **connect** method.
The format of the connection string can have the following forms:
::
    DriverName:database_name
    DriverName:database_name@hostname:port
    DriverName:database=database_name;host=hostname;port=port

In plugin.pm:

.. code-block:: perl

  $self->{sqldefault}->{dbi} = ();
  $self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };

In your mode:

.. code-block:: perl

  $self->{sql} = $options{sql};
  my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);

Then, you are connected to the MySQL database.

query
-----

Description
^^^^^^^^^^^

Send query to database.

Parameters
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Parameter        |    Type         |   Default   |          Description                                    |
+===================+=================+=============+=========================================================+
| query             | String          |             | SQL query to send.                                      |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Example
^^^^^^^

This is an example of how to use **query** method:

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Slow_queries'});
  my ($name, $result) = $self->{sql}->fetchrow_array();

  print 'Name : '.$name."\n";
  print 'Value : '.$value."\n";

Output displays count of MySQL slow queries.


fetchrow_array
--------------

Description
^^^^^^^^^^^

Return Array from sql query.

Parameters
^^^^^^^^^^

None.

Example
^^^^^^^

This is an example of how to use **fetchrow_array** method:

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
  my ($dummy, $result) = $self->{sql}->fetchrow_array();

  print 'Uptime : '.$result."\n";

Output displays MySQL uptime.


fetchall_arrayref
-----------------

Description
^^^^^^^^^^^

Return Array from SQL query.

Parameters
^^^^^^^^^^

None.

Example
^^^^^^^

This is an example of how to use **fetchrow_array** method:

.. code-block:: perl

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

Output displays physical reads on Oracle database.


fetchrow_hashref
----------------

Description
^^^^^^^^^^^

Return Hash table from SQL query.

Parameters
^^^^^^^^^^

None.

Example
^^^^^^^

This is an example of how to use **fetchrow_hashref** method:

.. code-block:: perl

  $self->{sql}->query(query => q{
    SELECT datname FROM pg_database
  });

  while ((my $row = $self->{sql}->fetchrow_hashref())) {
    print $row->{datname}."\n";
  }

Output displays Postgres databases.

*****************
Complete examples
*****************

-------------------
Simple SNMP request
-------------------

Description
-----------

| This example explains how to check a single SNMP value on a PfSense firewall (memory dropped packets).
| We use cache file because it's a SNMP counter. So we need to get the value between 2 checks.
| We get the value and compare it to warning and critical thresholds.

Plugin file
-----------

First, create the plugin directory and the plugin file:
::

  $ mkdir -p apps/pfsense/snmp
  $ touch apps/pfsense/snmp/plugin.pm

.. tip::
  PfSense is a firewall application and we check it using SNMP protocol

Then, edit **plugin.pm** and add the following lines:

.. code-block:: perl

  #
  # Copyright 2018 Centreon (http://www.centreon.com/)
  #
  # Centreon is a full-fledged industry-strength solution that meets
  # the needs in IT infrastructure and application monitoring for
  # service performance.
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  #       http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
  #

  # Path to the plugin
  package apps::pfsense::snmp::plugin;

  # Needed libraries
  use strict;
  use warnings;
  # Use this library to check using SNMP protocol
  use base qw(centreon::plugins::script_snmp);

.. tip::
  Don't forget to edit 'Authors' line.

Add **new** method to instantiate the plugin:

.. code-block:: perl

  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    # Plugin version
    $self->{version} = '0.1';

    # Modes association
    %{$self->{modes}} = (
                         # Mode name => path to the mode
                         'memory-dropped-packets'   => 'apps::pfsense::snmp::mode::memorydroppedpackets',
                         );

    return $self;
  }

Declare this plugin as a perl module:

.. code-block:: perl

  1;

Add a description to the plugin:

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  Check pfSense in SNMP.

  =cut

.. tip::

  This description is printed with '--help' option.


Mode file
---------

Then, create the mode directory and the mode file:
::

  $ mkdir apps/pfsense/snmp/mode
  $ touch apps/pfsense/snmp/mode/memorydroppedpackets.pm

Edit **memorydroppedpackets.pm** and add the following lines:

.. code-block:: perl

  #
  # Copyright 2018 Centreon (http://www.centreon.com/)
  #
  # Centreon is a full-fledged industry-strength solution that meets
  # the needs in IT infrastructure and application monitoring for
  # service performance.
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  #     http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
  #

  # Path to the plugin
  package apps::pfsense::snmp::mode::memorydroppedpackets;

  # Needed library for modes
  use base qw(centreon::plugins::mode);

  # Needed libraries
  use strict;
  use warnings;

  # Custom library
  use POSIX;

  # Needed library to use cache file
  use centreon::plugins::statefile;

Add **new** method to instantiate the mode:

.. code-block:: perl

  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # Mode version
    $self->{version} = '1.0';

    # Declare options
    $options{options}->add_options(arguments =>
                                {
                                  # option name        => variable name
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                });

    # Instantiate cache file
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
  }

.. tip::

  A default value can be added to options.
  Example : "warning:s" => { name => 'warning', default => '80'},

Add **check_options** method to validate options:

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Validate threshold options with threshold_validate method
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    # Validate cache file options using check_options method of statefile library
    $self->{statefile_value}->check_options(%options);
  }

Add **run** method to execute mode:

.. code-block:: perl

  sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object

    # Get SNMP options
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    # SNMP oid to request
    my $oid_pfsenseMemDropPackets = '.1.3.6.1.4.1.12325.1.200.1.2.6.0';
    my ($result, $value);

    # Get SNMP value for oid previsouly defined
    $result = $self->{snmp}->get_leef(oids => [ $oid_pfsenseMemDropPackets ], nothing_quit => 1);
    # $result is a hash table where keys are oids
    $value = $result->{$oid_pfsenseMemDropPackets};

    # Read the cache file
    $self->{statefile_value}->read(statefile => 'pfsense_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    # Get cache file values
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_memDropPackets = $self->{statefile_value}->get(name => 'memDropPackets');

    # Create a hash table with new values that will be write to cache file
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{memDropPackets} = $value;

    # Write new values to cache file
    $self->{statefile_value}->write(data => $new_datas);

    # If cache file didn't have any values, create it and wait another check to calculate value
    if (!defined($old_timestamp) || !defined($old_memDropPackets)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Fix when PfSense reboot (snmp counters initialize to 0)
    $old_memDropPackets = 0 if ($old_memDropPackets > $new_datas->{memDropPackets});

    # Calculate time between 2 checks
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    # Calculate value per second
    my $memDropPacketsPerSec = ($new_datas->{memDropPackets} - $old_memDropPackets) / $delta_time;

    # Calculate exit code by comparing value to thresholds
    # Exit code can be : 'OK', 'WARNING', 'CRITICAL', 'UNKNOWN'
    my $exit_code = $self->{perfdata}->threshold_check(value => $memDropPacketsPerSec,
                                                       threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    # Add a performance data
    $self->{output}->perfdata_add(label => 'dropped_packets_Per_Sec',
                                  value => sprintf("%.2f", $memDropPacketsPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    # Add output
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Dropped packets due to memory limitations : %.2f /s",
                                    $memDropPacketsPerSec));

    # Display output
    $self->{output}->display();
    $self->{output}->exit();
  }

Declare this plugin as a perl module:

.. code-block:: perl

  1;

Add a description of the mode options:

.. code-block:: perl

  __END__

  =head1 MODE

  Check number of packets per second dropped due to memory limitations.

  =over 8

  =item B<--warning>

  Threshold warning for dropped packets in packets per second.

  =item B<--critical>

  Threshold critical for dropped packets in packets per second.

  =back

  =cut


Command line
------------

This is an example of command line:
::

  $ perl centreon_plugins.pl --plugin apps::pfsense::snmp::plugin --mode memory-dropped-packets --hostname 192.168.0.1 --snmp-community 'public' --snmp-version '2c' --warning '1' --critical '2'

Output may display:
::

  OK: Dropped packets due to memory limitations : 0.00 /s | dropped_packets_Per_Sec=0.00;0;;1;2


.. _code_style_guidelines:

*********************
Code Style Guidelines
*********************

------------
Introduction
------------

Perl code from Pull-request must conform to the following style guidelines. If you find any code which doesn't conform, please fix it.

-----------
Indentation
-----------

Space should be used to indent all code blocks. Tabs should never be used to indent code blocks. Mixing tabs and spaces results in misaligned code blocks for other developers who prefer different indentation settings.
Please use 4 for indentation space width.

.. code-block:: perl

    if ($1 > 1) {
    ....return 1;
    } else {
        if ($i == -1) {
        ....return 0;
        }
        return -1
    }

--------
Comments
--------

There should always be at least 1 space between the # character and the beginning of the comment.  This makes it a little easier to read multi-line comments:

.. code-block:: perl

    # Good comment
    #Wrong comment

---------------------------
Subroutine & Variable Names
---------------------------

Whenever possible, use underscore to seperator words and don't use uppercase characters:

.. code-block:: perl

    sub get_logs {}
    my $start_time;

Keys of hash table should be used alphanumeric and underscore characters only (and no quote!):

.. code-block:: perl

    $dogs->{meapolitan_mastiff} = 10;

---------------------------
Curly Brackets, Parenthesis
---------------------------

There should be a space between every control/loop keyword and the opening parenthesis:

.. code-block:: perl

    if ($i == 1) {
        ...
    }
    while ($i == 2) {
        ...
    }
    
------------------
If/Else Statements
------------------

'else', 'elsif' should be on the same line after the previous closing curly brace:

.. code-block:: perl

    if ($i == 1) {
        ...
    } else {
        ...
    }

You can use single line if conditional:

.. code-block:: perl

    next if ($i == 1);


.. _model_classes_usage:

*******************
Model Classes Usage
*******************

------------
Introduction
------------

With the experience of plugin development, we have created two classes:

* centreon::plugins::templates::counter
* centreon::plugins::templates::hardware

It was developed to have a more consistent code and less redundant code. According to context, you should use one of two classes for modes. 
Following classes can be used for whatever plugin type (SNMP, Custom, DBI,...).

-------------
Class counter
-------------

When to use it ?
----------------

If you have some counters (CPU Usage, Memory, Session...), you should use that class.
If you have only one global counter to check, it's maybe not useful to use it (but only for these case).

Class methods
-------------

List of methods:

* **new**: class constructor. Overload if you need to add some specific options or to use a statefile.
* **check_options**: overload if you need to check your specific options.
* **manage_selection**: overload if *mandatory*. Method to get informations for the equipment.
* **set_counters**: overload if **mandatory**. Method to configure counters.

Examples
--------

Example 1
^^^^^^^^^

We want to develop the following SNMP plugin:

* measure the current sessions and current SSL sessions usages.

.. code-block:: perl

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


Output may display:
::

  OK: Current sessions : 24 - Current ssl sessions : 150 | sessions=24;;;0; sessions_ssl=150;;;0;

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

Example 2
^^^^^^^^^

We want to add the current number of sessions by virtual servers.

.. code-block:: perl

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

If we have at least 2 virtual servers:
::

  OK: Total current sessions : 24, current ssl sessions : 150 - All Virtual servers are ok | total_sessions=24;;;0; total_sessions_ssl=150;;;0; sessions_foo1=11;;;0; sessions_ssl_foo1=70;;;0; sessions_foo2=13;;;0; sessions_ssl_foo2=80;;;0;
  Virtual server 'foo1' current sessions : 11, current ssl sessions : 70
  Virtual server 'foo2' current sessions : 13, current ssl sessions : 80

Example 3
^^^^^^^^^

The model can also be used to check strings (not only counters). So we want to check the status of a virtualserver.

.. code-block:: perl

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


The following example show 4 new attributes:

* *closure_custom_calc*: should be used to do more complex calculation.
* *closure_custom_output*: should be used to have a more complex output (An example: want to display the total, free and used value at the same time).
* *closure_custom_perfdata*: should be used to manage yourself the perfdata.
* *closure_custom_threshold_check*: should be used to manage yourself the threshold check.


--------------
Class hardware
--------------

TODO
