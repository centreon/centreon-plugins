***********
Description
***********

Ce document présente les bonnes pratiques pour le développement de "centreon-plugins".
Comme tous les plugins sont écrits en Perl, “il y plus d'une façon de faire”.
Mais pour ne pas réinventer la roue, vous devirez d'abord regarder le dossier “example”, vous aurez alors un aperçu de comment construire votre propre plugin ainsi que ses modes associés.

La dernière version est disponible sur le dépôt git suivant: http://git.centreon.com/centreon-plugins.git

***********
Quick Start
***********

-------------------
Création du dossier
-------------------

Premièrement, vous avez besoin de créer un dossier sur le git afin de stocker le nouveau plugin.

Les répertoires racines sont oganisés par catégorie:

* Application            : apps
* Base de données        : database
* Matériel               : hardware
* Equipement réseau      : network
* Système d'exploitation : os
* Equipement de stockage : storage

Selon l'objet supervisé, il existe une organisation qui peut utiliser:

* Type
* Constructeur
* Modèle
* Protocole de supervision

Par exemple, si vous voulez ajouter un plugin pour superviser Linux par SNMP, you devez créer ce dossier:
::

  $ mkdir -p os/linux/snmp

You avez également besoin de créer une répertoire "mode" pour les futurs modes créés:
::

  $ mkdir os/linux/snmp/mode

------------------
Création du plugin
------------------

Une fois le dossier créé, créez le fichier du plugin à l'intérieur de celui-ci:
::

  $ touch plugin.pm

Ensuite, éditez plugin.pm pour ajouter les **conditions de licence** en les copiant à partir d'un autre plugin. N'oubliez pas d'ajouter votre nom à la fin de celles-ci:

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Renseigner votre nom de **package** : il correspond au dossier de votre plugin.

.. code-block:: perl

  package path::to::plugin;

Déclarez les bibliothèques utilisés (**strict** et **warnings** sont obligatoires). Les bibliothèque Centreon sont décrites par la suite :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(**centreon_library**);

Le plugin a besoin d'un constructeur **new** pour instancier l'objet:

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;
        
        ...
        
        return $self;
  }

La version du plugin doit être déclarée dans le constructeur **new**:

.. code-block:: perl

  $self->{version} = '0.1';

Plusieurs mode peuvent être déclarés dans le constructeur **new**:

.. code-block:: perl

  %{$self->{modes}} = (
                        'mode1'    => '<plugin_path>::mode::mode1',
                        'mode2'    => '<plugin_path>::mode::mode2',
                        ...
                        );

Ensuite, déclarez le module:

.. code-block:: perl

  1;

Une description du plugin est nécessaire pour générer la documentation:

.. code-block:: perl

  __END__
  
  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.
  
  =cut


.. tip::
  you can copy-paste an other plugin.pm and adapt some lines (package, arguments...).

.. tip::
  plugin has ".pm" extension because it's a perl module. So don't forget to add **1;** at the end of the file

----------------
Création du mode
----------------

Une fois que **plugin.pm** est créé et que ses modes sont déclarés, créez les modes dans le dossier **mode**:
::

  cd mode
  touch mode1.pm

Ensuite, éditez mode1.pm pour ajouter les **conditions de licence** en les copiant à partir d'un autre mode. N'oubliez pas d'ajouter votre nom à la fin de celles-ci:

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Décrivez votre nom de **package** : il correspond au dossier de votre mode.

.. code-block:: perl

  package path::to::plugin::mode::mode1;

Déclarez les bibliothèques utilisées (toujours les mêmes) :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

Le mode nécessite un constructeur **new** pour instancier l'objet:

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

La version du mode doit être déclaré dans le constructeur **new**:

.. code-block:: perl

  $self->{version} = '1.0';

Plusieurs options peuvent être déclarées dans le constructeur **new**:

.. code-block:: perl

  $options{options}->add_options(arguments =>
                                {
                                  "option1:s" => { name => 'option1' },
                                  "option2:s" => { name => 'option2', default => 'value1' },
                                  "option3"   => { name => 'option3' },
                                });

Voici la description des arguments de cet exemple:

* option1 : Chaîne de caractères
* option2 : Chaîne de caractères avec "value1" comme valeur par défaut
* option3 : Booléen

.. tip::
  Vous pouvez obtenir plus d'informations sur les format des options ici : http://perldoc.perl.org/Getopt/Long.html

