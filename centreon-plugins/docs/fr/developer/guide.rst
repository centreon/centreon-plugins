***********
Description
***********

Ce document présente les bonnes pratiques pour le développement de "centreon-plugins".
Comme tous les plugins sont écrits en Perl, "There's more than one way to do it".
Afib de ne pas réinventer la roue, vous devriez d'abord regarder le dossier “example”. Vous aurez alors un aperçu de la méthodologie pour construire votre propre plugin ainsi que ses modes associés.

La dernière version est disponible sur le dépôt git suivant: https://github.com/centreon/centreon-plugins.git

****************
Démarrage rapide
****************

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

Selon l'objet supervisé, il existe une organisation qui peut être utilisé :

* Type
* Constructeur
* Modèle
* Protocole de supervision

Par exemple, si vous voulez ajouter un plugin pour superviser Linux par SNMP, vous devez créer ce dossier :
::

  $ mkdir -p os/linux/snmp

Vous avez également besoin de créer une répertoire "mode" pour les futurs modes créés :
::

  $ mkdir os/linux/snmp/mode

------------------
Création du plugin
------------------

Une fois le dossier créé, ajouter le fichier du plugin à l'intérieur de celui-ci :
::

  $ touch plugin.pm

Ensuite, éditer le fichier plugin.pm pour ajouter les **conditions de licence** en les copiant à partir d'un autre plugin. N'oubliez pas d'ajouter votre nom à la fin de celles-ci :

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Renseigner votre nom de **package** : il correspond au dossier de votre plugin.

.. code-block:: perl

  package path::to::plugin;

Déclarer les bibliothèques utilisées (**strict** et **warnings** sont obligatoires). Les bibliothèques Centreon sont décrites par la suite :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(**centreon_library**);

Le plugin a besoin d'un constructeur **new** pour instancier l'objet :

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

La version du plugin doit être déclarée dans le constructeur **new** :

.. code-block:: perl

  $self->{version} = '0.1';

Plusieurs modes peuvent être déclarés dans le constructeur **new** :

.. code-block:: perl

  %{$self->{modes}} = (
                        'mode1'    => '<plugin_path>::mode::mode1',
                        'mode2'    => '<plugin_path>::mode::mode2',
                        ...
                        );

Ensuite, déclarer le module :

.. code-block:: perl

  1;

Une description du plugin est nécessaire pour générer la documentation :

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut


.. tip::
  Vous pouvez copier/coller les éléments d'un autre plugin et adapter les lignes (paquets, arguments, ...).

.. tip::
  Le plugin possède une extension ".pm" car c'est un module PERL. Par conséquent, ne pas oublier d'ajouter un **1;**.

----------------
Création du mode
----------------

Une fois que le fichier **plugin.pm** existe et que ses modes sont déclarés, créer les modes dans le dossier **mode** :
::

  cd mode
  touch mode1.pm

Ensuite, éditer mode1.pm pour ajouter les **conditions de licence** en les copiant à partir d'un autre mode. Ne pas oublier pas d'ajouter votre nom à la fin de celles-ci :

.. code-block:: perl

  # ...
  # Authors : <your name> <<your email>>

Décrire votre nom de **package** : il correspond au dossier de votre mode.

.. code-block:: perl

  package path::to::plugin::mode::mode1;

Déclarer les bibliothèques utilisées (toujours les mêmes) :

.. code-block:: perl

  use strict;
  use warnings;
  use base qw(centreon::plugins::mode);

Le mode nécessite un constructeur **new** pour instancier l'objet :

.. code-block:: perl

  sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        ...

        return $self;
  }

La version du mode doit être déclarée dans le constructeur **new** :

.. code-block:: perl

  $self->{version} = '1.0';

Plusieurs options peuvent être déclarées dans le constructeur **new** :

.. code-block:: perl

  $options{options}->add_options(arguments =>
                                {
                                  "option1:s" => { name => 'option1' },
                                  "option2:s" => { name => 'option2', default => 'value1' },
                                  "option3"   => { name => 'option3' },
                                });

