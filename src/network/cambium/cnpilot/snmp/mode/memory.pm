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

package network::cambium::cnpilot::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{name} . "' ";
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'used: %.2f %%',
        $self->{result_values}->{used}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memories are ok' }
    ];

     $self->{maps_counters}->{memory} = [
        { label => 'memory-usage-prct', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name'}
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

    # Select relevant oids for Memory monitoring
    my $mapping = {
        cambiumAPName       => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.2' },
        cambiumAPMemoryFree => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.7' }
    };

    # Point at the begining of the table 
    my $oid_cambiumAccessPointEntry = '.1.3.6.1.4.1.17713.22.1.1.1';

    my $memory_result = $options{snmp}->get_table(
        oid => $oid_cambiumAccessPointEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$memory_result}) {
        next if ($oid !~ /^$mapping->{cambiumAPName}->{oid}\.(.*)$/);
        # Catch instance in table
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $memory_result, instance => $instance);

        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $result->{cambiumAPName} !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cambiumAPName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{memory}->{$instance} = {
            name => $result->{cambiumAPName},
            free => $result->{cambiumAPMemoryFree},
            used => 100 - $result->{cambiumAPMemoryFree}
        };
    }

    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP matching with filter found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--filter-ap>

Filter on one or several AP.

=item B<--warning>

Warning threshold for Memory.

=item B<--critical>

Critical threshold for Memory.

=back

=cut
