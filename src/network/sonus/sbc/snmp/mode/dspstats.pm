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

package network::sonus::sbc::snmp::mode::dspstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s'", $self->{result_values}->{state});
}

sub prefix_dsp_output {
    my ($self, %options) = @_;

    return "DSP '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dsp', type => 1, cb_prefix_output => 'prefix_dsp_output', message_multiple => 'All DSP stats and states are ok' }
    ];

    $self->{maps_counters}->{dsp} = [
        { label => 'status', type => 2, critical_default => '%{state} eq "down"', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => \&custom_state_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu-utilization', nlabel => 'dsp.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'CPU usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'channels-active', nlabel => 'dsp.channels.active.count', set => {
                key_values => [ { name => 'channels' }, { name => 'display' } ],
                output_template => 'active channels: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my %map_status = (
    0 => 'down',
    1 => 'up'
);

my $mapping = {
    uxDSPIsPresent     => { oid => '.1.3.6.1.4.1.177.15.1.6.1.3' },
    uxDSPCPUUsage      => { oid => '.1.3.6.1.4.1.177.15.1.6.1.4' },
    uxDSPChannelsInUse => { oid => '.1.3.6.1.4.1.177.15.1.6.1.5' },
    uxDSPServiceStatus => { oid => '.1.3.6.1.4.1.177.15.1.6.1.6', map => \%map_status }
};
my $oid_uxDSPResourceTable = '.1.3.6.1.4.1.177.15.1.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_uxDSPResourceTable,
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if($oid !~ /^$mapping->{uxDSPServiceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($result->{uxDSPIsPresent} eq '0');

        $self->{dsp}->{$instance} = {
            state   => $result->{uxDSPServiceStatus},
            cpu  => $result->{uxDSPCPUUsage},
            channels  => $result->{uxDSPChannelsInUse},
            display => $instance
        };
    }
}

1;

__END__

=head1 MODE

Check Digital Signal Processing statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds. Can be: 'cpu-utilization', 'channels-active'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} eq "down"').
You can use the following variables: %{state}, %{display}

=back

=cut