Le mode nécessite une méthode **check_options** pour valider les options:

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

Par exemple, les seuils dégradé et critique doivent être validés dans la méthode **check_options**:

.. code-block:: perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
  }

Dans cet exemple, l'aide est affichée si les seuils spécifiés ne sont pas au bon format.

Ensuite vient la méthode **run**, où vous effectuez le traitement, vérifiez les seuils, affichez le message de sortie et les données de performance.
Voici un exemple pour vérifier une valeur snmp:

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

Dans cet exemple, nous vérifions un OID snmp que nous comparons aux seuils dégradé et critique.
Voici les méthodes que nous utilisons:

* get_leef        : obtient une valeur snmp à partir d'un OID
* threshold_check : compare une valeur snmp à des seuils dégradé et critique
* output_add      : ajoute des informations au message de sortie
* perfdata_add    : ajout des données de performance au message de sortie
* display         : affiche le message de sortie
* exit            : sort du programme

Ensuite, déclarez le module:

.. code-block:: perl

  1;

Une description du mode et ses arguments est nécessaire pour générer la documentation:

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut

--------------
Commit et push
--------------

Avant de commiter le plugin, you devez créer un **ticket amélioration** dans le forge centreon-plugins : http://forge.centreon.com/projects/centreon-plugins

Une fois que le plugin et ses modes sont développés, vous pouvez commiter et pusher votre travail:
::

  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push

*****************************
Référentiel des bibliothèques
*****************************

Ce chapitre décrit les bibliothèques centreon qui peuvent être utilisés dans votre développement.

------
Output
------

Cette bibliothèque vous permet de modifier la sortie de votre plugin.

output_add
----------

Description
^^^^^^^^^^^

Ajoute une chaîne de caractères à la sortie (affichée avec la méthode **display**).
Si le statut est différent de 'ok', le message de sortie associé à 'ok' n'est pas affiché.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                          |
+=================+=================+=============+===============================================================+
| severity        | String          |    OK       | Statut du message de sortie.                                  |
+-----------------+-----------------+-------------+---------------------------------------------------------------+
| separator       | String          |    \-       | Séparateur entre le statut et le message de sortie            |
+-----------------+-----------------+-------------+---------------------------------------------------------------+
| short_msg       | String          |             | Message de sortie court (première ligne).                     |
+-----------------+-----------------+-------------+---------------------------------------------------------------+
| long_msg        | String          |             | Message de sortie long (utilisé avec l'option ``--verbose``). |
+-----------------+-----------------+-------------+---------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple de gestion de la sortie du plugin:

.. code-block:: perl

  $self->{output}->output_add(severity  => 'OK',
                              short_msg => 'All is ok');
  $self->{output}->output_add(severity  => 'Critical',
                              short_msg => 'There is a critical problem');
  $self->{output}->output_add(long_msg  => 'Port 1 is disconnected');

  $self->{output}->display();

La sortie affiche:
::

  CRITICAL - There is a critical problem
  Port 1 is disconnected


perfdata_add
------------

Description
^^^^^^^^^^^

Ajouter une donnée de performance à la sortie (affichée avec la méthode **display**).
Les données de performance sont affichées après le symbol '|'.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| label           | String          |             | Label de la donnée de performance.                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| value           | Int             |             | Valeur de la donnée de performance.                     |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| unit            | String          |             | Unité de la donnée de performance.                      |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| warning         | String          |             | Seuil dégradé.                                          |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| critical        | String          |             | Seuil critique.                                         |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| min             | Int             |             | Valeur minimum de la donnée de performance.             |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| max             | Int             |             | Valeur maximum de la donnée de performance.             |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'ajout d'une donnée de performance :

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

La sortie affiche :
::

  OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000


-------
Perdata
-------

Cette bibliothèque vous permet de gérer les données de performance.

get_perfdata_for_output
-----------------------

Description
^^^^^^^^^^^

Gère les seuils des données de performance pour la sortie.

Parameters
^^^^^^^^^^

+-----------------+-----------------+-------------+--------------------------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                                     |
+=================+=================+=============+==========================================================================+
| **label**       | String          |             | Label du seuil.                                                          |
+-----------------+-----------------+-------------+--------------------------------------------------------------------------+
| total           | Int             |             | Seuil en pourcentage à transformer en valeur globale.                    |
+-----------------+-----------------+-------------+--------------------------------------------------------------------------+
| cast_int        | Int (0 or 1)    |             | Cast une valeur absolue en entier.                                       |
+-----------------+-----------------+-------------+--------------------------------------------------------------------------+
| op              | String          |             | Opérateur à appliquer à la valeur de début/fin (utilisé avec ``value``). |
+-----------------+-----------------+-------------+--------------------------------------------------------------------------+
| value           | Int             |             | Valeur à appliquer avec l'option ``op``.                                 |
+-----------------+-----------------+-------------+--------------------------------------------------------------------------+


Exemple
^^^^^^^

Voici un exemple de gestion des données de performance pour la sortie:

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
  Dans cet exemple, au lieu d'afficher les seuils dégradé et critique en 'pourcentage', la fonction calcule et affiche celle-ci en 'bytes'.

threshold_validate
------------------

Description
^^^^^^^^^^^

Valide et associe un seuil à un label.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| label           | String          |             | Label du seuil.                                         |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| value           | String          |             | Valeur du seuil.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple vérifiant si le seuil dégradé est correct:

.. code-block:: perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
    $self->{output}->option_exit();
  }

