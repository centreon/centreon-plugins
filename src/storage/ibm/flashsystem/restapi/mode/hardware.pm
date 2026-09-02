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
# Hardware health.
#
# lsenclosure already carries the online/total counters of every enclosure
# subsystem: power supplies, canisters, fan modules, SEMs. One command is thus
# enough where the naive approach needed four.
#
# A subsystem whose total is 0 is not fitted on that model: it is skipped and
# not counted as failed. That is what lets the same mode cover a FlashSystem
# 5300 without SEMs and an enclosure that has some.
#

package storage::ibm::flashsystem::restapi::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# The object families queried, with the displayed label. The list is walked
# as is: adding a family takes one line.
#
# id_fields: the fields where to look for the identity, in order. The first
# one set wins. Storage Virtualize objects do not all carry the same key - a
# fan module is called fan_module_id, an application quorum has neither name
# nor id and is only designated by quorum_index. Trying several fields avoids
# guessing family by family, and above all avoids the "'-'" that made the
# alert message unreadable.
my $COMPONENT_COMMANDS = [
    { command => 'lsenclosure',         label => 'enclosure' },
    { command => 'lsnodecanister',      label => 'node canister' },
    { command => 'lsenclosurecanister', label => 'expansion canister' },
    { command => 'lsenclosurepsu',      label => 'power supply' },
    { command => 'lsenclosurebattery',  label => 'battery' },
    { command => 'lsenclosurefanmodule', label => 'fan module', id_fields => [ 'fan_module_id' ] },
    { command => 'lsdrive',             label => 'drive' },
    { command => 'lsarray',             label => 'array' },
    { command => 'lsmdisk',             label => 'mdisk' },
    { command => 'lsquorum',            label => 'quorum', id_fields => [ 'quorum_index' ] }
];

# Subsystems described by an online_X / total_X pair in lsenclosure.
my $ENCLOSURE_SUBSYSTEMS = [
    { field => 'PSUs',        label => 'power supplies' },
    { field => 'canisters',   label => 'canisters' },
    { field => 'fan_modules', label => 'fan modules' },
    { field => 'sems',        label => 'secondary expander modules' }
];

sub custom_component_output {
    my ($self, %options) = @_;

    return sprintf('status: %s', $self->{result_values}->{status});
}

sub custom_subsystem_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s online: %s/%s',
        $self->{result_values}->{label},
        $self->{result_values}->{online},
        $self->{result_values}->{total}
    );
}

# Environmental counters exposed by lssystemstats. They are physical measures
# of the enclosure, not performance: their place is here.
my $ENVIRONMENT_STATS = [
    { stat => 'temp_c',  key => 'temperature', label => 'temperature', unit => 'C' },
    { stat => 'power_w', key => 'power',       label => 'power draw',  unit => 'W' }
];

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Hardware: ';
}

sub prefix_environment_output {
    my ($self, %options) = @_;

    return 'Enclosure: ';
}

sub prefix_component_output {
    my ($self, %options) = @_;

    return ucfirst($options{instance_value}->{type}) . " '" . $options{instance_value}->{name} . "' ";
}

