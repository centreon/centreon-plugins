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

package network::fortinet::fortiauthenticator::snmp::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "high-availability status is '%s'",
        $self->{result_values}->{ha_status}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    if (!defined($options{old_datas}->{$self->{instance} . '_ha_status'})) {
        $self->{error_msg} = 'buffer creation';
        return -2;
    }
    $self->{result_values}->{ha_status_last} = $options{old_datas}->{$self->{instance} . '_ha_status'};
    $self->{result_values}->{ha_status} = $options{new_datas}->{$self->{instance} . '_ha_status'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ha-status', type => 2, critical_default => '%{ha_status} ne %{ha_status_last}', set => {
                key_values => [ { name => 'ha_status' } ],
                closure_custom_calc => \&custom_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_ha_status = {
    1 => 'unknownOrDetermining', 2 => 'clusterMaster', 3 => 'clusterSlave',
    4 => 'standaloneMaster', 5 => 'loadBalancingSlave', 255 => 'disabled'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_facHaCurrentStatus = '.1.3.6.1.4.1.12356.113.1.201.1.0';
    my $result = $options{snmp}->get_leef(oids => [$oid_facHaCurrentStatus], nothing_quit => 1);

    $self->{global} = {
        ha_status => $map_ha_status->{ $result->{$oid_facHaCurrentStatus} }
    };

    $self->{cache_name} = 'fortinet_fortiauthenticator_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check high-availability status.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{ha_status}, %{ha_status_last}

=item B<--critical-status>

Set critical threshold for status (Default: '%{ha_status} ne %{ha_status_last}').
Can used special variables like: %{ha_status}, %{ha_status_last}

=back

=cut