Voici la description des arguments de cet exemple :

* option1 : Chaîne de caractères
* option2 : Chaîne de caractères avec "value1" comme valeur par défaut
* option3 : Booléen

.. tip::
  Vous pouvez obtenir plus d'informations sur les formats des options ici : http://perldoc.perl.org/Getopt/Long.html

Le mode nécessite une méthode **check_options** pour valider les options :

.. code-block:: perl

  sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    ...
  }

Par exemple, les seuils Dégradé (Warning) et Critique (Critical) doivent être validés dans la méthode **check_options** :

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

Ensuite vient la méthode **run** où sera effectué le traitement, vérifié les seuils et affichés le message de sortie et les données de performance.
Voici un exemple pour vérifier une valeur SNMP :

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

Dans cet exemple, un OID SNMP sera vérifié et comparé aux seuils Dégradé et Critique.
Voici les méthodes utilisées :

* get_leef        : pour obtenir une valeur snmp à partir d'un OID
* threshold_check : pour comparer une valeur snmp à des seuils dégradé et critique
* output_add      : pour ajouter des informations au message de sortie
* perfdata_add    : pour ajouter des données de performance au message de sortie
* display         : pour afficher le message de sortie
* exit            : pour sortir du programme

Ensuite, déclarer le module :

.. code-block:: perl

  1;

Une description du mode et de ses arguments est nécessaire pour générer la documentation :

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut

--------------
Commit et push
--------------

Avant de commiter le plugin, vous devez créer un **ticket amélioration** (enhancement) dans la forge centreon-plugins : http://forge.centreon.com/projects/centreon-plugins

Une fois que le plugin et ses modes sont développés, vous pouvez commiter (messages de commit en anglais) et envoyer votre travail :
::

  git add path/to/plugin
  git commit -m "Add new plugin for XXXX refs #<ticked_id>"
  git push

*****************************
Référentiel des bibliothèques
*****************************

Ce chapitre décrit les bibliothèques Centreon qui peuvent être utilisées dans votre développement.

------
Output
------

Cette bibliothèque vous permet de construire la sortie de votre plugin.

output_add
----------

Description
^^^^^^^^^^^

Ajouter une chaîne de caractères à la sortie (affichée avec la méthode **display**).
Si le statut est différent de 'OK', le message de sortie associé à 'OK' ne sera pas affiché.

Paramètres
^^^^^^^^^^

+------------+---------+----------+---------------------------------------------------------------+
|  Paramètre |    Type |   Défaut |          Description                                          |
+============+=========+==========+===============================================================+
| severity   | String  |    OK    | Statut du message de sortie.                                  |
+------------+---------+----------+---------------------------------------------------------------+
| separator  | String  |    \-    | Séparateur entre le statut et le message de sortie.           |
+------------+---------+----------+---------------------------------------------------------------+
| short_msg  | String  |          | Message de sortie court (première ligne).                     |
+------------+---------+----------+---------------------------------------------------------------+
| long_msg   | String  |          | Message de sortie long (utilisé avec l'option ``--verbose``). |
+------------+---------+----------+---------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple de gestion de la sortie du plugin :

.. code-block:: perl

  $self->{output}->output_add(severity  => 'OK',
                              short_msg => 'All is ok');
  $self->{output}->output_add(severity  => 'Critical',
                              short_msg => 'There is a critical problem');
  $self->{output}->output_add(long_msg  => 'Port 1 is disconnected');

  $self->{output}->display();

La sortie affichera :
::

  CRITICAL - There is a critical problem
  Port 1 is disconnected


perfdata_add
------------

Description
^^^^^^^^^^^

Ajouter une donnée de performance à la sortie (affichée avec la méthode **display**).
Les données de performance sont affichées après le symbole '|'.

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
| warning         | String          |             | Seuil Dégradé.                                          |
+-----------------+-----------------+-------------+---------------------------------------------------------+
| critical        | String          |             | Seuil Critique.                                         |
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

La sortie affichera :
::

  OK - Memory is ok | 'memory_used'=30000000B;80000000;90000000;0;100000000


--------
Perfdata
--------

Cette bibliothèque vous permet de gérer les données de performance.

get_perfdata_for_output
-----------------------

Description
^^^^^^^^^^^

Gérer les seuils des données de performance pour la sortie.

Paramètres
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

Voici un exemple de gestion des données de performance pour la sortie :

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
  Dans cet exemple, au lieu d'afficher les seuils Dégradé et Critique en 'pourcentage', la fonction calculera et affichera ceux-ci en 'bytes'.

threshold_validate
------------------

Description
^^^^^^^^^^^

Valider et associer un seuil à un label.

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

Voici un exemple vérifiant si le seuil dégradé est correct :

.. code-block:: perl

  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
    $self->{output}->option_exit();
  }

