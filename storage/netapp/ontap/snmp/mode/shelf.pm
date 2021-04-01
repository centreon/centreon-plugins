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

package storage::netapp::ontap::snmp::mode::shelf;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(voltage|temperature|fan)$';
    
    $self->{cb_hook1} = 'init_shelf';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        communication => [
            ['initializing', 'WARNING'],
            ['transitioning', 'WARNING'],
            ['inactive', 'CRITICAL'],
            ['reconfiguring', 'WARNING'],
            ['nonexistent', 'CRITICAL'],
            ['active', 'OK'],
        ],
        raid => [
            ['initializing', 'WARNING'],
            ['reconstructionInProgress', 'WARNING'],
            ['parityVerificationInProgress', 'OK'],
            ['scrubbingInProgress', 'OK'],
            ['prefailed', 'CRITICAL'],
            ['failed', 'CRITICAL'],
            ['active', 'OK'],
        ],
        fan => [
            ['failed', 'CRITICAL'],
            ['ok', 'OK'],
        ],
        psu => [
            ['failed', 'CRITICAL'],
            ['ok', 'OK'],
        ],
        electronics => [
            ['failed', 'CRITICAL'],
            ['ok', 'OK'],
        ],
        voltage => [
            ['under critical threshold', 'CRITICAL'],
            ['under warning threshold', 'WARNING'],
            ['over critical threshold', 'CRITICAL'],
            ['over warning threshold', 'WARNING'],
            ['ok', 'OK'],
        ],
        temperature => [
            ['under critical threshold', 'CRITICAL'],
            ['under warning threshold', 'WARNING'],
            ['over critical threshold', 'CRITICAL'],
            ['over warning threshold', 'WARNING'],
            ['ok', 'OK'],
        ],
    };
    
    $self->{components_path} = 'storage::netapp::ontap::snmp::mode::components';
    $self->{components_module} = ['communication', 'psu', 'fan', 'temperature', 'voltage', 'electronics', 'raid'];
}

my $oid_enclNumber = '.1.3.6.1.4.1.789.1.21.1.1';
my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    $self->{number_shelf} = defined($self->{results}->{$oid_enclNumber}->{$oid_enclNumber . '.0'}) ? $self->{results}->{$oid_enclNumber}->{$oid_enclNumber . '.0'} : -1;
    $self->{shelf_addr} = $self->{results}->{$oid_enclChannelShelfAddr};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub init_shelf {
    my ($self, %options) = @_;

    push @{$self->{request}}, ({ oid => $oid_enclNumber }, { oid => $oid_enclChannelShelfAddr });
}

1;

__END__

=head1 MODE

Check Shelves hardware (temperatures, voltages, electronics, fan, power supplies).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'communication', 'voltage', 'temperature', 'electronics', 'raid'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=psu,41239F00647-A

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan,41239F00647-fan02

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='gfc,CRITICAL,^(?!(Online)$)'

=item B<--warning>

Set warning threshold for temperature, fan, voltage (syntax: type,regexp,threshold)
Example: --warning='41239F00647-vimm46,20' --warning='41239F00647-vimm5.*,30'

=item B<--critical>

Set critical threshold for temperature, fan, voltage (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,25' --warning='temperature,.*,35'

=back

=cut
    
