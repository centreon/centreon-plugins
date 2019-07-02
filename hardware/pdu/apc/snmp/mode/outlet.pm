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

package hardware::pdu::apc::snmp::mode::outlet;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = "status : '" . $self->{result_values}->{status} . "' [bank : " . $self->{result_values}->{bank} . ', phase : ' . $self->{result_values}->{phase} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{bank} = $options{new_datas}->{$self->{instance} . '_bank'};
    $self->{result_values}->{phase} = $options{new_datas}->{$self->{instance} . '_phase'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'outlet', type => 1, cb_prefix_output => 'prefix_outlet_output', message_multiple => 'All outlets are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{outlet} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'bank' }, { name => 'phase' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'current', nlabel => 'outlet.current.ampere', set => {
                key_values => [ { name => 'current' }, { name => 'display' } ],
                output_template => 'current : %s A',
                perfdatas => [
                    { label => 'current',  template => '%s', value => 'current_absolute',
                      unit => 'A', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_outlet_output {
    my ($self, %options) = @_;

    return "Outlet '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "unknown-status:s"  => { name => 'unknown_status', default => '' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} =~ /off/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

my %map_rpdu_status = (
    1 => 'on',
    2 => 'off',
);
my %map_rpdu_phase = (
    1 => 'phase1',
    2 => 'phase2',
    3 => 'phase3',
    4 => 'phase1-2',
    5 => 'phase2-3',
    6 => 'phase3-1',
);

sub check_rpdu {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{outlet}}) > 0);

    my $mapping = {
        rPDUOutletStatusOutletName  => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.2' },
        rPDUOutletStatusOutletPhase => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.3', map => \%map_rpdu_phase },
        rPDUOutletStatusOutletState => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.4', map => \%map_rpdu_status },
        rPDUOutletStatusOutletBank  => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.6' },
        rPDUOutletStatusLoad        => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.7' },
    };

    my $oid_rPDUOutletStatusEntry = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_rPDUOutletStatusEntry, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{rPDUOutletStatusOutletState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{outlet}->{$instance} = {
            display => $result->{rPDUOutletStatusOutletName},
            status => $result->{rPDUOutletStatusOutletState},
            bank => $result->{rPDUOutletStatusOutletBank},
            phase => $result->{rPDUOutletStatusOutletPhase},
            current => $result->{rPDUOutletStatusLoad} / 10,
        };
    }
}

sub check_rpdu2 {
    my ($self, %options) = @_;

    # not implemented yet
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{outlet} = {};
    
    $self->check_rpdu2(%options);
    $self->check_rpdu(%options);
    
    if (scalar(keys %{$self->{outlet}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No outlet found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check outlet.

=over 8

=item B<--unknown-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{phase}, %{bank}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /off/').
Can used special variables like: %{status}, %{phase}, %{bank}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current'.

=back

=cut