.. tip::
  Les bon formats de seuils sont consultables ici : https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT

threshold_check
---------------

Description
^^^^^^^^^^^

Vérifier la valeur d'une donnée de performance avec un seuil pour déterminer son statut.

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

La sortie affichera :
::

  WARNING - Used memory is 85% |

change_bytes
------------

Description
^^^^^^^^^^^

Convertir des bytes en unité de mesure lisible.
Retourner une valeur et une unité.

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

Voici un exemple de conversion des bytes en unité de mesure lisible :

.. code-block:: perl

  my ($value, $unit) = $self->{perfdata}->change_bytes(value => 100000);

  print $value.' '.$unit."\n";

La sortie affichera :
::

  100 KB

----
SNMP
----

Cette bibliothèque vous permet d'utiliser le protocole SNMP dans votre plugin.
Pour l'utiliser, vous devez ajouter la ligne suivant au début de votre fichier **plugin.pm** :

.. code-block:: perl

  use base qw(centreon::plugins::script_snmp);


get_leef
--------

Description
^^^^^^^^^^^

Retourne une table de hashage de valeurs SNMP pour plusieurs OIDs (ne fonctionne pas avec les tables SNMP).

Paramètres
^^^^^^^^^^

+--------------+--------------+----------+----------------------------------------------------------------------------+
|  Paramètre   |    Type      |   Défaut |          Description                                                       |
+==============+==============+==========+============================================================================+
| **oids**     | String array |          | Tableau d'OIDs à contrôler (Peut être spécifier avec la méthode ``load``). |
+--------------+--------------+----------+----------------------------------------------------------------------------+
| dont_quit    | Int (0 or 1) |     0    | Ne pas quitter pas même si une erreur SNMP se produit.                     |
+--------------+--------------+----------+----------------------------------------------------------------------------+
| nothing_quit | Int (0 or 1) |     0    | Quitter si aucune valeur n'est retournée.                                  |
+--------------+--------------+----------+----------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour récupérer 2 valeurs SNMP :

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

Charger une liste d'OIDs à utiliser avec la méthode **get_leef**.

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
| begin           |  Int                 |              | Instance de début.                                                          |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+
| end             |  Int                 |              | Instance de fin.                                                           |
+-----------------+----------------------+--------------+----------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour obtenir les 4 premières instances d'une table SNMP en utilisant la méthode **load** :

.. code-block:: perl

  my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';

  $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => [1,2,3,4]);

  my $result = $self->{snmp}->get_leef(nothing_quit => 1);

  use Data::Dumper;
  print Dumper($result);

Voici un exemple pour obtenir plusieurs instances dynamiquement (modules mémoire de matériel Dell) en utilisant la méthode **load** :

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

Retourner une table de hashage de valeurs SNMP pour une table SNMP.

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
| dont_quit       |  Int (0 or 1)        |       0        | Ne pas quitter même si une erreur SNMP se produit.              |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quitter si aucune valeur n'est retournée.                       |
+-----------------+----------------------+----------------+-----------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Retourner une table de hashage à un niveau au lieu de plusieurs.|
+-----------------+----------------------+----------------+-----------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour récupérer une table SNMP :

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

