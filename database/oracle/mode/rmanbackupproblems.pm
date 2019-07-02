#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::rmanbackupproblems;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "warning:s"       => { name => 'warning', },
        "critical:s"      => { name => 'critical', },
        "retention:s"     => { name => 'retention', default => 3 },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $retention = $self->{option_results}->{retention};
    my $query = q{SELECT COUNT(*) FROM v$rman_status WHERE operation = 'BACKUP' AND status != 'COMPLETED' AND status != 'RUNNING' AND start_time > sysdate-} . $retention;
    $self->{sql}->query(query => $query);
    my $rman_backup_problems = $self->{sql}->fetchrow_array();
    $self->{sql}->disconnect();

    my $exit_code = $self->{perfdata}->threshold_check(value => $rman_backup_problems, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit_code,
                                  short_msg => sprintf("rman had %i problems during the last %i days", $rman_backup_problems, $self->{option_results}->{retention}));
    $self->{output}->perfdata_add(label => 'rman_backup_problems',
                                  value => $rman_backup_problems,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle rman backup problems.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--retention>

Retention in days (default : 3).

=back

=cut
