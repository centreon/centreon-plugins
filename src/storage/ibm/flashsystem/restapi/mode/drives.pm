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

package storage::ibm::flashsystem::restapi::mode::drives;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(convert_bytes is_empty is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_path_output {
    my ($self, %options) = @_;

    my $msg = $self->{result_values}->{paths_total} > 0
        ? sprintf('paths %s/%s online', $self->{result_values}->{paths_online}, $self->{result_values}->{paths_total})
        : 'paths status unknown';
    $msg .= sprintf(', use: %s', $self->{result_values}->{use})
        if (is_not_empty($self->{result_values}->{use}));
    $msg .= sprintf(', firmware %s', $self->{result_values}->{firmware})
        if (is_not_empty($self->{result_values}->{firmware}));

    return $msg;
}

sub custom_replacement_output {
    my ($self, %options) = @_;

    return is_not_empty($self->{result_values}->{replacement_date})
        ? sprintf('REPLACEMENT PREDICTED %s', $self->{result_values}->{replacement_date})
        : 'no replacement predicted';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Drives: ' },
        { name => 'drives', type => COUNTER_TYPE_INSTANCE, prefix_output => "Drive '%{name}' (enclosure %{enclosure} slot %{slot}) ",
          message_multiple => 'All drives are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'drives.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{drives} = [
        {
            label => 'path-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{paths_total} > 0 and %{paths_online} == 0',
            warning_default => '%{paths_online} < %{paths_total}',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'paths_online' }, { name => 'paths_total' },
                    { name => 'port_1_status' }, { name => 'port_2_status' },
                    { name => 'use' }, { name => 'firmware' }
                ],
                closure_custom_output => $self->can('custom_path_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'replacement-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{replacement_date} ne ""',
            set => {
                key_values => [ { name => 'name' }, { name => 'replacement_date' } ],
                closure_custom_output => $self->can('custom_replacement_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'endurance', nlabel => 'drive.endurance.used.percentage', set => {
                key_values => [ { name => 'endurance' }, { name => 'name' } ],
                output_template => 'endurance used %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'physical-usage-prct', nlabel => 'drive.physical.space.usage.percentage', set => {
                key_values => [ { name => 'physical_used_prct' }, { name => 'name' } ],
                output_template => 'physical used %.2f %%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-id:s' => { name => 'include_id' },
        'exclude-id:s' => { name => 'exclude_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $to_bytes = sub { # base 1024 unit-suffixed strings ("3.49TB").
        return convert_bytes(value => $_[0] // '', pattern => '^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTP]?B?)\s*$');
    };

    $self->{global} = { detected => 0 };
    $self->{drives} = {};

    foreach my $drive (@{$options{custom}->request(command => 'lsdrive')}) {
        next if (ref($drive) ne 'HASH' || !defined($drive->{id}) || $drive->{id} !~ /^\d+$/);
        next if (is_excluded($drive->{id}, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}));

        # Wear, paths and physical fill are only in the detailed view.
        my $detail = $options{custom}->request_optional(command => 'lsdrive/' . $drive->{id})->[0];
        $detail = $drive if (ref($detail) ne 'HASH');

        $self->{global}->{detected}++;

        my $entry = {
            name => $drive->{id},
            enclosure => $detail->{enclosure_id} // '',
            slot => $detail->{slot_id} // '',
            use => $detail->{use} // '',
            port_1_status => $detail->{port_1_status} // '',
            port_2_status => $detail->{port_2_status} // '',
            replacement_date => $detail->{replacement_date} // '',
            firmware => $detail->{firmware_level} // ''
        };
        $entry->{firmware} =~ s/\s+$//;
        $entry->{paths_total} = 0;
        $entry->{paths_online} = 0;
        foreach my $path_status ($entry->{port_1_status}, $entry->{port_2_status}) {
            next if (is_empty($path_status));
            $entry->{paths_total}++;
            $entry->{paths_online}++ if ($path_status =~ /^online$/i);
        }

        my $endurance = $detail->{write_endurance_used};
        $entry->{endurance} = $endurance
            if (defined($endurance) && $endurance =~ /^\d+(?:\.\d+)?$/);

        my $ptot = $to_bytes->($detail->{physical_capacity});
        my $pused = $to_bytes->($detail->{physical_used_capacity});
        $entry->{physical_used_prct} = $pused * 100 / $ptot
            if (defined($ptot) && defined($pused) && $ptot > 0);

        $self->{drives}->{$drive->{id}} = $entry;
    }

    $self->{output}->option_exit(short_msg => 'No drive returned by lsdrive.')
        if ($self->{global}->{detected} == 0);
}

1;

__END__

=head1 MODE

Track the drives: FlashCore Module wear, NVMe paths and physical fill, per
drive.

The concise C<lsdrive> view only carries status and capacity; everything that
makes drive B<tracking> lives in the detailed per-drive view (one call per
drive): C<write_endurance_used>, the two path statuses, the physical fill and
the predicted C<replacement_date>.

Drive B<status> stays with the C<hardware> mode, which already covers every
drive among its components, carrying it here too would double each alert.
This mode alerts, by default, on a fallen path or a predicted end of life.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=drives --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure \
        --warning-endurance=80 --critical-endurance=90

=over 8

=item B<--include-id>

Filter drives by id (can be a regexp).

=item B<--exclude-id>

Exclude drives by id (can be a regexp).

=item B<--unknown-path-status>

Define the conditions to match for the path status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{paths_online}>,
C<%{paths_total}>, C<%{port_1_status}>, C<%{port_2_status}>, C<%{use}>,
C<%{firmware}>. Paths without a known state are not counted in
C<%{paths_total}>.

=item B<--warning-path-status>

Define the conditions to match for the path status to be WARNING
(default: C<'%{paths_online} < %{paths_total}'>).
You can use the following variables: C<%{name}>, C<%{paths_online}>,
C<%{paths_total}>, C<%{port_1_status}>, C<%{port_2_status}>, C<%{use}>,
C<%{firmware}>.

=item B<--critical-path-status>

Define the conditions to match for the path status to be CRITICAL
(default: C<< '%{paths_total} > 0 and %{paths_online} == 0' >>).
You can use the following variables: C<%{name}>, C<%{paths_online}>,
C<%{paths_total}>, C<%{port_1_status}>, C<%{port_2_status}>, C<%{use}>,
C<%{firmware}>.

=item B<--unknown-replacement-status>

Define the conditions to match for the replacement status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{replacement_date}>.

=item B<--warning-replacement-status>

Define the conditions to match for the replacement status to be WARNING
(default: C<'%{replacement_date} ne ""'>): the array predicts an end of life.
You can use the following variables: C<%{name}>, C<%{replacement_date}>.

=item B<--critical-replacement-status>

Define the conditions to match for the replacement status to be CRITICAL.
You can use the following variables: C<%{name}>, C<%{replacement_date}>.

=item B<--warning-endurance>

Warning threshold.

Thresholds on the FlashCore Module wear, in percent. No default in the code:
the values are set in the service template macro (80/90 suggested). Observed
on these arrays after their first months: 0 %.

=item B<--critical-endurance>

Critical threshold.

Thresholds on the FlashCore Module wear, in percent. No default in the code:
the values are set in the service template macro (80/90 suggested). Observed
on these arrays after their first months: 0 %.

=item B<--warning-physical-usage-prct>

Warning threshold.

Thresholds on the physical fill of each module. The system-level threshold in
the capacity mode is the one that matters; the per-drive figure exists to spot
an unbalanced distribution.

=item B<--critical-physical-usage-prct>

Critical threshold.

Thresholds on the physical fill of each module. The system-level threshold in
the capacity mode is the one that matters; the per-drive figure exists to spot
an unbalanced distribution.

=back

=cut
