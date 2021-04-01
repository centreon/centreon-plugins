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

package centreon::common::ingrian::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', },
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total CPU Usage : %.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'total', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' }, ],
                output_template => 'Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu', value => 'usage', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{cpu}}) > 1 ? return(0) : return(1);
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    naeSystemCPUDescr       => { oid => '.1.3.6.1.4.1.5595.3.2.4.1.2' },
    naeSystemCPUUtilization => { oid => '.1.3.6.1.4.1.5595.3.2.4.1.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_naeSystemStatCPUEntry = '.1.3.6.1.4.1.5595.3.2.4.1';
    my $oid_naeSystemStatCPU = '.1.3.6.1.4.1.5595.3.2.2'; # without .0
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_naeSystemStatCPU },
                                                            { oid => $oid_naeSystemStatCPUEntry },
                                                          ], nothing_quit => 1);
    
    $self->{cpu} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_naeSystemStatCPUEntry}}) {
        next if ($oid !~ /^$mapping->{naeSystemCPUUtilization}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_naeSystemStatCPUEntry}, instance => $instance);
        
        $self->{cpu}->{$instance} = { display => $instance - 1, usage => $result->{naeSystemCPUUtilization} };
    }

    $self->{global} = { total => $snmp_result->{$oid_naeSystemStatCPU}->{$oid_naeSystemStatCPU . '.0'} };
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'usage'.

=back

=cut
