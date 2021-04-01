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

package storage::quantum::dxi::ssh::mode::throughput;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_volume_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'B/s',
        value => $self->{result_values}->{volume},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label})
    );
}

sub custom_volume_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{volume},
        threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_volume_output {
    my ($self, %options) = @_;

    my ($volume_value, $volume_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{volume});
    return sprintf("%s: %s %s/s", $self->{result_values}->{display}, $volume_value, $volume_unit);
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
        { label => 'read-rate', set => {
                key_values => [ { name => 'read_rate' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'read_rate', display_ref => 'Read Rate' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'write-rate', set => {
                key_values => [ { name => 'write_rate' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'write_rate', display_ref => 'Write Rate' },
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = $options{custom}->execute_command(command => 'syscli --get ingestrate');
    # Output data:
    #     Write Throughput = 0.03 MB/s
    #     Read Throughput = 6.98 MB/s
    $self->{global} = {};
    foreach (split(/\n/, $stdout)) {
        $self->{global}->{write_rate} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Write\sThroughput\s=\s(.*)$/i);
        $self->{global}->{read_rate} = $options{custom}->convert_to_bytes(raw_value => $1)  if (/.*Read\sThroughput\s=\s(.*)$/i);
    }
}

1;

__END__

=head1 MODE

Check ingest throughput rate.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read-rate', 'write-rate'.

=back

=cut
