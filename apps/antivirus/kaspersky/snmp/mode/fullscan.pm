#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::antivirus::kaspersky::snmp::mode::fullscan;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Full scan status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_fullscanStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'fullscanStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'not-scanned', set => {
                key_values => [ { name => 'hostsNotScannedLately' } ],
                output_template => '%d hosts(s) has not been scanned lately',
                perfdatas => [
                    { label => 'not_scanned', value => 'hostsNotScannedLately_absolute', template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "warning-status:s"      => { name => 'warning_status', default => '%{status} =~ /Warning/i' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} =~ /Critical/i' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'OK',
    1 => 'Info',
    2 => 'Warning',
    3 => 'Critical',
);

my $oid_fullscanStatus = '.1.3.6.1.4.1.23668.1093.1.4.1';
my $oid_hostsNotScannedLately = '.1.3.6.1.4.1.23668.1093.1.4.3';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_fullscanStatus, $oid_hostsNotScannedLately ], 
                                               nothing_quit => 1);
    
    $self->{global} = {};

    $self->{global} = { 
        fullscanStatus => $map_status{$snmp_result->{$oid_fullscanStatus}},
        hostsNotScannedLately => $snmp_result->{$oid_hostsNotScannedLately},
    };
}

1;

__END__

=head1 MODE

Check full scan status.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} =~ /Warning/i').
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} =~ /Critical/i').
Can use special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'not-scanned'.

=item B<--critical-*>

Threshold critical.
Can be: 'not-scanned'.

=back

=cut