sub prefix_subsystem_output {
    my ($self, %options) = @_;

    return "Enclosure '" . $options{instance_value}->{enclosure} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'components', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_component_output',
          message_multiple => 'All hardware components are online', skipped_code => { NO_VALUE() => 1 } },
        { name => 'environment', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_environment_output' },
        { name => 'subsystems', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_subsystem_output',
          message_multiple => 'All enclosure subsystems are fully populated', skipped_code => { NO_VALUE() => 1 } }
    ];

    # Physical measures of the enclosure. No default threshold: the right
    # setting depends on the room and the model, not on a general rule. The
    # metric is graphed in every case, which allows tuning it on what is seen.
    $self->{maps_counters}->{environment} = [
        { label => 'temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature %s C',
                perfdatas => [ { template => '%s', unit => 'C' } ]
            }
        },
        { label => 'power', nlabel => 'hardware.power.watt', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'power draw %s W',
                perfdatas => [ { template => '%s', unit => 'W', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'components-detected', nlabel => 'hardware.components.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s component(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'components-degraded', nlabel => 'hardware.components.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s not online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # CRITICAL = SERVICE lost, WARNING = REDUNDANCY lost. All this hardware is
    # redundant (2 power supplies, 2 canisters, 6 fan modules, a DRAID across
    # the drives): a 'degraded' component eats the margin, it stops nothing.
    # Confusing it with 'offline' wakes someone up for a fault that can wait
    # for business hours - and, conversely, buries the real outage among them.
    $self->{maps_counters}->{components} = [
        {
            label => 'component-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /^(offline|excluded)$/i',
            warning_default => '%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'type' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_component_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    # Same principle on the enclosure subsystems: one power supply out of two
    # is a lost redundancy (WARNING), zero power supply online is an outage
    # (CRITICAL).
    $self->{maps_counters}->{subsystems} = [
        {
            label => 'subsystem-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{online} == 0',
            warning_default => '%{online} < %{total}',
            set => {
                key_values => [ { name => 'enclosure' }, { name => 'label' }, { name => 'online' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_subsystem_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-type:s' => { name => 'filter_type' },
        'filter-name:s' => { name => 'filter_name' }
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

    $self->{global} = { detected => 0, degraded => 0 };
    $self->{environment} = {};
    $self->{components} = {};
    $self->{subsystems} = {};

    # Temperature and power draw come from lssystemstats, with the performance
    # counters - but they are physical measures of the enclosure, so they are
    # read here rather than in the performance mode.
    my %stats;
    foreach my $entry (@{ $options{custom}->request_optional(command => 'lssystemstats') }) {
        next unless (ref $entry eq 'HASH' && defined($entry->{stat_name}));
        $stats{ $entry->{stat_name} } = $entry->{stat_current};
    }
    foreach my $measure (@$ENVIRONMENT_STATS) {
        my $value = $stats{ $measure->{stat} };
        next if (!defined($value) || $value !~ /^-?\d+(?:\.\d+)?$/);
        $self->{environment}->{ $measure->{key} } = $value;
    }

    foreach my $family (@$COMPONENT_COMMANDS) {
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne ''
            && $family->{label} !~ /$self->{option_results}->{filter_type}/);

        # A family missing from the model or the firmware must not fail the
        # check of the others.
        my $entries = $options{custom}->request_optional(command => $family->{command});

        foreach my $entry (@$entries) {
            # Not every object has a 'name' field: a drive or a power supply only
            # carries an identifier. The first field set is taken, starting with
            # those specific to the family.
            my @candidates = ('name');
            push @candidates, @{ $family->{id_fields} } if (defined($family->{id_fields}));
            push @candidates, 'id';

            my $name = '-';
            foreach my $candidate (@candidates) {
                next if (!defined($entry->{$candidate}) || $entry->{$candidate} eq '');
                $name = $entry->{$candidate};
                last;
            }
            my $instance = $family->{label} . '.' . $name;

            next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
                && $name !~ /$self->{option_results}->{filter_name}/);

            my $status = field($entry, 'status');

            $self->{global}->{detected}++;
            $self->{global}->{degraded}++ if ($status !~ /^online$/i);

            $self->{components}->{$instance} = {
                name => $name,
                type => $family->{label},
                status => $status
            };

            next if ($family->{command} ne 'lsenclosure');

            # online/total counters carried by the enclosure itself.
            foreach my $subsystem (@$ENCLOSURE_SUBSYSTEMS) {
                my $online = $entry->{'online_' . $subsystem->{field}};
                my $total  = $entry->{'total_' . $subsystem->{field}};

                next if (!defined($online) || !defined($total));
                next if ($online !~ /^\d+$/ || $total !~ /^\d+$/);
                # total = 0: the subsystem does not exist on this hardware.
                next if ($total == 0);

                $self->{subsystems}->{ $name . '.' . $subsystem->{field} } = {
                    enclosure => $name,
                    label => $subsystem->{label},
                    online => $online,
                    total => $total
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check hardware health: enclosures, node and expansion canisters, power
supplies, batteries, drives, arrays, mdisks and quorum devices.

Enclosure subsystems are additionally checked through the C<online_*>/C<total_*>
counters the enclosure itself reports. A subsystem whose total is zero is not
fitted on that model and is skipped rather than counted as missing.

Families that do not exist on a given model or firmware are skipped silently,
so the same mode covers every Storage Virtualize system.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=hardware --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--filter-type>

Only check component families whose label matches this regular expression
(enclosure, node canister, expansion canister, power supply, battery, drive,
array, mdisk, quorum).

=item B<--filter-name>

Only check components whose name or id matches this regular expression.

=item B<--unknown-component-status> B<--warning-component-status> B<--critical-component-status>

Threshold on each component. Available macros: C<name>, C<type>, C<status>.

Default critical: C<%{status} =~ /^(offline|excluded)$/i>

Default warning: C<%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i>

Critical means B<service lost>, warning means B<redundancy lost>. Every part
here is redundant — two power supplies, two canisters, six fan modules, a DRAID
across twelve drives — so a degraded component eats the margin without stopping
anything. Merging the two wakes someone up for a fault that can wait for
business hours, and buries the real outage among them.

=item B<--unknown-subsystem-status> B<--warning-subsystem-status> B<--critical-subsystem-status>

Threshold on each enclosure subsystem. Available macros: C<enclosure>,
C<label>, C<online>, C<total>.

Default critical: C<%{online} == 0> — nothing left in that subsystem.

Default warning: C<%{online} E<lt> %{total}> — one power supply out of two is a
lost redundancy, not an outage.

=item B<--warning-components-degraded> B<--critical-components-degraded>

Thresholds on the number of components that are not online.

=back

=cut
