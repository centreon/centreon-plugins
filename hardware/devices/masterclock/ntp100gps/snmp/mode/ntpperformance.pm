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

package hardware::devices::masterclock::ntp100gps::snmp::mode::ntpperformance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Leap : '%s'",
        $self->{result_values}->{leap});

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{leap} = $options{new_datas}->{$self->{instance} . '_leap'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'leap' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'stratum-level', set => {
                key_values => [ { name => 'stratum_level' } ],
                output_template => 'Stratum level : %d',
                perfdatas => [
                    { label => 'stratum_level', value => 'stratum_level', template => '%d',
                      min => 0, max => 16 },
                ],
            }
        },
        { label => 'precision', set => {
                key_values => [ { name => 'precision' } ],
                output_template => 'Precision : %s seconds',
                perfdatas => [
                    { label => 'precision', value => 'precision', template => '%s',
                      min => 0, unit => "seconds" },
                ],
            }
        },
        { label => 'poll-interval', set => {
                key_values => [ { name => 'poll_interval' } ],
                output_template => 'Poll interval : %d seconds',
                perfdatas => [
                    { label => 'poll_interval', value => 'poll_interval', template => '%d',
                      min => 0, unit => "seconds"  },
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
                                  "warning-status:s"        => { name => 'warning_status', default => '%{health} !~ /No leap second today/' },
                                  "critical-status:s"       => { name => 'critical_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ntp_leap_id = ".1.3.6.1.4.1.45561.1.1.1.4.0";
    my $oid_ntp_stratum_level = ".1.3.6.1.4.1.45561.1.1.1.5.0";
    my $oid_ntp_precision = ".1.3.6.1.4.1.45561.1.1.1.6.0";
    my $oid_ntp_poll_interval = ".1.3.6.1.4.1.45561.1.1.1.11.0";
    
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_ntp_leap_id, $oid_ntp_stratum_level, $oid_ntp_precision, $oid_ntp_poll_interval ]);

    $self->{global} = { 
        leap => $snmp_result->{$oid_ntp_leap_id},
        stratum_level => $snmp_result->{$oid_ntp_stratum_level},
        precision => (2 ** $snmp_result->{$oid_ntp_precision}),
        poll_interval => $snmp_result->{$oid_ntp_poll_interval},
    };
}

1;

__END__

=head1 MODE

Check NTP performances

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{health} !~ /No leap second today/')
Can used special variables like: %{leap}

=item B<--critical-status>

Set critical threshold for status (Default: '')
Can used special variables like: %{health}

=item B<--warning-*>

Threshold warning. Can be : 'stratum-level', 'precision', 'poll-interval'

=item B<--critical-*>

Threshold critical. Can be : 'stratum-level', 'precision', 'poll-interval'

=back

=cut
