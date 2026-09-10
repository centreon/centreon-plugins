#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package hardware::pdu::epdu::snmp::mode::outlet;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status : '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'outlet',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_outlet_output',
            message_multiple => 'All outlets are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{outlet} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /off/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'status' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_overall_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'include-outlet:s' => { name => 'include_outlet' },
            'exclude-outlet:s' => { name => 'exclude_outlet' }
        });

    return $self;
}

my $map_epdu_status = {
    1 => 'off',
    2 => 'on',
};

my $mapping = {
    ePDUOutletStatusModule => { oid => '.1.3.6.1.4.1.318.1.1.30.6.1.1.2' },
    ePDUOutletStatusNumber => { oid => '.1.3.6.1.4.1.318.1.1.30.6.1.1.3' },
    ePDUOutletStatusState  => { oid => '.1.3.6.1.4.1.318.1.1.30.6.1.1.4', map => $map_epdu_status },
};

my $oid_ePDUOutletStatusEntry = '.1.3.6.1.4.1.318.1.1.30.6.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_ePDUOutletStatusEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ePDUOutletStatusModule}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        my $instance = $result->{ePDUOutletStatusModule} . '.' . $result->{ePDUOutletStatusNumber};

        next if is_excluded(
            $instance,
            $self->{option_results}->{include_outlet},
            $self->{option_results}->{exclude_outlet}
        );

        $self->{outlet}->{$instance} =
            {
                display => $instance,
                status  => $result->{ePDUOutletStatusState},
            };
    };

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

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{display}>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: C<%{status}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /off/').
You can use the following variables: C<%{status}>, C<%{display}>

=back

=cut
