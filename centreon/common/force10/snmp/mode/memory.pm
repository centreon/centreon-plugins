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

package centreon::common::force10::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => '%s %%', output_error_template => "%s",
                perfdatas => [
                    { label => 'used', value => 'usage', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' Usage ";
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
        MemUsageUtil    => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.9.1.5' },
    },
    mseries => {
        MemUsageUtil    => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.8.1.5' },
    },
    zseries => {
        MemUsageUtil    => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.3.1.4' },
    },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oids = { sseries => '.1.3.6.1.4.1.6027.3.10.1.2.9.1', mseries => '.1.3.6.1.4.1.6027.3.19.1.2.8.1', zseries => '.1.3.6.1.4.1.6027.3.25.1.2.3.1' };
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ { oid => $oids->{sseries} }, { oid => $oids->{mseries} }, { oid => $oids->{zseries} } ], 
        nothing_quit => 1
    );

    $self->{memory} = {};
    foreach my $name (keys %{$oids}) {
        foreach my $oid (keys %{$snmp_result->{$oids->{$name}}}) {
            next if ($oid !~ /^$mapping->{$name}->{MemUsageUtil}->{oid}\.(.*)/);
            my $instance = $1;
            my $result = $options{snmp}->map_instance(mapping => $mapping->{$name}, results => $snmp_result->{$oids->{$name}}, instance => $instance);
        
            $self->{memory}->{$instance} = {
                display => $instance, 
                usage => $result->{MemUsageUtil},
            };
        }
    }
    
    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
