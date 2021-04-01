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

package network::aruba::instant::snmp::mode::ssidstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "Status is '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ssid', display_long => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All SSIDs are ok', type => 1 },
    ];
    
    $self->{maps_counters}->{ssid} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /enable/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $map_status = {
    0 => 'enable', 1 => 'disable'
};

my $mapping = {
    aiSSID          => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.1.7.1.2' },
    aiSSIDStatus    => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.1.7.1.3', map => $map_status },
};
my $oid_aiWlanSSIDEntry = '.1.3.6.1.4.1.14823.2.3.3.1.1.7.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_aiWlanSSIDEntry,
        start => $mapping->{aiSSID}->{oid},
        end => $mapping->{aiSSIDStatus}->{oid},
        nothing_quit => 1
    );

    $self->{ssid} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{aiSSID}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{aiSSID} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping ssid '" . $result->{aiSSID} . "'.", debug => 1);
            next;
        }

        $self->{ssid}->{$result->{aiSSID}} = { 
            status => $result->{aiSSIDStatus},
            display => $result->{aiSSID}
        };
    }

    if (scalar(keys %{$self->{ssid}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SSID found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SSID status.

=over 8

=item B<--filter-name>

Filter SSID name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /enable/i').
Can used special variables like: %{status}, %{display}

=back

=cut
