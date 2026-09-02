#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Drive tracking: wear, paths and fill, per drive.
#
# The concise lsdrive view only carries status and capacity. Everything that
# makes drive TRACKING lives in the detailed view, one call per drive:
#
#   write_endurance_used     FlashCore Module wear, in % - the long-term
#                            metric of a flash drive
#   port_1/2_status          the two NVMe paths to the drive
#   physical_used_capacity   real physical fill of the module
#   replacement_date         set when IBM predicts an end of life
#
# Drive STATUS stays with the hardware mode, which already covers every drive
# among its components: carrying it here too would double each alert. This
# mode covers what hardware does not see - path redundancy, wear and fill -
# and by default only alerts on a fallen path or a predicted end of life.
#
# Wear thresholds are not coded here: they are set on the service side
# (--warning-endurance=80 --critical-endurance=90), visible and adjustable in
# Centreon.
#

package storage::ibm::flashsystem::restapi::mode::drives;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_drive_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'paths %s/%s, use: %s',
        $self->{result_values}->{port_1_status},
        $self->{result_values}->{port_2_status},
        $self->{result_values}->{use}
    );
    $msg .= sprintf(', firmware %s', $self->{result_values}->{firmware})
        if ($self->{result_values}->{firmware} ne '-');
    # A replacement date is only set when the array predicts an end of life:
    # when it exists, it is the most important piece of information.
    $msg .= sprintf(', REPLACEMENT PREDICTED %s', $self->{result_values}->{replacement_date})
        if ($self->{result_values}->{replacement_date} ne '-');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Drives: ';
}

sub prefix_drive_output {
    my ($self, %options) = @_;

    return sprintf(
        "Drive '%s' (enclosure %s slot %s) ",
        $options{instance_value}->{display},
        $options{instance_value}->{enclosure},
        $options{instance_value}->{slot}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'drives', type => 1, cb_prefix_output => 'prefix_drive_output',
          message_multiple => 'All drives have both paths online', skipped_code => { -10 => 1 } }
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
        # Drive status belongs to the hardware mode: here we watch REDUNDANCY. A
        # path down while the drive still serves is exactly the fault a global
        # status does not show.
        {
            label => 'status',
            type => 2,
            critical_default => '%{port_1_status} !~ /^online$/i and %{port_2_status} !~ /^online$/i',
            warning_default => '%{port_1_status} !~ /^online$/i or %{port_2_status} !~ /^online$/i or %{replacement_date} ne "-"',
            set => {
                key_values => [
                    { name => 'display' }, { name => 'use' },
                    { name => 'port_1_status' }, { name => 'port_2_status' },
                    { name => 'replacement_date' }, { name => 'firmware' }
                ],
                closure_custom_output => $self->can('custom_drive_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        # Wear only goes one way: the curve is the real deliverable, the threshold
        # is set on the service side.
        { label => 'endurance', nlabel => 'drive.endurance.used.percentage', set => {
                key_values => [ { name => 'endurance' }, { name => 'display' } ],
                output_template => 'endurance used %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100,
                                 label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'physical-usage-prct', nlabel => 'drive.physical.space.usage.percentage', set => {
                key_values => [ { name => 'physical_used_prct' }, { name => 'display' } ],
                output_template => 'physical used %.2f %%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100,
                                 label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s' => { name => 'filter_id' }
    });

    return $self;
}

sub field {
    my ($entry, $name) = @_;

    return '-' if (!defined($entry->{$name}) || $entry->{$name} eq '');
    return $entry->{$name};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    $self->{drives} = {};

    foreach my $drive (@{ $options{custom}->request(command => 'lsdrive') }) {
        next unless (ref $drive eq 'HASH' && defined($drive->{id}) && $drive->{id} =~ /^\d+$/);

        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne ''
            && $drive->{id} !~ /$self->{option_results}->{filter_id}/);

        # Everything that makes the tracking is in the detailed view. A dozen
        # calls per check: the token is cached, the cost is low.
        my $detail = $options{custom}->request_optional(command => 'lsdrive/' . $drive->{id})->[0];
        $detail = $drive unless (ref $detail eq 'HASH');

        $self->{global}->{detected}++;

        my $entry = {
            display => $drive->{id},
            enclosure => field($detail, 'enclosure_id'),
            slot => field($detail, 'slot_id'),
            use => field($detail, 'use'),
            port_1_status => field($detail, 'port_1_status'),
            port_2_status => field($detail, 'port_2_status'),
            replacement_date => field($detail, 'replacement_date'),
            firmware => field($detail, 'firmware_level')
        };
        # firmware_level comes with trailing spaces on some firmwares.
        $entry->{firmware} =~ s/\s+$//;

        my $endurance = $detail->{write_endurance_used};
        $entry->{endurance} = $endurance
            if (defined($endurance) && $endurance =~ /^\d+(?:\.\d+)?$/);

        my $ptot = $options{custom}->size_to_bytes(value => $detail->{physical_capacity});
        my $pused = $options{custom}->size_to_bytes(value => $detail->{physical_used_capacity});
        $entry->{physical_used_prct} = $pused * 100 / $ptot
            if (defined($ptot) && defined($pused) && $ptot > 0);

        $self->{drives}->{ $drive->{id} } = $entry;
    }

    if ($self->{global}->{detected} == 0) {
        $self->{output}->add_option_msg(short_msg => 'No drive returned by lsdrive.');
        $self->{output}->option_exit();
    }
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
drive among its components — carrying it here too would double each alert.
This mode alerts, by default, on a fallen path or a predicted end of life.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=drives --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure \
        --warning-endurance=80 --critical-endurance=90

=over 8

=item B<--filter-id>

Only check drives whose id matches this regular expression.

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each drive. Available macros: C<display>, C<use>,
C<port_1_status>, C<port_2_status>, C<replacement_date>, C<firmware>.

Default critical:
C<%{port_1_status} !~ /^online$/i and %{port_2_status} !~ /^online$/i> — both
NVMe paths down, the drive is unreachable.

Default warning:
C<%{port_1_status} !~ /^online$/i or %{port_2_status} !~ /^online$/i or %{replacement_date} ne "-">
— one path left, or an end of life the array predicts.

=item B<--warning-endurance> B<--critical-endurance>

Thresholds on the FlashCore Module wear, in percent. No default in the code:
the values are set in the service template macro (80/90 suggested). Observed
on these arrays after their first months: 0 %.

=item B<--warning-physical-usage-prct> B<--critical-physical-usage-prct>

Thresholds on the physical fill of each module. The system-level threshold in
the capacity mode is the one that matters; the per-drive figure exists to spot
an unbalanced distribution.

=back

=cut