Retourner une table de hashage de valeurs SNMP pour plusieurs tables SNMP.

Paramètres
^^^^^^^^^^

+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
|  Paramètre      |        Type          |   Défaut       |          Description                                                                  |
+=================+======================+================+=======================================================================================+
| **oids**        |  Hash table          |                | Table de hashage des OIDs à récupérer (Peut être spécifié avec la méthode ``load``).  |
|                 |                      |                | Les clés peuvent être : "oid", "start", "end".                                        |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| dont_quit       |  Int (0 or 1)        |       0        | Ne pas quitter même si une erreur snmp se produit.                                    |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| nothing_quit    |  Int (0 or 1)        |       0        | Quitter si aucune valeur n'est retournée.                                             |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+
| return_type     |  Int (0 or 1)        |       0        | Retourner une table de hashage à un niveau au lieu de plusieurs.                      |
+-----------------+----------------------+----------------+---------------------------------------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple pour récupérer 2 tables SNMP :

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

Récupérer le nom d'hôte en paramètre (utile pour obtenir le nom d'hôte dans un mode).

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple pour obtenir le nom d'hôte en paramètre :

.. code-block:: perl

  my $hostname = $self->{snmp}->get_hostname();


get_port
--------

Description
^^^^^^^^^^^

Récupérer le port en paramètre (utile pour obtenir le port dans un mode).

Parameters
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple pour obtenir le port en paramètre :

.. code-block:: perl

  my $port = $self->{snmp}->get_port();


oid_lex_sort
------------

Description
^^^^^^^^^^^

Retourner des OIDs triés.

Paramètres
^^^^^^^^^^

+-----------------+-------------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type           |   Défaut    |          Description                                    |
+=================+===================+=============+=========================================================+
| **-**           |  String array     |             | Tableau d'OIDs à trier.                                 |
+-----------------+-------------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Cet exemple afichera des OIDs triés :

.. code-block:: perl

  foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$my_oid}})) {
    print $oid;
  }


----
Misc
----

Cette bibliothèque fournit un ensemble de méthodes diverses.
Pour l'utiliser, vous pouvez directement utiliser le chemin de la méthode :

.. code-block:: perl

  centreon::plugins::misc::<my_method>;


trim
----

Description
^^^^^^^^^^^

Enlever les espaces de début et de fin d'une chaîne de caractères.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | String          |             | Chaîne à modifier.                                   |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **trim** :

.. code-block:: perl

  my $word = '  Hello world !  ';
  my $trim_word =  centreon::plugins::misc::trim($word);

  print $word."\n";
  print $trim_word."\n";

La sortie affichera :
::

  Hello world !


change_seconds
--------------

Description
^^^^^^^^^^^

Convertir des secondes en unité de mesure lisible.

Paramètres
^^^^^^^^^^

+-----------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre      |    Type         |   Défaut    |          Description                                    |
+=================+=================+=============+=========================================================+
| **-**           | Int             |             | Nombre de secondes à convertir.                         |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **change_seconds** :

.. code-block:: perl

  my $seconds = 3750;
  my $human_readable_time =  centreon::plugins::misc::change_seconds($seconds);

  print 'Human readable time : '.$human_readable_time."\n";

La sortie affichera :
::

  Human readable time : 1h 2m 30s


backtick
--------

Description
^^^^^^^^^^^

Exécuter une commande système.

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
| redirect_stderr | Int (0 or 1)    |     0       | Afficher les erreurs dans la sortie.                    |
+-----------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **backtick** :

.. code-block:: perl

  my ($error, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                      command => 'ls /home',
                                      timeout => 5,
                                      wait_exit => 1
                                      );

  print $stdout."\n";

La sortie affichera les fichiers du répertoire '/home'.


execute
-------

Description
^^^^^^^^^^^

