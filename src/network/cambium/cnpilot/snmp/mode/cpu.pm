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

package network::cambium::cnpilot::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{name} . "' usage: ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-usage-prct', nlabel => 'cpu.usage.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'name' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'cpu', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1,  instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-ap:s' => { name => 'filter_ap' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Select relevant oids for CPU monitoring
    my $mapping = {
        cambiumAPName           => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.2' },
        cambiumAPCPUUtilization => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.6' }
    };

    # Point at the begining of the table 
    my $oid_cambiumAccessPointEntry = '.1.3.6.1.4.1.17713.22.1.1.1';

    my $cpu_result = $options{snmp}->get_table(
        oid => $oid_cambiumAccessPointEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$cpu_result}) {
        next if ($oid !~ /^$mapping->{cambiumAPName}->{oid}\.(.*)$/);
        # Catch instance in table
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $cpu_result, instance => $instance);

        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $result->{cambiumAPName} !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cambiumAPName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{cpu}->{$instance} = {
            name => $result->{cambiumAPName},
            cpu_usage => $result->{cambiumAPCPUUtilization}
        };
    }

    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP matching with filter found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-ap>

Filter on one AP name.
    
=item B<--warning>

Warning threshold for CPU.

=item B<--critical>

Critical threshold for CPU.

=back

=cut