.. tip::
  Vous pouvez voir les bon format de seuil ici : https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

threshold_check
---------------

Description
^^^^^^^^^^^

Vérifie la valeur d'une donnée de performance avec un seuil pour déterminer son statut.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+-------------------------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                                    |
+=================+=================+=============+=========================================================================+
| value           | Int             |             | Valeur de la donnée de performance à comparer.                          |
+-----------------+-----------------+-------------+-------------------------------------------------------------------------+
| threshold       | String array    |             | Label du seuil à comparer et statut de sortie si celui-ci est atteint.  |
+-----------------+-----------------+-------------+-------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple vérifiant si une donnée de performance a atteint certains seuils :

.. code-block:: perl

  $self->{perfdata}->threshold_validate(label => 'warning', value => 80);
  $self->{perfdata}->threshold_validate(label => 'critical', value => 90);
  my $prct_used = 85;

  my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

  $self->{output}->output_add(severity  => $exit,
                              short_msg => sprint("Used memory is %i%%", $prct_used));  
  $self->{output}->display();

La sortie affiche :
::

  WARNING - Used memory is 85% |

change_bytes
------------

Description
^^^^^^^^^^^

Convertie des bytes en unité de mesure lisible.
Retourne une valeur et une unité.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| value           | Int             |             | Valeur de données de performance à convertir.           |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| network         |                 | 1024        | Unité de division (1000 si définie).                    |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple de conversion des bytes en unité de mesure lisible:

.. code-block:: perl

  my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

  print $value.' '.$unit."\n";

La sortie affiche:
::

  100 KB

----
Snmp
----

Cette bibliothèque vous permet d'utiliser le protocole snmp dans votre plugin.
Pour l'utiliser, vous devez ajouter la ligne suivant au début de votre **plugin.pm**:

.. code-block:: perl

  use base qw(centreon::plugins::script_snmp);


get_leef
--------

Description
^^^^^^^^^^^

Retourne une table de hashage de valeurs SNMP pour plusieurs OIDs (ne fonctionne pas avec les tables SNMP).

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+----------------------------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                                       |
+=================+=================+=============+============================================================================+
| **oids**        | String array    |             | Tableau d'OIDs à contrôler (Peut être spécifier avec la méthode ``load``). |
+-----------------+-----------------+-------------+----------------------------------------------------------------------------+
| dont_quit       | Int (0 or 1)    |     0       | Ne quitte pas même si une erreur snmp se produit.                          |
+-----------------+-----------------+-------------+----------------------------------------------------------------------------+
| nothing_quit    | Int (0 or 1)    |     0       | Quitte si aucune valeur n'est retournée.                                   |
+-----------------+-----------------+-------------+----------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour obtenir 2 valeurs snmp:

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

Charge une liste d'oids à utiliser avec la méthode **get_leef**.

Paramètres
^^^^^^^^^^

+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
|  Paramètre      |        Type          |   Défaut     |          Description                                                       |
+=================+======================+==============+============================================================================+
| **oids**        |  String array        |              | Tableau d'OIDs à vérifier.                                                 |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
| instances       |  Int array           |              | Tableau d'instances d'OIDs à vérifier.                                     |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
| instance_regexp |  String              |              | Expression régulière pour obtenir les instances de l'option **instances**. |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
| begin           |  Int                 |              | Instance de début                                                          |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
| end             |  Int                 |              | Instance to fin                                                            |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour obtenir les 4 premières instances d'une table snmp en utilisant la méthode **load**:

