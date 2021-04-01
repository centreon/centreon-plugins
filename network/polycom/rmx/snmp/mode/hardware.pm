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

package network::polycom::rmx::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['disabled', 'OK'],
            ['ok', 'OK'],
            ['failed', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'network::polycom::rmx::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'board'];
}

my %map_status = (1 => 'disabled', 2 => 'ok', 3 => 'failed');
my $mapping = {
    hardwareFanStatus               => { oid => '.1.3.6.1.4.1.13885.110.1.3.2.1', map => \%map_status },
    hardwarePowerSupplyStatus       => { oid => '.1.3.6.1.4.1.13885.110.1.3.3.1', map => \%map_status },
    hardwareIntegratedBoardStatus   => { oid => '.1.3.6.1.4.1.13885.110.1.3.4.1', map => \%map_status }
};

sub snmp_execute {
    my ($self, %options) = @_;
    
    my $oid_hardware = '.1.3.6.1.4.1.13885.110.1.3';
    push @{$self->{request}}, { oid => $oid_hardware };
    my $results = $options{snmp}->get_multiple_table(oids => $self->{request});
    $self->{results} = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_hardware}, instance => '0');
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'board'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=board --filter=psu)

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,disabled'

=back

=cut
