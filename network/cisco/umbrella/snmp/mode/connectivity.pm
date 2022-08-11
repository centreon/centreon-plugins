#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

    return  $self->{result_values}->{status} ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dns', type => 0, message_separator => ' - ' },
        { name => 'localdns', type => 0, message_separator => ' - ' },
        { name => 'cloud', type => 0, message_separator => ' - ' },
        { name => 'ad', type => 0 }
    ];

    $self->{maps_counters}->{dns} = [
        { label => 'dns-connectivity', type => 2, critical_default => '%{status} !~ /green/', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    $self->{maps_counters}->{localdns} = [
        { label => 'localdns-connectivity', type => 2, critical_default => '%{status} !~ /green/', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    $self->{maps_counters}->{cloud} = [
        { label => 'cloud-connectivity', type => 2, critical_default => '%{status} !~ /green/', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    $self->{maps_counters}->{ad} = [
        { label => 'ad-connectivity', type => 2, critical_default => '%{status} !~ /green/', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_dnsConnectivity = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.3.100.110.115.1';
    my $oid_localdnsConnectivity = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.8.108.111.99.97.108.100.110.115.1';
    my $oid_cloudConnectivity = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.5.99.108.111.117.100.1';
    my $oid_cloudAd = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.2.97.100.1';

    my $result = $options{snmp}->get_leef(
        oids => [ $oid_dnsConnectivity, $oid_localdnsConnectivity, $oid_cloudConnectivity, $oid_cloudAd ],
        nothing_quit => 1
    );

    $self->{dns} = { 
        status => $result->{$oid_dnsConnectivity}
    };
    $self->{localdns} = { 
        status => $result->{$oid_localdnsConnectivity}
    };
    $self->{cloud} = { 
        status => $result->{$oid_cloudConnectivity}
    };
    $self->{ad} = { 
        status => $result->{$oid_cloudAd}
    };
}

1;

__END__

=head1 MODE

Check connectivity between Umbrella server and dns, localdns, cloud and ad.

=over 8

=item B<--warning-*>

Set warning threshold for status. (Default: '%{status} =~ /green/').
Can be: 'dns-connectivity', 'localdns-connectivity', 'cloud-connectivity', 'ad-connectivity'.
Can used special variables like: %{status}

=item B<--critical-*>

Set critical threshold for status. (Default: '%{status} =~ /green/').
Can be: 'dns-connectivity', 'localdns-connectivity', 'cloud-connectivity', 'ad-connectivity'.

Can used special variables like: %{status}

=back

=cut
