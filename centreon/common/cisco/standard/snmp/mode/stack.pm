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

package centreon::common::cisco::standard::snmp::mode::stack;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_role = (
    1 => 'master',
    2 => 'member',
    3 => 'notMember',
    4 => 'standby'
);
my %states = (
    1 => ['waiting', 'WARNING'], 
    2 => ['progressing', 'WARNING'], 
    3 => ['added', 'WARNING'], 
    4 => ['ready', 'OK'],
    5 => ['sdmMismatch', 'CRITICAL'],
    6 => ['verMismatch', 'CRITICAL'],
    7 => ['featureMismatch', 'CRITICAL'],
    8 => ['newMasterInit', 'WARNING'],
    9 => ['provisioned', 'OK'],
    10 => ['invalid', 'WARNING'],
    11 => ['removed', 'WARNING'],
);

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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_cswRingRedundant = '.1.3.6.1.4.1.9.9.500.1.1.3';
    my $oid_cswSwitchRole = '.1.3.6.1.4.1.9.9.500.1.2.1.1.3';
    my $oid_cswSwitchState = '.1.3.6.1.4.1.9.9.500.1.2.1.1.6';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_cswRingRedundant },
                                                            { oid => $oid_cswSwitchState },
                                                            { oid => $oid_cswSwitchRole }
                                                            ],
                                                   nothing_quit => 1);    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Stack ring is redundant');
    if ($results->{$oid_cswRingRedundant}->{$oid_cswRingRedundant . '.0'} != 1) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => 'Stack ring is not redundant');
    }
    
    foreach my $oid (keys %{$results->{$oid_cswSwitchState}}) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $state = $results->{$oid_cswSwitchState}->{$oid};
        my $role = defined($results->{$oid_cswSwitchRole}->{$oid_cswSwitchRole . '.' . $instance}) ? $results->{$oid_cswSwitchRole}->{$oid_cswSwitchRole . '.' . $instance} : 'unknown';
        # .1001, .2001 the instance.
        my $number = int(($instance - 1) / 1000);
        
        $self->{output}->output_add(long_msg => sprintf("Member '%s' state is %s [Role is '%s']", $number,
                                            ${$states{$state}}[0], $map_role{$role}));
        if (${$states{$state}}[1] ne 'OK') {
             $self->{output}->output_add(severity => ${$states{$state}}[1],
                                        short_msg => sprintf("Member '%s' state is %s", $number,
                                                             ${$states{$state}}[0]));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cisco Stack (CISCO-STACKWISE-MIB).

=over 8

=back

=cut
    