.. code-block:: perl

  my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

  $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

  my $result = $self->{snmp}->get_leef(nothing_quit => 1);

  use Data::Dumper;
  print Dumper($result);

Voici un exemple pour obtenir plusieurs instances dynamiquement (modules mémoire de matériel Dell) en utilisant la méthode **load**:

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

Retourne une table de hashage de valeurs SNMP pour une table SNMP.

Paramètres
^^^^^^^^^^

+-----------------+----------------------+----------------+-----------------------------------------------------------------+
|  Paramètre      |        Type          |   Défaut       |          Description                                            |
+=================+======================+================+=================================================================+
| **oid**         |  String              |                | OID de la talbe SNMP à récupérer.                               |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| start           |  Int                 |                | Premier OID à récupérer.                                        |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| end             |  Int                 |                | Dernier OID à récupérer.                                        |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Ne quitte pas même si une erreur snmp se produit.               |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quitte si aucune valeur n'est retournée.                        |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Retourne une table de hashage à un niveau au lieu de plusieurs. |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour obtenir une table snmp:

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

Retourne une table de hashage de valeurs SNMP pour plusieurs tables SNMP.

Paramètres
^^^^^^^^^^

+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
|  Paramètre      |        Type          |   Défaut       |          Description                                                                  |
+=================+======================+================+=======================================================================================+
| **oids**        |  Hash table          |                | Table de hashage des OIDs à récupérer (Peut être spécifié avec la méthode ``load``).  |
|                 |                      |                | Les clés peuvent être : "oid", "start", "end".                                        |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Ne quitte pas même si une erreur snmp se produit.                                     |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quitte si aucune valeur n'est retournée.                                              |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Retourne une table de hashage à un niveau au lieu de plusieurs.                       |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour obtenir 2 tables snmp:

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

Récupère le nom d'hôte en paramètre (utile pour obtenir le nom d'hôte dans un mode).

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple pour obtenir le nom d'hôte en paramètre:

.. code-block:: perl

  my $hostname = $self->{snmp}->get_hostname();


get_port
--------

Description
^^^^^^^^^^^

Récupère le port en paramètre (utile pour obtenir le port dans un mode).

Parameters
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple pour obtenir le port en paramètre:

.. code-block:: perl

  my $port = $self->{snmp}->get_port();


oid_lex_sort
------------

Description
^^^^^^^^^^^

Retourne des OIDs triés.

Paramètres
^^^^^^^^^^

+-----------------+-------------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type           |   Défaut    |          Description                                    |
+=================+===================+=============+=========================================================+
| **-**           |  String array     |             | Tableau d'OIDs à trier.                                 |
+-----------------+-------------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Cet exemple afiche des OIDs triés:

.. code-block:: perl

  foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
    print $oid;
  }


----
Misc
----

Cette bibliothèque fournit un ensemble de méthodes diverses.
Pour l'utiliser, vous pouvez directement utiliser le chemin de la méthode:

.. code-block:: perl

  centreon::plugins::misc::<my_method>;


trim
----

Description
^^^^^^^^^^^

Enlève les espaces de début et de fin d'une chaîne de caractères.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | String          |             | String to strip.                                        |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **trim**:

.. code-block:: perl

  my $word = '  Hello world !  ';
  my $trim_word =  centreon::plugins::misc::trim($word);

  print $word."\n";
  print $trim_word."\n";

La sortie affiche:
::

    Hello world !  
  Hello world !


change_seconds
--------------

Description
^^^^^^^^^^^

Convertie des secondes en unité de mesure lisible.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | Int             |             | Nombre de secondes à convertir.                         |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **change_seconds**:

.. code-block:: perl

  my $seconds = 3750;
  my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

  print 'Human readable time : '.$human_readable_time."\n";

La sortie affiche:
::

  Human readable time : 1h 2m 30s


backtick
--------

Description
^^^^^^^^^^^

Exécute une commande système.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| **command**     | String          |             | Commande à exécuter.                                    |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| arguments       | String array    |             | Arguments de la commande.                               |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| timeout         | Int             |     30      | Timeout de la commande.                                 |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| wait_exit       | Int (0 or 1)    |     0       | Le processus de la commande ignore les signaux SIGCHLD. |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| redirect_stderr | Int (0 or 1)    |     0       | Affiche les erreurs dans la sortie.                     |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **backtick**:

.. code-block:: perl

  my ($error, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                      command => 'ls /home',
                                      timeout => 5,
                                      wait_exit => 1
                                      );

  print $stdout."\n";

La sortie affiche les fichiers du répertoire '/home'.


execute
-------

Description
^^^^^^^^^^^

Exécute une commande à distance.

Paramètres
^^^^^^^^^^

+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
|  Paramètre       |    Type         |   Défaut    |          Description                                                                               |
+==================+=================+=============+====================================================================================================+
| **output**       | Object          |             | Sortie du plugin ($self->{output}).                                                                |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| **options**      | Object          |             | Options du plugin ($self->{option_results}) pour obtenir les informations de connexion à distance. |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| sudo             | String          |             | Utilise la commande sudo.                                                                          |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| **command**      | String          |             | Commande à exécuter.                                                                               |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| command_path     | String          |             | Chemin de la commande.                                                                             |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| command_options  | String          |             | Arguments de la commande.                                                                          |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **execute**.
Nous supposons que l'option ``--remote`` est activée:

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

Exécute une commande sur Windows.

Paramètres
^^^^^^^^^^

+------------------+-----------------+-------------+-----------------------------------------------------------------+
|  Paramètre       |    Type         |   Défaut    |          Description                                            |
+==================+=================+=============+=================================================================+
| **output**       | Object          |             | Sortie du plugin ($self->{output}).                             |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| **command**      | String          |             | Command à exécuter.                                             |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_path     | String          |             | Chemin de la commande.                                          |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_options  | String          |             | Arguments de la commande.                                       |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| timeout          | Int             |             | Timeout de la commande.                                         |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| no_quit          | Int             |             | Ne quitte pas même si une erreur snmp se produit.               |
+------------------+-----------------+-------------+-----------------------------------------------------------------+


Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **windows_execute**.

.. code-block:: perl

  my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                        timeout => 10,
                                                        command => 'ipconfig',
                                                        command_path => '',
                                                        command_options => '/all');

La sortie affiche la configuration ip d'un hôte Windows.


---------
Statefile
---------

Cette bibliothèque fournit un ensemble de méthodes pour utiliser un fichier de cache.
Pour l'utiliser, ajoutez la ligne suivante au début de votre **mode**:

.. code-block:: perl

  use centreon::plugins::statefile;


read
----

Description
^^^^^^^^^^^

Lit un fichier de cache.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| **statefile**     | String          |             | Nom du fichier de cache.                                |
+-------------------+-----------------+-------------+---------------------------------------------------------+
| **statefile_dir** | String          |             | Répertoire du fichier de cache.                         |
+-------------------+-----------------+-------------+---------------------------------------------------------+
| memcached         | String          |             | Serveur memcached à utiliser.                           |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **read**:

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  use Data::Dumper;
  print Dumper($self->{statefile_value});

La sortie affiche le fichier de cache et ses paramètres.


get
---

Description
^^^^^^^^^^^

Récupérer les données d'un fichier de cache.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| name              | String          |             | Récupére une valeur du fichier de cache.                |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **get**:

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $value = $self->{statefile_value}->get(name => 'property1');
  print $value."\n";

La sortie affiche la valeur associée à 'property1' du fichier de cache.


write
-----

Description
^^^^^^^^^^^

Ecris des données dans le fichier de cache.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| data              | String          |             | Données à écrire dans le fichier de cache.              |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **write**:

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $new_datas = {};
  $new_datas->{last_timestamp} = time();
  $self->{statefile_value}->write(data => $new_datas);

Ensuite, vous pouvez jeter un oeil dans le fichier '/var/lib/centreon/centplugins/my_cache_file', le timestamp y est écris.


----
Http
----

Cette bibliothèque fournit un ensemble de méthodes pour utiliser le protocole HTTP.
Pour l'utiliser, ajoutez la ligne suivante au début de votre **mode**:

.. code-block:: perl

  use centreon::plugins::httplib;

Certaines options doivent être spécifiées dans **plugin.pm**:

