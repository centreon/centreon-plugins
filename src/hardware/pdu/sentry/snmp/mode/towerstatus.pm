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

package hardware::pdu::sentry::snmp::mode::towerstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub prefix_tower_output {
    my ($self, %options) = @_;

    return "Tower '" . $options{instance_value}->{display} . "' ";
}

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
            name             => 'tower',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_tower_output',
            message_multiple => 'All towers are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{tower} = [
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
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'include-tower:s' => { name => 'include_tower' },
            'exclude-tower:s' => { name => 'exclude_tower' }
        });

    return $self;
}

my $tower_status = {
    0 => 'normal',
    1 => 'noComm',
    2 => 'fanFail',
    3 => 'overTemp',
    4 => 'nvmFail',
    5 => 'outOfBalance',
};

my $mapping = {
    towerID     => { oid => '.1.3.6.1.4.1.1718.3.2.1.1.2' },
    towerName   => { oid => '.1.3.6.1.4.1.1718.3.2.1.1.3' },
    towerStatus => { oid => '.1.3.6.1.4.1.1718.3.2.1.1.4', map => $tower_status },
};

my $oid_tower_entry = '.1.3.6.1.4.1.1718.3.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_tower_entry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{towerID}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        next if is_excluded(
            $result->{towerName},
            $self->{option_results}->{include_tower},
            $self->{option_results}->{exclude_tower}
        );

        $self->{tower}->{$result->{towerID}} =
            {
                display => $result->{towerName},
                status  => $result->{towerStatus},
            };
    };

    if (scalar(keys %{$self->{tower}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No tower found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check tower.

=over 8

=item B<--include-tower>

Filter C<tower> by number (can be a regexp).
Example: C<--include-tower='Master'>

=item B<--exclude-tower>

Exclude C<tower> by number (can be a regexp).
Example: C<--exclude-tower='Master'>

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{display}>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: C<%{status}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /normal/').
You can use the following variables: C<%{status}>, C<%{display}>

=back

=cut
