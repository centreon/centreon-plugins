#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package storage::quantum::dxi::ssh::mode::compaction;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'Compaction status: ' . $self->{result_values}->{compaction_status};
}

sub custom_volume_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'B',
        value => $self->{result_values}->{volume},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label})
    );
}

sub custom_volume_threshold {
    my ($self, %options) = @_;
    
    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{volume},
        threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]
    );
}

sub custom_volume_output {
    my ($self, %options) = @_;
    
    my ($volume_value, $volume_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{volume});
    return sprintf('%s: %s %s', $self->{result_values}->{display}, $volume_value, $volume_unit);
}

sub custom_volume_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{volume} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{display} = $options{extra_options}->{display_ref};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'compaction_status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'status-progress', set => {
                key_values => [ { name => 'status_progress' } ],
                output_template => 'Status progress: %.2f %%',
                perfdatas => [
                    { label => 'status_progress', value => 'status_progress', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'compacted', set => {
                key_values => [ { name => 'compacted' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'compacted', display_ref => 'Compacted' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'still-to-compact', set => {
                key_values => [ { name => 'still_to_compact' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'still_to_compact', display_ref => 'Still to compact' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{compaction_status} !~ /ready/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $stdout = $options{custom}->execute_command(command => 'syscli --getstatus compaction');
    # Output data:
    #    Compaction Status = Ready
    #    Status Progress = 0 %
    #    Start Time =
    #    End Time =
    #    Compacted = 12.00 MB
    #    Still to compact = 123.00 MB

    $self->{global} = {};
    foreach (split(/\n/, $stdout)) {
        $self->{global}->{compaction_status} = $1 if (/.*Compaction\sStatus\s=\s(.*)$/i);
        $self->{global}->{status_progress} = $1 if (/.*Status\sProgress\s=\s(.*)\s%$/i);
        $self->{global}->{compacted} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Compacted\s=\s(.*)$/i);
        $self->{global}->{still_to_compact} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Still\sto\scompact\s=\s(.*)$/i);
    }
}

1;

__END__

=head1 MODE

Check compaction status and volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{compaction_status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{compaction_status} !~ /ready/i').
Can used special variables like: %{compaction_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'status-progress', 'compacted', 'still-to-compact'.

=back

=cut