Exécuter une commande à distance.

Paramètres
^^^^^^^^^^

+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
|  Paramètre       |    Type         |   Défaut    |          Description                                                                               |
+==================+=================+=============+====================================================================================================+
| **output**       | Object          |             | Sortie du plugin ($self->{output}).                                                                |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| **options**      | Object          |             | Options du plugin ($self->{option_results}) pour obtenir les informations de connexion à distance. |
+------------------+-----------------+-------------+----------------------------------------------------------------------------------------------------+
| sudo             | String          |             | Utiliser la commande sudo.                                                                         |
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
Nous supposons que l'option ``--remote`` soit activée :

.. code-block:: perl

  my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                options => $self->{option_results},
                                                sudo => 1,
                                                command => 'ls /home',
                                                command_path => '/bin/',
                                                command_options => '-l');

La sortie affichera les fichier du répertoire /home d'un hôte distant à travers une connexion SSH.


windows_execute
---------------

Description
^^^^^^^^^^^

Exécuter une commande sur Windows.

Paramètres
^^^^^^^^^^

+------------------+-----------------+-------------+-----------------------------------------------------------------+
|  Paramètre       |    Type         |   Défaut    |          Description                                            |
+==================+=================+=============+=================================================================+
| **output**       | Object          |             | Sortie du plugin ($self->{output}).                             |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| **command**      | String          |             | Commande à exécuter.                                            |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_path     | String          |             | Chemin de la commande.                                          |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| command_options  | String          |             | Arguments de la commande.                                       |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| timeout          | Int             |             | Timeout de la commande.                                         |
+------------------+-----------------+-------------+-----------------------------------------------------------------+
| no_quit          | Int             |             | Ne pas quitter même si une erreur SNMP se produit.              |
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

La sortie affichera la configuration IP d'un hôte Windows.


---------
Statefile
---------

Cette bibliothèque fournit un ensemble de méthodes pour utiliser un fichier de cache.
Pour l'utiliser, ajouter la ligne suivante au début de votre **mode** :

.. code-block:: perl

  use centreon::plugins::statefile;


read
----

Description
^^^^^^^^^^^

Lire un fichier de cache.

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

Voici un exemple d'utilisation de la méthode **read** :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  use Data::Dumper;
  print Dumper($self->{statefile_value});

La sortie affichera le fichier de cache et ses paramètres.


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
| name              | String          |             | Récupérer une valeur du fichier de cache.               |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **get** :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $value = $self->{statefile_value}->get(name => 'property1');
  print $value."\n";

La sortie affichera la valeur associée à 'property1' du fichier de cache.


write
-----

Description
^^^^^^^^^^^

Ecrire des données dans le fichier de cache.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| data              | String          |             | Données à écrire dans le fichier de cache.              |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **write** :

.. code-block:: perl

  $self->{statefile_value} = centreon::plugins::statefile->new(%options);
  $self->{statefile_value}->check_options(%options);
  $self->{statefile_value}->read(statefile => 'my_cache_file',
                                 statefile_dir => '/var/lib/centreon/centplugins'
                                );

  my $new_datas = {};
  $new_datas->{last_timestamp} = time();
  $self->{statefile_value}->write(data => $new_datas);

Ensuite, vous pouvez voir le résultat dans le fichier '/var/lib/centreon/centplugins/my_cache_file', le timestamp y est écrit.


----
HTTP
----

Cette bibliothèque fournit un ensemble de méthodes pour utiliser le protocole HTTP.
Pour l'utiliser, ajouter la ligne suivante au début de votre **mode** :

.. code-block:: perl

  use centreon::plugins::http;

Certaines options doivent être spécifiées dans **plugin.pm** :