+-----------------+-----------------+----------------------------------------------------------------------+
|  Option         |    Type         |          Description                                                 |
+=================+=================+======================================================================+
| **hostname**    | String          | Adresse IP/FQDN du serveur web.                                      |
+-----------------+-----------------+----------------------------------------------------------------------+
| **port**        | String          | Port HTTP.                                                           |
+-----------------+-----------------+----------------------------------------------------------------------+
| **proto**       | String          | Protocole utilisé ('http' ou 'https').                               |
+-----------------+-----------------+----------------------------------------------------------------------+
| credentials     |                 | Utilise les informations d'authentification.                         | 
+-----------------+-----------------+----------------------------------------------------------------------+
| ntlm            |                 | Utilise l'authentification NTLM (si ``--credentials`` est utilisée). |
+-----------------+-----------------+----------------------------------------------------------------------+
| username        | String          | Nom d'utilisateur (si ``--credentials`` est utilisée).               |
+-----------------+-----------------+----------------------------------------------------------------------+
| password        | String          | Mot de passe (si ``--credentials`` est utilisée).                    |
+-----------------+-----------------+----------------------------------------------------------------------+
| proxyurl        | String          | Proxy à utiliser.                                                    |
+-----------------+-----------------+----------------------------------------------------------------------+
| url_path        | String          | URL à se connecter (commence par '/').                               |
+-----------------+-----------------+----------------------------------------------------------------------+

connect
-------

Description
^^^^^^^^^^^

Teste la connection vers une url http.
Retourne le contenu de la page web.

Paramètres
^^^^^^^^^^

Cette méthode utilise les options du plugin précédemment définies.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **connect**.
Nous supposons que ces options sont définies:
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

.. code-block:: perl

  my $webcontent = centreon::plugins::httplib::connect($self);
  print $webcontent;

La sortie affiche le contenu de la page web '\http://google.com/'.


---
Dbi
---

Cette bibliothèque vous permet de vous connecter à une ou plusieurs bases de données.
Pour l'utiliser, ajoutez la ligne suivante au début de votre **plugin.pm**:

.. code-block:: perl

  use base qw(centreon::plugins::script_sql);

connect
-------

Description
^^^^^^^^^^^

Se connecter à une ou plusieurs bases de données.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| dontquit          | Int (0 or 1)    |     0       | Ne quitte pas même si une erreur snmp se produit.       |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **connect**.

Dans plugin.pm:

.. code-block:: perl

  $self->{sqldefault}->{dbi} = ();
  $self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };

Dans votre mode mode :

.. code-block:: perl

  $self->{sql} = $options{sql};
  my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);

Vous êtes alors connecté à la base de données MySQL.

query
-----

Description
^^^^^^^^^^^

Exécute une requête sql sur la base de données.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| query             | String          |             | Requête SQL à exécuter.                                 |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **query**:

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Slow_queries'});
  my ($name, $result) = $self->{sql}->fetchrow_array();
  
  print 'Name : '.$name."\n";
  print 'Value : '.$value."\n";

La sortie affiche le nombre de requêtes MySQL lentes.


fetchrow_array
--------------

Description
^^^^^^^^^^^

Retourne une tableau à partir d'une requête sql.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_array**:

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
  my ($dummy, $result) = $self->{sql}->fetchrow_array();

  print 'Uptime : '.$result."\n";

La sortie affiche l'uptime MySQL.


fetchall_arrayref
-----------------

Description
^^^^^^^^^^^

Retourne un tableau à partir d'une requête sql.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_array**:

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

La sortie affiche les lectures physiques sur une base de données Oracle.


fetchrow_hashref
----------------

Description
^^^^^^^^^^^

Retourne une table de hashage à partir d'une requête sql.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_hashref**:

.. code-block:: perl

  $self->{sql}->query(query => q{
    SELECT datname FROM pg_database
  });

  while ((my $row = $self->{sql}->fetchrow_hashref())) {
    print $row->{datname}."\n";
  }

La sortie affiche la liste des base de données Postgres.


*****************
Exemples complets
*****************

-------------------
Requête SNMP simple
-------------------

Description
-----------

| Cet exemple explique comment vérifier une valeur SNMP unique sur un pare-feu PfSense (paquets supprimés pour cause de surcharge mémoire).
| Nous utilisons un fiçhier de cache car c'est un compteur SNMP. Nous avons donc besoin d'obtenir la valuer différentielle en tre 2 contrôles.
| Nous récupérons la valeur et la comparons aux seuils dégradé et critique.

Fichier du plugin
-----------------

Tout d'abord, créez le dossier du plugin, ainsi que le fichier du plugin:
::

  $ mkdir -p apps/pfsense/snmp
  $ touch apps/pfsense/snmp/plugin.pm

