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

package network::cisco::umbrella::snmp::mode::connectivity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return uc($self->{result_values}->{display}) . " health: " . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dns', type => 0 },
        { name => 'localdns', type => 0 },
        { name => 'cloud', type => 0 },
        { name => 'ad', type => 0 }
    ];

    foreach ('dns', 'localdns', 'cloud', 'ad') {
        $self->{maps_counters}->{$_} = [
            {
                label => $_ . '-status', type => 2, 
                critical_default => '%{status} =~ /red/' , 
                warning_default => '%{status} =~ /yellow/', 
                unknown_default => '%{status} !~ /(green|yellow|red|white)/', 
                set => {
                    key_values => [ { name => 'status' }, { name => 'display' }],
                    closure_custom_output => $self->can('custom_status_output'),
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            }
        ];
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_dns = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.3.100.110.115.1';
    my $oid_localdns = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.8.108.111.99.97.108.100.110.115.1';
    my $oid_cloud = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.5.99.108.111.117.100.1';
    my $oid_ad = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.2.97.100.1';

    my $result = $options{snmp}->get_leef(
        oids => [ $oid_dns, $oid_localdns, $oid_cloud, $oid_ad ],
        nothing_quit => 1
    );

    foreach my $umbrella_component ('dns', 'localdns', 'cloud', 'ad') {
        my $status_output = $result->{eval("\$oid_" . "$umbrella_component")};
        if ($status_output =~ /\((.*?)\)/){
            my $status = $1;
            $self->{$umbrella_component} = { 
                display => $umbrella_component,
                status => $status
            };
        }
    }

}

1;

__END__

=head1 MODE

Check connectivity between Umbrella server and DNS, local DNS, Umbrella dashboard (cloud) and AD connectors.

=over 8

=item B<--warning-*>

Define the conditions to match for the status to be WARNING. (default: '%{status} =~ /yellow/').
Can be: 'dns-status', 'localdns-status', 'cloud-status', 'ad-status'.

Can use special variables like: %{status}, %{display}

=item B<--critical-*>

Define the conditions to match for the status to be CRITICAL. (default: %{status} =~ /red/).
Can be: 'dns-status', 'localdns-status', 'cloud-status', 'ad-status'.

Can use special variables like: %{status}, %{display}

=back

=cut
