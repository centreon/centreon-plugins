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

package centreon::common::force10::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' usage ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => '5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_5s' }, { name => 'display' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { label => 'cpu_5s', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => '1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'cpu_1m', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => '5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'cpu_5m', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
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

my $mapping = {
    sseries => {
        cpu_5s => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.2' }, # chStackUnitCpuUtil5Sec
        cpu_1m => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.3' }, # chStackUnitCpuUtil1Min
        cpu_5m => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.4' }  # chStackUnitCpuUtil5Min
    },
    mseries => {
        cpu_5s => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.2' }, # chStackUnitCpuUtil5Sec
        cpu_1m => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.3' }, # chStackUnitCpuUtil1Min
        cpu_5m => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.4' }  # chStackUnitCpuUtil5Min
    },
    zseries => {
        cpu_5s => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.1' }, # chSysCpuUtil5Sec
        cpu_1m => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.2' }, # chSysCpuUtil1Min
        cpu_5m => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.3' }  # chSysCpuUtil5Min
    },
    os9 => {
        cpu_5s => { oid => '.1.3.6.1.4.1.6027.3.26.1.4.4.1.1' }, # dellNetCpuUtil5Sec
        cpu_1m => { oid => '.1.3.6.1.4.1.6027.3.26.1.4.4.1.4' }, # dellNetCpuUtil1Min
        cpu_5m => { oid => '.1.3.6.1.4.1.6027.3.26.1.4.4.1.5' }  # dellNetCpuUtil5Min
    }
};
my $map_device_type = {
    1 => 'chassis', 2 => 'stack', 3 => 'rpm', 4 => 'supervisor', 5 => 'linecard', 6 => 'port-extender'
};

sub load_series {
    my ($self, %options) = @_;

    foreach my $oid (keys %{$options{snmp_result}}) {
        next if ($oid !~ /^$mapping->{ $options{name} }->{cpu_5m}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{name} }, results => $options{snmp_result}, instance => $instance);

        $self->{cpu}->{$instance} = { 
            display => $instance, 
            %$result
        };
    }
}

sub load_os9 {
    my ($self, %options) = @_;

    foreach my $oid (keys %{$options{snmp_result}}) {
        next if ($oid !~ /^$mapping->{ $options{name} }->{cpu_5m}->{oid}\.(\d+)\.(\d+)\.(\d+)/);
        my $name = $map_device_type->{$1} . ':' . $2 . ':' . $3;
        my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{name} }, results => $options{snmp_result}, instance => $1 . '.' . $2 . '.' . $3);

        $self->{cpu}->{$name} = { 
            display => $name, 
            %$result
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oids = {
        sseries => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1', load => $self->can('load_series') },
        mseries => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1', load => $self->can('load_series') },
        zseries => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1', load => $self->can('load_series') },
        os9     => { oid => '.1.3.6.1.4.1.6027.3.26.1.4.4.1', load => $self->can('load_os9') }
    };
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{sseries}->{oid}, start => $mapping->{sseries}->{cpu_5s}->{oid}, end => $mapping->{sseries}->{cpu_5m}->{oid} },
            { oid => $oids->{mseries}->{oid}, start => $mapping->{mseries}->{cpu_5s}->{oid}, end => $mapping->{mseries}->{cpu_5m}->{oid} },
            { oid => $oids->{zseries}->{oid}, end => $mapping->{zseries}->{cpu_5m}->{oid} },
            { oid => $oids->{os9}->{oid}, end => $mapping->{os9}->{cpu_5m}->{oid} }
        ], 
        nothing_quit => 1
    );

    $self->{cpu} = {};
    foreach my $name (keys %$oids) {
        $oids->{$name}->{load}->(
            $self,
            name => $name,
            snmp => $options{snmp},
            snmp_result => $snmp_result->{ $oids->{$name}->{oid} }
        );
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
