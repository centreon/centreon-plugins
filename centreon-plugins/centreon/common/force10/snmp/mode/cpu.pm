#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::force10::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => '5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'usage_5s' }, { name => 'display' } ],
                output_template => '%s %% (5sec)', output_error_template => "%s (5sec)",
                perfdatas => [
                    { label => 'cpu_5s', value => 'usage_5s', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => '1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'usage_1m' }, { name => 'display' } ],
                output_template => '%s %% (1m)', output_error_template => "%s (1min)",
                perfdatas => [
                    { label => 'cpu_1m', value => 'usage_1m', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => '5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'usage_5m' }, { name => 'display' } ],
                output_template => '%s %% (5min)', output_error_template => "%s (5min)",
                perfdatas => [
                    { label => 'cpu_5m', value => 'usage_5m', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
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

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' Usage ";
}

my $mapping = {
    sseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.2' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.3' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.4' },
    },
    mseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.2' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.3' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.4' },
    },
    zseries => {
        Util5Sec    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.1' },
        Util1Min    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.2' },
        Util5Min    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.3' },
    },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oids = { sseries => '.1.3.6.1.4.1.6027.3.10.1.2.9.1', mseries => '.1.3.6.1.4.1.6027.3.19.1.2.8.1', zseries => '.1.3.6.1.4.1.6027.3.25.1.2.3.1' };
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ { oid => $oids->{sseries} }, { oid => $oids->{mseries} }, { oid => $oids->{zseries} } ], 
        nothing_quit => 1
    );

    $self->{cpu} = {};
    foreach my $name (keys %{$oids}) {
        foreach my $oid (keys %{$snmp_result->{$oids->{$name}}}) {
            next if ($oid !~ /^$mapping->{$name}->{Util5Min}->{oid}\.(.*)/);
            my $instance = $1;
            my $result = $options{snmp}->map_instance(mapping => $mapping->{$name}, results => $snmp_result->{$oids->{$name}}, instance => $instance);
        
            $self->{cpu}->{$instance} = { 
                display => $instance, 
                usage_5s => $result->{Util5Sec},
                usage_1m => $result->{Util1Min},
                usage_5m => $result->{Util5Min},
            };
        }
    }
    
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check cpu usages.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: '5s', '1m', '5m'.

=item B<--critical-*>

Threshold critical.
Can be: '5s', '1m', '5m'.

=back

=cut
