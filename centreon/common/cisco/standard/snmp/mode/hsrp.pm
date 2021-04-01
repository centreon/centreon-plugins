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

package centreon::common::cisco::standard::snmp::mode::hsrp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_row_status = (
    1 => 'active',
    2 => 'notInService',
    3 => 'notReady',
    4 => 'createAndGo',
    5 => 'createAndWait',
    6 => 'destroy'
);
my %map_states = (
    1 => 'initial',
    2 => 'learn',
    3 => 'listen',
    4 => 'speak',
    5 => 'standby',
    6 => 'active',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'role:s'        => { name => 'role', default => 'primary' },
        'filter-vrid:s' => { name => 'filter_vrid' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if ($self->{option_results}->{role} !~ /^primary|secondary$/) {
        $self->{output}->add_option_msg(short_msg => "You must use either primary either secondary for --role option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $vridout = '';
    my $oid_cHsrpGrpStandbyState = ".1.3.6.1.4.1.9.9.106.1.2.1.1.15";    # HSRP Oper Status
    my $oid_cHsrpGrpEntryRowStatus = ".1.3.6.1.4.1.9.9.106.1.2.1.1.17";   # HSRP Admin Status

    my $results = $self->{snmp}->get_multiple_table(oids => 
        [
            { oid => $oid_cHsrpGrpStandbyState },
            { oid => $oid_cHsrpGrpEntryRowStatus },
        ],
        nothing_quit => 1
    );

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Router is in its expected state : '%s'", $self->{option_results}->{role}));
    foreach my $oid (keys %{$results->{$oid_cHsrpGrpStandbyState}}) {
        $oid =~ /(\d+\.\d+)$/; 
        my $vrid = $1;

        if (defined($self->{option_results}->{filter_vrid}) && $self->{option_results}->{filter_vrid} ne '' &&
            $vrid !~ /$self->{option_results}->{filter_vrid}/) {
            $self->{output}->output_add(long_msg => "skipping vrid '" . $vrid . "': no matching filter.", debug => 1);
            next;
        }

        my $operState = $results->{$oid_cHsrpGrpEntryRowStatus}->{$oid_cHsrpGrpEntryRowStatus . "." . $vrid};
        my $adminState = $results->{$oid_cHsrpGrpStandbyState}->{$oid};

        $self->{output}->output_add(long_msg => sprintf("[Vrid : %s] [Admin Status is '%s'] [Oper Status is '%s']",
                                                        $vrid, $map_states{$adminState}, $map_row_status{$operState}));
        
        if ($map_row_status{$operState} !~ /^active$/i) {
            $self->{output}->output_add(severity => 'CRITICAL',
					                    short_msg => sprintf("VRID %s operational state is '%s'", $vrid, $map_row_status{$operState}));
        }

        if (($self->{option_results}->{role} eq 'primary' && $map_states{$adminState} !~ /^active$/) || 
            ($self->{option_results}->{role} eq 'secondary' && $map_states{$adminState} !~ /^standby$/)) {
            $vridout .= sprintf("(VRID %s is '%s')", $vrid, $map_states{$adminState});
        }
    }       
    
    if ($vridout ne '') {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("%s - Router isn't in the expected state (%s)", $vridout, $self->{option_results}->{role}));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cisco HSRP (CISCO-HSRP-MIB). Trigger a critical if not in the expected state or if a VRID is not in an active state.

=over 8

=item B<--filter-vrid>

Filter VRID (can be a regexp).

=item B<--role>

If role is 'primary', an error if HSRPs are 'standby' states. 
If role is 'secondary', an error if HSRPs are 'active' states. (Default: 'primary')

=back

=cut
    