+-----------------+-----------------+----------------------------------------------------------------------+
|  Option         |    Type         |          Description                                                 |
+=================+=================+======================================================================+
| **hostname**    | String          | Adresse IP/FQDN du serveur web.                                      |
+-----------------+-----------------+----------------------------------------------------------------------+
| **port**        | String          | Port HTTP.                                                           |
+-----------------+-----------------+----------------------------------------------------------------------+
| **proto**       | String          | Protocole utilisé ('HTTP' ou 'HTTPS').                               |
+-----------------+-----------------+----------------------------------------------------------------------+
| credentials     |                 | Utiliser les informations d'authentification.                        |
+-----------------+-----------------+----------------------------------------------------------------------+
| ntlm            |                 | Utiliser l'authentification NTLM (si ``--credentials`` est utilisée).|
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

Tester la connexion vers une url HTTP.
Retourner le contenu de la page web.

Paramètres
^^^^^^^^^^

Cette méthode utilise les options du plugin précédemment définies.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **connect**.
Nous supposons que ces options sont définies :
* --hostname = 'google.com'
* --urlpath  = '/'
* --proto    = 'http'
* --port     = 80

.. code-block:: perl

  $self->{http} = centreon::plugins::http->new(output => $self->{output});
  $self->{http}->set_options(%{$self->{option_results}});
  my $webcontent = $self->{http}->request();
  print $webcontent;

La sortie affichera le contenu de la page web '\http://google.com/'.


---
DBI
---

Cette bibliothèque vous permet de vous connecter à une ou plusieurs bases de données.
Pour l'utiliser, ajouter la ligne suivante au début de votre fichier **plugin.pm** :

.. code-block:: perl

  use base qw(centreon::plugins::script_sql);

connect
-------

Description
^^^^^^^^^^^

Se connecter à une ou plusieurs bases de données.

Paramètres
^^^^^^^^^^

+------------+--------------+----------+-----------------------------------------------------------+
|  Paramètre |    Type      |   Défaut |          Description                                      |
+============+==============+==========+===========================================================+
| dontquit   | Int (0 or 1) |     0    | Ne pas quitter même si une erreur de connexion se produit.|
+------------+--------------+----------+-----------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **connect**.
Le format de la chaîne de connexion peut avoir les formes suivantes :
::
    DriverName:database_name
    DriverName:database_name@hostname:port
    DriverName:database=database_name;host=hostname;port=port

Dans plugin.pm :

.. code-block:: perl

  $self->{sqldefault}->{dbi} = ();
  $self->{sqldefault}->{dbi} = { data_source => 'mysql:host=127.0.0.1;port=3306' };

Dans votre mode :

.. code-block:: perl

  $self->{sql} = $options{sql};
  my ($exit, $msg_error) = $self->{sql}->connect(dontquit => 1);

Vous êtes alors connecté à la base de données MySQL.

query
-----

Description
^^^^^^^^^^^

Exécuter une requête SQL sur la base de données.

Paramètres
^^^^^^^^^^

+-------------------+-----------------+-------------+---------------------------------------------------------+
|  Paramètre        |    Type         |   Défaut    |          Description                                    |
+===================+=================+=============+=========================================================+
| query             | String          |             | Requête SQL à exécuter.                                 |
+-------------------+-----------------+-------------+---------------------------------------------------------+

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **query** :

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Slow_queries'});
  my ($name, $result) = $self->{sql}->fetchrow_array();

  print 'Name : '.$name."\n";
  print 'Value : '.$value."\n";

La sortie affichera le nombre de requêtes MySQL lentes.


fetchrow_array
--------------

Description
^^^^^^^^^^^

Retourner une tableau à partir d'une requête SQL.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_array** :

