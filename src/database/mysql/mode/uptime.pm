#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

# Constructeur de la classe
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # Ajout des options spécifiques à ce mode
    $options{options}->add_options(arguments => { 
        "warning:s"  => { name => 'warning' },
        "critical:s" => { name => 'critical' },
        "seconds"    => { name => 'seconds' }
    });

    return $self;
}

# Vérification des options
sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Validation des seuils de warning et critical
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

# Méthode d'exécution du script
sub run {
    my ($self, %options) = @_;

    # Connexion à la base de données MySQL
    $options{sql}->connect();    

    # Vérification de la version de MySQL
    if (!($options{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.x').");
        $self->{output}->option_exit();
    }

    # Exécution de la requête pour obtenir le temps d'activité (uptime)
    $options{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
    my ($name, $value) = $options{sql}->fetchrow_array();
    
    # Vérification si le temps d'activité a été obtenu avec succès
    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get uptime.");
        $self->{output}->option_exit();
    }

    # Vérification des seuils de warning et critical
    my $exit_code = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    # Préparation du message de sortie
    my $uptime_days = floor($value / 86400);
    my $msg = sprintf("database is up since %d days", $uptime_days);
    if (defined($self->{option_results}->{seconds})) {
        $msg = sprintf("database is up since %d seconds", $value);
    }

    # Ajout du message à la sortie
    $self->{output}->output_add(
        severity => $exit_code,
        short_msg => $msg
    );

    # Ajout de la date de démarrage de la base de données
    my $start_time = strftime("%Y/%m/%d %H:%M:%S", localtime(time - $value));
    $self->{output}->output_add(long_msg => "Start time = $start_time");

    # Ajout des données de performance à la sortie
    $self->{output}->perfdata_add(
        label => 'uptime', 
        nlabel => 'database.uptime.seconds',
        unit => 's',
        value => $value,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    # Affichage de la sortie
    $self->{output}->display();

    # Sortie du script avec le code approprié
    $self->{output}->exit();
}

# Indique que le module a été correctement chargé
1;

__END__


=head1 MODE

Check MySQL uptime.

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
