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

package database::oracle::mode::rmanbackupproblems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'During the last %s days, number of backups ',
        $options{instance_value}->{retention}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'completed', nlabel => 'rman.backups.completed.count', set => {
                key_values => [ { name => 'completed' } ],
                output_template => 'completed: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'failed', nlabel => 'rman.backups.failed.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'completed-warnings', nlabel => 'rman.backups.completed_with_warnings.count', set => {
                key_values => [ { name => 'completed_with_warnings' } ],
                output_template => 'completed with warnings: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'completed-errors', nlabel => 'rman.backups.completed_with_errors.count', set => {
                key_values => [ { name => 'completed_with_errors' } ],
                output_template => 'completed with errors: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'retention:s' => { name => 'retention', default => 3 }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    my $query = q{
        SELECT status, COUNT(*) as num
        FROM v$rman_status 
        WHERE operation = 'BACKUP' AND status NOT IN ('RUNNING', 'RUNNING WITH WARNINGS', 'RUNNING WITH ERRORS')
            AND start_time > sysdate-} . $self->{option_results}->{retention} . q{
        GROUP BY status
    };

    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchall_arrayref();
    $options{sql}->disconnect();

    $self->{global} = {
        retention => $self->{option_results}->{retention},
        completed => 0,
        failed => 0,
        completed_with_warnings => 0,
        completed_with_errors => 0
    };
    foreach my $row (@$result) {
        my $status = lc($row->[0]);
        $status =~ s/\s+/_/g;
        $self->{global}->{$status} += $row->[1];
    }
}

1;

__END__

=head1 MODE

Check Oracle rman backup problems.

=over 8

=item B<--retention>

Retention in days (default: 3).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'completed', 'failed', 'completed-warnings', 'completed-errors'.

=back

=cut
