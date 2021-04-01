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

package hardware::devices::aeg::acm::snmp::mode::loadstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'voltage', set => {
                key_values => [ { name => 'loadVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'loadVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'loadCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'loadCurrent', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'power', set => {
                key_values => [ { name => 'loadPower' } ],
                output_template => 'Power : %s W',
                perfdatas => [
                    { label => 'power', value => 'loadPower', template => '%s', 
                      unit => 'w'},
                ],
            }
        },
    ];
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mapping_acm1000 = {
    loadVoltage     => { oid => '.1.3.6.1.4.1.15416.37.3.1', divider => '100' },
    loadCurrent     => { oid => '.1.3.6.1.4.1.15416.37.3.2', divider => '100' },
    loadPower       => { oid => '.1.3.6.1.4.1.15416.37.3.3' },
};
my $mapping_acmi1000 = {
    loadVoltage     => { oid => '.1.3.6.1.4.1.15416.38.3.1', divider => '100' },
    loadCurrent     => { oid => '.1.3.6.1.4.1.15416.38.3.2', divider => '100' },
    loadPower       => { oid => '.1.3.6.1.4.1.15416.38.3.3' },
};
my $mapping_acm1d = {
    loadVoltage     => { oid => '.1.3.6.1.4.1.15416.29.4.1' },
    loadCurrent     => { oid => '.1.3.6.1.4.1.15416.29.4.2' },
};
my $oid_acm1000Load = '.1.3.6.1.4.1.15416.37.3';
my $oid_acmi1000Load = '.1.3.6.1.4.1.15416.38.3';
my $oid_acm1dLoad = '.1.3.6.1.4.1.15416.29.4';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_acm1000Load },
                                                                    { oid => $oid_acmi1000Load },
                                                                    { oid => $oid_acm1dLoad },
                                                                  ],
                                                          nothing_quit => 1);
                                                         
    my $result_acm1000 = $options{snmp}->map_instance(mapping => $mapping_acm1000, results => $self->{results}->{$oid_acm1000Load}, instance => '0');
    my $result_acmi1000 = $options{snmp}->map_instance(mapping => $mapping_acmi1000, results => $self->{results}->{$oid_acmi1000Load}, instance => '0');
    my $result_acm1d = $options{snmp}->map_instance(mapping => $mapping_acm1d, results => $self->{results}->{$oid_acm1dLoad}, instance => '0');

    foreach my $name (keys %{$mapping_acm1000}) {
        if (defined($result_acm1000->{$name})) {
            $self->{global}->{$name} = $result_acm1000->{$name};
            $self->{global}->{$name} = $result_acm1000->{$name} / $mapping_acm1000->{$name}->{divider} if defined($mapping_acm1000->{$name}->{divider});
        }
    }
    foreach my $name (keys %{$mapping_acmi1000}) {
        if (defined($result_acmi1000->{$name})) {
            $self->{global}->{$name} = $result_acmi1000->{$name};
            $self->{global}->{$name} = $result_acmi1000->{$name} / $mapping_acmi1000->{$name}->{divider} if defined($mapping_acmi1000->{$name}->{divider});
        }
    }
    foreach my $name (keys %{$mapping_acm1d}) {
        $self->{global}->{$name} = $result_acm1d->{$name} unless (!defined($result_acm1d->{$name}));
    }
}

1;

__END__

=head1 MODE

Check load plant statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^current$'

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'power'.

=back

=cut
