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

package centreon::common::xppc::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
                key_values => [ { name => 'upsSmartInputFrequency', no_value => 0 } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { value => 'upsSmartInputFrequency', template => '%.2f', 
                      unit => 'Hz' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'lines.input.voltage.volt', set => {
                key_values => [ { name => 'upsSmartInputLineVoltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { value => 'upsSmartInputLineVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Input lines ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    upsSmartInputLineVoltage => { oid => '.1.3.6.1.4.1.935.1.1.1.3.2.1' }, # in dV
    upsSmartInputFrequency   => { oid => '.1.3.6.1.4.1.935.1.1.1.3.2.4' }, # in tenth of Hz
};

sub manage_selection {
    my ($self, %options) = @_;
 
     my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $result->{upsSmartInputLineVoltage} = defined($result->{upsSmartInputLineVoltage}) ? $result->{upsSmartInputLineVoltage} * 0.1 : 0;
    $result->{upsSmartInputFrequency} = defined($result->{upsSmartInputFrequency}) ? $result->{upsSmartInputFrequency} * 0.1 : 0;
    $self->{global} = $result;
}

1;

__END__

=head1 MODE

Check input lines metrics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'frequence', 'voltage'.

=back

=cut