.. code-block:: perl

  $self->{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
  my ($dummy, $result) = $self->{sql}->fetchrow_array();

  print 'Uptime : '.$result."\n";

La sortie affichera l'uptime MySQL.


fetchall_arrayref
-----------------

Description
^^^^^^^^^^^

Retourner un tableau à partir d'une requête SQL.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_array** :

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

La sortie affichera les lectures physiques sur une base de données Oracle.


fetchrow_hashref

----------------

Description
^^^^^^^^^^^

Retourner une table de hashage à partir d'une requête SQL.

Paramètres
^^^^^^^^^^

Aucun.

Exemple
^^^^^^^

Voici un exemple d'utilisation de la méthode **fetchrow_hashref** :

.. code-block:: perl

  $self->{sql}->query(query => q{
    SELECT datname FROM pg_database
  });

  while ((my $row = $self->{sql}->fetchrow_hashref())) {
    print $row->{datname}."\n";
  }

La sortie affichera la liste des bases de données PostgreSQL.


*****************
Exemples complets
*****************

-------------------
Requête SNMP simple
-------------------

Description
-----------

| Cet exemple explique comment vérifier une valeur SNMP unique sur un pare-feu PfSense (paquets supprimés pour cause de surcharge mémoire).
| Un fichier de cache sera utilisé car c'est un compteur SNMP. Il est nécessaire d'obtenir la valeur différentielle entre 2 contrôles.
| La valeur récupérée sera comparée aux seuils Dégradé et Critique.

Fichier du plugin
-----------------

Tout d'abord, créer le dossier du plugin, ainsi que le fichier du plugin :
::

  $ mkdir -p apps/pfsense/snmp
  $ touch apps/pfsense/snmp/plugin.pm

.. tip::
  PfSense est un pare-feu applicatif et il sera contrôler en utilisant le protocole SNMP

Ensuite, éditer le fichier **plugin.pm** et ajouter les lignes suivantes :

.. code-block:: perl

  #
  # Copyright 2016 Centreon (http://www.centreon.com/)
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

  # Chemin vers le plugin
  package apps::pfsense::snmp::plugin;

  # Bibliothèques nécessaires
  use strict;
  use warnings;
  # Utiliser cette bibliothèque pour contrôle en utilisant le protocole SNMP
  use base qw(centreon::plugins::script_snmp);

.. tip::
  N'oublier pas de modifier la ligne 'Authors'.

Ajouter la méthode **new** pour instancier le plugin :

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

Déclarer ce plugin en tant que module perl :

.. code-block:: perl

  1;

Ajouter une description au plugin :

.. code-block:: perl

  __END__

  =head1 PLUGIN DESCRIPTION

  Check pfSense in SNMP.

  =cut

.. tip::

  Cette description est affichée avec l'option ``--help``.


Fichier du mode
---------------

Ensuite, créer le répertoire du mode, ainsi que le fichier du mode :
::

  $ mkdir apps/pfsense/snmp/mode
  $ touch apps/pfsense/snmp/mode/memorydroppedpackets.pm

Editer le fichier **memorydroppedpackets.pm** et ajouter les lignes suivantes :

.. code-block:: perl

  #
  # Copyright 2016 Centreon (http://www.centreon.com/)
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

Ajouter la méthode **new** pour instancier le mode :

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

Ajouter la méthode **check_options** pour valider les options :

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

Ajouter la méthode **run** pour exécuter le mode :

.. code-block:: perl

  sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object

    # Récupération des options SNMP
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    # oid SNMP à requêter
    my $oid_pfsenseMemDropPackets = '.1.3.6.1.4.1.12325.1.200.1.2.6.0';
    my ($result, $value);

    # Récupération de la valeur SNMP pour l'oid précédemment défini
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

    # Si le fichier de cache ne possède aucune valeur, nous les créons et attendons un nouveau contrôle pour calculer la valeur
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

Déclarer ce mode comme un module perl :

.. code-block:: perl

  1;


Ajouter une description aux options du mode :

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

Voici un exemple de ligne de commande :
::

  $ perl centreon_plugins.pl --plugin apps::pfsense::snmp::plugin --mode memory-dropped-packets --hostname 192.168.0.1 --snmp-community 'public' --snmp-version '2c' --warning '1' --critical '2'

La sortie pourrait afficher :
::

  OK: Dropped packets due to memory limitations : 0.00 /s | dropped_packets_Per_Sec=0.00;0;;1;2

