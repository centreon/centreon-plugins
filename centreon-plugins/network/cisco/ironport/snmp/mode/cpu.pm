#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::cisco::ironport::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'mail', set => {
                key_values => [ { name => 'perCentCPUUtilization' } ],
                output_template => 'CPU Mail usage is: %.2f%%',
                perfdatas => [
                    { label => 'cpu_mail', value => 'perCentCPUUtilization_absolute', template => '%.2f', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'websecurity', set => {
                key_values => [ { name => 'cacheCpuUsage' } ],
                output_template => 'CPU WebSecurity usage is: %.2f%%',
                perfdatas => [
                    { label => 'cpu_websecurity', value => 'cacheCpuUsage_absolute', template => '%.2f', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %oids = (
        perCentCPUUtilization => '.1.3.6.1.4.1.15497.1.1.1.2.0',
        cacheCpuUsage => '.1.3.6.1.4.1.15497.1.2.3.1.2.0',
    );
    my $result = $options{snmp}->get_leef(oids => [values %oids], nothing_quit => 1);
    $self->{global} = {};
    foreach (keys %oids) {
        $self->{global}->{$_} = $result->{$oids{$_}} if (defined($result->{$oids{$_}}));
    }
}

1;

__END__

=head1 MODE

Check cpu usage of web security and mail (ASYNCOS-MAIL-MIB, ASYNCOSWEBSECURITYAPPLIANCE-MIB).
Use linux SNMP plugin for global CPU.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'mail', 'websecurity'.

=item B<--critical-*>

Threshold critical.
Can be: 'mail', 'websecurity'.

=back

=cut
