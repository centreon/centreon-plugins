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

package network::juniper::common::junos::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_seamsg_output', message_multiple => 'All CPU(s) average usages are ok' },
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'utilization', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'display' } ],
                output_template => 'average usage is: %.2f%%',
                perfdatas => [
                    { label => 'cpu', value => 'cpu_usage', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'load-1m', nlabel => 'cpu.load.1m.percentage', display_ok => 0, set => {
                key_values => [ { name => 'cpu_load1' }, { name => 'display' } ],
                output_template => 'load 1min: %s',
                perfdatas => [
                    { label => 'load1', value => 'cpu_load1', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'load-5m', nlabel => 'cpu.load.5m.percentage', display_ok => 0, set => {
                key_values => [ { name => 'cpu_load5' }, { name => 'display' } ],
                output_template => 'load 5min: %s',
                perfdatas => [
                    { label => 'load5', value => 'cpu_load5', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'load-15m', nlabel => 'cpu.load.15m.percentage', display_ok => 0, set => {
                key_values => [ { name => 'cpu_load15' }, { name => 'display' } ],
                output_template => 'load 15min: %s',
                perfdatas => [
                    { label => 'load15', value => 'cpu_load15', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_seamsg_output {
    my ($self, %options) = @_;

    return "CPU(s) '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter:s' => { name => 'filter', default => 'routing|fpc' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_jnxOperatingDescr = '.1.3.6.1.4.1.2636.3.1.13.1.5';
    my $oid_jnxOperatingCPU = '.1.3.6.1.4.1.2636.3.1.13.1.8';
    my $oid_jnxOperating1MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.20';
    my $oid_jnxOperating5MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.21';
    my $oid_jnxOperating15MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.22';

    my $result = $options{snmp}->get_table(oid => $oid_jnxOperatingDescr, nothing_quit => 1);
    my $routing_engine_find = 0;
    my @oids_routing_engine = ();
    foreach my $oid (keys %$result) {        
        if ($result->{$oid} =~ /$self->{option_results}->{filter}/i) {
            $routing_engine_find = 1;
            push @oids_routing_engine, $oid;
        }
    }

    if ($routing_engine_find == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find operating with '$self->{option_results}->{filter}' in description.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [$oid_jnxOperatingCPU, $oid_jnxOperating1MinLoadAvg, $oid_jnxOperating5MinLoadAvg, $oid_jnxOperating15MinLoadAvg],
        instances => \@oids_routing_engine,
        instance_regexp => "^" . $oid_jnxOperatingDescr . '\.(.+)'
    );
    my $result2 = $options{snmp}->get_leef();

    foreach my $oid_routing_engine (@oids_routing_engine) {
        $oid_routing_engine =~ /^$oid_jnxOperatingDescr\.(.+)/;
        my $instance = $1;
        
        $self->{cpu}->{$instance} = {
            display => $result->{$oid_jnxOperatingDescr . '.' . $instance},
            cpu_usage => $result2->{$oid_jnxOperatingCPU . '.' . $instance},
            cpu_load1 => $result2->{$oid_jnxOperating1MinLoadAvg . '.' . $instance},
            cpu_load5 => $result2->{$oid_jnxOperating5MinLoadAvg . '.' . $instance},
            cpu_load15 => $result2->{$oid_jnxOperating15MinLoadAvg . '.' . $instance}
        };
    }
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--filter>

Filter operating (Default: 'routing|fpc').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'utilization', 'load-1m', 'load-5m', 'load-15m'.

=back

=cut
