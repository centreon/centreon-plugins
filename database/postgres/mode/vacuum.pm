#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::postgres::mode::vacuum;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
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

    $options{sql}->connect();
    
    my $target_fields = 'last_vacuum';
    # Autovacuum feature has only been impleted starting PG 8.2 
    # (options needed http://www.postgresql.org/docs/8.2/static/runtime-config-autovacuum.html, no need starting 8.3)
    if ($options{sql}->is_version_minimum(version => '8.2.0')) {
        $target_fields = 'greatest(last_autovacuum,last_vacuum)';
    }

    my $query = sprintf(
        'SELECT ROUND(EXTRACT(EPOCH from (select min (now() - %s) from pg_stat_all_tables where %s is not null)))',
        $target_fields,
        $target_fields
    );
    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchrow_array();
    if (defined($result)) {
        my $exit_code = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf('Most recent vacuum dates back from %d seconds', $result)
        );
        $self->{output}->perfdata_add(
            label => 'last_vacuum',
            value => $result,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
        );
    } else {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'No vacuum performed on this BD yet.'
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check a vacuum (manual or auto) command has been performed on at least one of the tables of the associated DB

=over 8

=item B<--warning>

Threshold warning in seconds, maximum time interval since last vacuum.

=item B<--critical>

Threshold critical in seconds, maximum time interval since last vacuum.

=back

=cut
