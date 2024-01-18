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

package network::aruba::aoscx::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_module_output {
    my ($self, %options) = @_;

    return sprintf(
        "module '%s' [type: %s] ",
         $options{instance_value}->{name},
         $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'modules', type => 1, cb_prefix_output => 'prefix_module_output', message_multiple => 'All memory usages are ok' }
    ];

    $self->{maps_counters}->{modules} = [
        { label => 'memory-usage-prct', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'mem_util' } ],
                output_template => 'memory used: %.2f%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-module-name:s' => { name => 'filter_module_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_memory = '.1.3.6.1.4.1.47196.4.1.1.3.22.1.0.1.1.4'; # arubaWiredSystemInfoMemory
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_memory,
        nothing_quit => 1
    );

    $self->{modules} = {};
    foreach (keys %$snmp_result) {
        /^$oid_memory\.(.*)$/;
        my @indexes = split(/\./, $1);

        my $type = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));
        my $name = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));

        next if (defined($self->{option_results}->{filter_module_name}) && $self->{option_results}->{filter_module_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_module_name}/);

        $self->{modules}->{$name} = {
            name => $name,
            type => $type,
            mem_util => $snmp_result->{$_}
        };
    }
}

1;

__END__

=head1 MODE

Check memory (worked since firmware 10.10). 

=over 8

=item B<--filter-module-name>

Filter modules by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage-prct' (%).

=back

=cut