.. tip::
  PfSense est un pare-feu applicatif et nous le contrôlons en utilisant le protocole SNMP

Ensuite, éditez **plugin.pm** et ajoutez les lignes suivantes:

.. code-block:: perl

  ################################################################################
  # Copyright 2005-2014 MERETHIS
  # Centreon is developped by : Julien Mathis and Romain Le Merlus under
  # GPL Licence 2.0.
  #
  # This program is free software; you can redistribute it and/or modify it under
  # the terms of the GNU General Public License as published by the Free Software
  # Foundation ; either version 2 of the License.
  #
  # This program is distributed in the hope that it will be useful, but WITHOUT ANY
  # WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
  # PARTICULAR PURPOSE. See the GNU General Public License for more details.
  #
  # You should have received a copy of the GNU General Public License along with
  # this program; if not, see <http://www.gnu.org/licenses>.
  #
  # Linking this program statically or dynamically with other modules is making a
  # combined work based on this program. Thus, the terms and conditions of the GNU
  # General Public License cover the whole combination.
  #
  # As a special exception, the copyright holders of this program give MERETHIS
  # permission to link this program with independent modules to produce an executable,
  # regardless of the license terms of these independent modules, and to copy and
  # distribute the resulting executable under terms of MERETHIS choice, provided that
  # MERETHIS also meet, for each linked independent module, the terms  and conditions
  # of the license of that module. An independent module is a module which is not
  # derived from this program. If you modify this program, you may extend this
  # exception to your version of the program, but you are not obliged to do so. If you
  # do not wish to do so, delete this exception statement from your version.
  #
  # For more information : contact@centreon.com
  # Authors : your name <your@mail>
  #
  ####################################################################################

  # Chemin vers le plugin
  package apps::pfsense::snmp::plugin;

  # Bibliothèques nécessaires
  use strict;
  use warnings;
  # Utiliser cette bibliothèque pour contrôle en utilisant le protocole SNMP
  use base qw(centreon::plugins::script_snmp);

.. tip::
  N'oubliez pas de modifier la ligne 'Authors'.

Ajoutez la méthode **new** pour instancier le plugin:

.. code-block:: perl

  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    # Version du plugin
    $self->{version} = '0.1';

    # Association des modes
    %{$self->{modes}} = (
                         # Nom du mode => Chemin vers le mode
                         'memory-dropped-packets'   => 'apps::pfsense::snmp::mode::memorydroppedpackets',
                         );

    return $self;
  }

Déclarez ce plugin en tant que module perl:

.. code-block:: perl

  1;

Ajoutez une description au plugin:

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  Check pfSense in SNMP.

  =cut

.. tip::

  Cette description est affichée avec l'option ``--help``.


Fichier du mode
---------------

Ensuite, créez le répertoire du mode, ainsi que le fichier du mode:
::

  $ mkdir apps/pfsense/snmp/mode
  $ touch apps/pfsense/snmp/mode/memorydroppedpackets.pm

Editez **memorydroppedpackets.pm** et ajoutez les lignes suivantes:

.. code-block:: perl

  ################################################################################
  # Copyright 2005-2014 MERETHIS
  # Centreon is developped by : Julien Mathis and Romain Le Merlus under
  # GPL Licence 2.0.
  #
  # This program is free software; you can redistribute it and/or modify it under
  # the terms of the GNU General Public License as published by the Free Software
  # Foundation ; either version 2 of the License.
  #
  # This program is distributed in the hope that it will be useful, but WITHOUT ANY
  # WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
  # PARTICULAR PURPOSE. See the GNU General Public License for more details.
  #
  # You should have received a copy of the GNU General Public License along with
  # this program; if not, see <http://www.gnu.org/licenses>.
  #
  # Linking this program statically or dynamically with other modules is making a
  # combined work based on this program. Thus, the terms and conditions of the GNU
  # General Public License cover the whole combination.
  #
  # As a special exception, the copyright holders of this program give MERETHIS
  # permission to link this program with independent modules to produce an executable,
  # regardless of the license terms of these independent modules, and to copy and
  # distribute the resulting executable under terms of MERETHIS choice, provided that
  # MERETHIS also meet, for each linked independent module, the terms  and conditions
  # of the license of that module. An independent module is a module which is not
  # derived from this program. If you modify this program, you may extend this
  # exception to your version of the program, but you are not obliged to do so. If you
  # do not wish to do so, delete this exception statement from your version.
  #
  # For more information : contact@centreon.com
  # Authors : your name <your@mail>
  #
  ####################################################################################

  # Chemin vers le mode
  package apps::pfsense::snmp::mode::memorydroppedpackets;

  # Bibliothèque nécessaire pour le mode
  use base qw(centreon::plugins::mode);

  # Bibliothèques nécessaires
  use strict;
  use warnings;

  # Bibliothèque nécessaire pour certaines fonctions
  use POSIX;

  # Bibliothèque nécessaire pour utiliser un fichier de cache
  use centreon::plugins::statefile;

