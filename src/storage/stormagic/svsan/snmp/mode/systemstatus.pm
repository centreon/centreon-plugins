#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package storage::stormagic::svsan::snmp::mode::systemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "system '%s' status is '%s'",
        $self->{result_values}->{system_name},
        $self->{result_values}->{system_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'system',
            type             => COUNTER_TYPE_INSTANCE,
            message_multiple => 'All systems are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{system} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{system_status} =~ /warning/',
            critical_default => '%{system_status} =~ /error/',
            set              => {
                key_values                     => [
                    { name => 'system_status' },
                    { name => 'system_name' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'include-name:s' => { name => 'include_name' },
            'exclude-name:s' => { name => 'exclude_name' }
        });

    return $self;
}

my $map_status = {
    1 => 'warning', 2 => 'error', 3 => 'ok'
};

my $mapping = {
    systemName    => { oid => '.1.3.6.1.4.1.38003.1.1.1.2' },# systemName,
    systemStatus  => { oid => '.1.3.6.1.4.1.38003.1.1.1.3', map => $map_status },# systemState
};

my $oid_systemEntry = '.1.3.6.1.4.1.38003.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_systemEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{systemName}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if is_excluded(
            $result->{systemName},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name}
        );

        $self->{system}->{$instance} = {
            system_name    => $result->{systemName},
            system_status  => $result->{systemStatus},
        };
    }

    if (scalar(keys %{$self->{system}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No system matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check the overall status of C<StorMagic SvSAN>.

=over 8

=item B<--include-name>

Filter systems by name (can be a regexp).

=item B<--exclude-name>

Exclude systems by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
You can use the following variables: %{system_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{system_status} =~ /warning/').
You can use the following variables: %{system_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{system_status} =~ /error/').
You can use the following variables: %{system_status}

=back

=cut
