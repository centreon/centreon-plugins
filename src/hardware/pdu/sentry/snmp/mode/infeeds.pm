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

package hardware::pdu::sentry::snmp::mode::infeeds;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_overall_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s - load status: %s",
        $self->{result_values}->{status},
        $self->{result_values}->{load_status}
    );
}

sub prefix_infeed_output {
    my ($self, %options) = @_;

    return sprintf("Infeed '%s' ", $options{instance_value}->{display});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'infeed',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_infeed_output',
            message_multiple => 'All current infeeds are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{infeed} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            unknown_default  => '%{status} =~ /noComm/i || %{load_status} =~ /noComm|readError/i',
            warning_default  => '%{load_status} =~ /loadLow/i',
            critical_default => '%{status} =~ /error/i || %{load_status} =~ /loadHigh|overLoad/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'status' },
                        { name => 'load_status' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_overall_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'voltage', nlabel => 'infeed.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'voltage' }, { name => 'display' } ],
            output_template => 'Voltage : %.2f V',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'V',
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        },
        { label => 'load', nlabel => 'infeed.load.ampere', display_ok => 0, set => {
            key_values      => [ { name => 'load' }, { name => 'display' } ],
            output_template => 'Load : %.2f A',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'A',
                    min                  => 0,
                    max                  => 'capacity',
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        },
        { label => 'load-prct', nlabel => 'infeed.load.percentage', display_ok => 1, set => {
            key_values      => [ { name => 'load_prct' }, { name => 'display' } ],
            output_template => 'Load : %.2f %%',
            perfdatas       => [
                {
                    template             => '%.2f',
                    unit                 => '%',
                    min                  => 0,
                    max                  => 100,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        },
        { label => 'power', nlabel => 'infeed.power.watt', display_ok => 0, set => {
            key_values      => [ { name => 'power' }, { name => 'display' } ],
            output_template => 'power: %s W',
            perfdatas       => [
                {
                    template             => '%d',
                    unit                 => 'W',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'include-infeed:s' => { name => 'include_infeed' },
            'exclude-infeed:s' => { name => 'exclude_infeed' }
        });

    return $self;
}

my $infeed_status = {
    0 => 'off',
    1 => 'on',
    2 => 'offWait',
    3 => 'onWait',
    4 => 'offError',
    5 => 'onError',
    6 => 'noComm',
    7 => 'reading',
    8 => 'offFuse',
    9 => 'onFuse'
};

my $infeed_load_status = {
    0 => 'normal',
    1 => 'notOn',
    2 => 'reading',
    3 => 'loadLow',
    4 => 'loadHigh',
    5 => 'overLoad',
    6 => 'readError',
    7 => 'noComm'
};

my $mapping = {
    infeedID         => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.2' },
    infeedName       => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.3' },
    infeedStatus     => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.5', map => $infeed_status },
    infeedLoadStatus => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.6', map => $infeed_load_status },
    infeedLoadValue  => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.7' },
    infeedCapacity   => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.10' },
    infeedVoltage    => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.11' },
    infeedPower      => { oid => '.1.3.6.1.4.1.1718.3.2.2.1.12' }
};

my $oid_infeedEntry = '.1.3.6.1.4.1.1718.3.2.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_infeedEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{infeedID}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        next if is_excluded(
            $result->{infeedID},
            $self->{option_results}->{include_infeed},
            $self->{option_results}->{exclude_infeed}
        );

        $self->{infeed}->{$result->{infeedID}} =
            {
                display     => $result->{infeedName},
                voltage     => $result->{infeedVoltage} * 0.1,
                load        => $result->{infeedLoadValue} * 0.01,
                load_prct   => defined($result->{infeedCapacity}) && $result->{infeedCapacity} > 0 ?
                    $result->{infeedLoadValue} * 0.01 / $result->{infeedCapacity} * 100 : undef,
                capacity    => $result->{infeedCapacity},
                power       => $result->{infeedPower},
                status      => $result->{infeedStatus},
                load_status => $result->{infeedLoadStatus},
            };

    }

    if (scalar(keys %{$self->{infeed}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No infeeds matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check C<infeeds> current.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='active-power'>

=item B<--include-infeed>

Filter C<infeed> by number (can be a regexp).
Example: C<--include-infeed='Master_A'>

=item B<--exclude-infeed>

Exclude C<infeed> by number (can be a regexp).
Example: C<--exclude-infeed='Master_B'>

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN. (default: '%{status} =~ /noComm/i || %{load_status} =~ /noComm|readError/i').
You can use the following variables: C<%{status}>, C<%{load_status}>, C<%{display}>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: '%{load_status} =~ /loadLow/i').
You can use the following variables: C<%{status}>, C<%{load_status}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: '%{status} =~ /error/i || %{load_status} =~ /loadHigh|overLoad/i').
You can use the following variables: C<%{status}>, C<%{display}>

=item B<--warning-voltage>

Warning threshold. (V)

=item B<--critical-voltage>

Critical threshold. (V)

=item B<--warning-load>

Warning threshold. (A)

=item B<--critical-load>

Critical threshold. (A)

=item B<--warning-load-prct>

Warning threshold. (%)

=item B<--critical-load-prct>

Critical threshold. (%)

=item B<--warning-power>

Warning threshold. (W)

=item B<--critical-power>

Critical threshold. (W)

=back

=cut