Ajoutez la méthode **new** pour instancier le mode:

.. code-block:: perl

  sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # Version du mode
    $self->{version} = '1.0';

    # Declaration des options
    $options{options}->add_options(arguments =>
                                {
                                  # nom de l'option    => nom de la variable
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                });

    # Instanciation du fichier de cache
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
  }

.. tip::

  Une valeur par défaut peut être ajoutée aux options.
  Exemple : "warning:s" => { name => 'warning', default => '80'},

Ajoutez la méthode **check_options** pour valider les options:

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Validation des options de seuil avec la méthode threshold_validate
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    # Validation des options de fichier de cache en utilisant la méthode check_options de la bibliothèque statefile
    $self->{statefile_value}->check_options(%options);
  }

Ajoutez la méthode **run** pour exécuter le mode:

.. code-block:: perl

  sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object

    # Récupération des options snmp
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    # oid snmp à requêter
    my $oid_pfsenseMemDropPackets = '.1.3.6.1.4.1.12325.1.200.1.2.6.0';
    my ($result, $value);

    # Récupération de la valeur snmp pour l'oid précédemment défini
    $result = $self->{snmp}->get_leef(oids => [ $oid_pfsenseMemDropPackets ], nothing_quit => 1);
    # $result est une table de hashage où les clés sont les oids
    $value = $result->{$oid_pfsenseMemDropPackets};

    # Lecture du fichier de cache
    $self->{statefile_value}->read(statefile => 'pfsense_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    # Lecture des valeurs du fichier de cache
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_memDropPackets = $self->{statefile_value}->get(name => 'memDropPackets');

    # Création d'une table de hashage avec les nouvelles valeurs qui seront écrites dans le fichier de cache
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{memDropPackets} = $value;

    # Ecriture des nouvelles valeurs dans le fichier de cache
    $self->{statefile_value}->write(data => $new_datas);

    # Si le fichier de cache ne possédait aucune valeur, nous les créons et attendons un nouveau contrôle pour calculer la valeur
    if (!defined($old_timestamp) || !defined($old_memDropPackets)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Correctif lorsque PfSense redémarre (les compteurs snmp sont réinitialisés à 0)
    $old_memDropPackets = 0 if ($old_memDropPackets > $new_datas->{memDropPackets});

    # Calcul de l'intervalle de temps entre 2 contrôles
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    # Calcul de la valeur par seconde
    my $memDropPacketsPerSec = ($new_datas->{memDropPackets} - $old_memDropPackets) / $delta_time;

    # Calcul le code de retour en comparant la valeur aux seuils
    # Le code de retour peut être : 'OK', 'WARNING', 'CRITICAL', 'UNKNOWN'
    my $exit_code = $self->{perfdata}->threshold_check(value => $memDropPacketsPerSec,
                                                       threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    # Ajout d'une donnée de performance
    $self->{output}->perfdata_add(label => 'dropped_packets_Per_Sec',
                                  value => sprintf("%.2f", $memDropPacketsPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    # Ajout du message de sortie
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Dropped packets due to memory limitations : %.2f /s",
                                    $memDropPacketsPerSec));

    # Affichage du message de sortie
    $self->{output}->display();
    $self->{output}->exit();
  }

Déclarez ce mode comme un module perl:

.. code-block:: perl

  1;

Ajoutez une description aux options du mode:

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


Ligne de commande
-----------------

Voici un exemple de ligne de commande:
::

  $ perl centreon_plugins.pl --plugin apps::pfsense::snmp::plugin --mode memory-dropped-packets --hostname 192.168.0.1 --snmp-community 'public' --snmp-version '2c' --warning '1' --critical '2'

La sortie pourrait afficher:
::

  OK: Dropped packets due to memory limitations : 0.00 /s | dropped_packets_Per_Sec=0.00;0;;1;2



