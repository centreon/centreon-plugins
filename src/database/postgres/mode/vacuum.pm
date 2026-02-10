#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { redirect => 'warning-vacuum-last-execution-seconds' },
        'critical:s' => { redirect => 'critical-vacuum-last-execution-seconds' },
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vacuum', nlabel => 'vacuum.last.execution.seconds', set => {
                key_values => [ { name => 'vacuum' } ],
                output_template => 'Most recent vacuum dates back from %d seconds',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' },
                ],
            }
        }
    ];
}

sub manage_selection {
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

    $self->{output}->option_exit(short_msg => 'No vacuum performed')
        unless $result;

    $self->{global} = { vacuum => $result };
}

1;

__END__

=head1 MODE

Check a vacuum (manual or auto) command has been performed on at least one of the tables of the associated DB

=over 8

=item B<--warning-vacuum>

Warning threshold in seconds, maximum time interval since last vacuum.

=item B<--critical-vacuum>

Critical threshold in seconds, maximum time interval since last vacuum.

=back

=cut
