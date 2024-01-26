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

package network::fortinet::fortiadc::snmp::mode::security;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'ddos-status',
            type => 2,
            critical_default => '%{status} eq "attacking"',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'DDoS status is %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ddos = '.1.3.6.1.4.1.12356.112.7.1.0'; # fadcDDoSAttackStatus
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_ddos ],
        nothing_quit => 1
    );

    $self->{global} = { 
        status => $snmp_result->{$oid_ddos} == 1 ? 'attacking' : 'noAttack'
    };
}

1;

__END__

=head1 MODE

Check security.

=over 8

=item B<--warning-ddos-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-ddos-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "attacking"').
You can use the following variables: %{status}

=back

=cut
