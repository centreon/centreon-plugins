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

package network::aviat::snmp::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "event '%s' count: %d [severity: %s]",
        $self->{result_values}->{eventName},
        $self->{result_values}->{count},
        $self->{result_values}->{severity}
    );
}

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'event.detected.count',
        instances => [$self->{result_values}->{slotName}, $self->{result_values}->{eventName}],
        value => $self->{result_values}->{count}
    );
}

sub long_slot_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking slot '%s'",
        $options{instance_value}->{slotName}
    );
}

sub prefix_slot_output {
    my ($self, %options) = @_;

    return sprintf(
        "slot '%s' ",
        $options{instance_value}->{slotName}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'slots', type => 3, cb_prefix_output => 'prefix_slot_output', cb_long_output => 'long_slot_output',
          message_multiple => 'All slots are ok', indent_long_output => '    ',
            group => [
                { name => 'events', display_long => 1, message_multiple => 'All events are ok', type => 1, skipped_code => { -1, => 1, -11 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{events} = [
        { 
            label => 'status',
            type => 2,
            unknown_default => '%{count} > 0 and %{severity} =~ /indetermined/',
            warning_default => '%{count} > 0 and %{severity} =~ /warning|minor/',
            critical_default => '%{count} > 0 and %{severity} =~ /major|critical/',
            set => {
                key_values => [ { name => 'eventName' }, { name => 'slotName' }, { name => 'severity' }, { name => 'count', diff => 1 } ],
                closure_custom_output => $self->can('custom_output'),
                closure_custom_perfdata => $self->can('custom_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-event-severity:s' => { name => 'filter_event_severity', default => 'major|critical|warning|minor|indetermined|cleared' },
        'filter-event-name:s'     => { name => 'filter_event_name' },
        'filter-slot-name:s'      => { name => 'filter_slot_name' }
    });

    return $self;
}

my %map_severity = (
    1 => 'critical',
    2 => 'major',
    3 => 'minor',
    4 => 'warning',
    5 => 'information',
    6 => 'cleared',
    7 => 'indetermined'
);

my $mapping_slot = {
    serial => { oid => '.1.3.6.1.4.1.2509.12.8.31.2.10.1.2' }, # fMfgDetailsInfoSerialNumber
    type   => { oid => '.1.3.6.1.4.1.2509.12.8.31.2.10.1.9' }  # fMfgDetailsInfoUnitType
};

my $mapping_event = {
    eventName => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.2' }, # fEventName
    count     => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.3' }, # fEventState
    severity  => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.4', map => \%map_severity } # fEventSeverity
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'aviat_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_event_name}) ? $self->{option_results}->{filter_event_name} : '') . '_' .
            (defined($self->{option_results}->{filter_slot_name}) ? $self->{option_results}->{filter_slot_name} : '') . '_' .
            (defined($self->{option_results}->{filter_event_severity}) ? $self->{option_results}->{filter_event_severity} : '')
        );

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [map({ oid => $_->{oid} }, values(%$mapping_slot))],
        return_type => 1,
        nothing_quit => 1
    );
    my $slots = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_slot->{serial}->{oid}\.(\d+)\.(.*)/);
        my ($slot_index, $instance) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping_slot, results => $snmp_result, instance => $slot_index . '.' . $instance);

        next if ($result->{serial} =~ /unknown/i);

        $slots->{$slot_index} = $result->{type} . ' ' . $result->{serial};
    }

    $self->{slots} = {};

    my $oid_fEventTable = '.1.3.6.1.4.1.2509.12.8.1.2.2';

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_fEventTable,
        start => $mapping_event->{eventName}->{oid},
        end => $mapping_event->{severity}->{oid},
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_event->{eventName}->{oid}\.(\d+)\.(.*)$/);
        my ($slot_index, $instance) = ($1, $2);

        next if (!defined($slots->{$slot_index}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_event, results => $snmp_result, instance => $slot_index . '.' . $instance);

        $result->{severity} = 'unknown' if (!defined($result->{severity}));

        next if (defined($self->{option_results}->{filter_slot_name}) && $self->{option_results}->{filter_slot_name} ne '' &&
            $slots->{$slot_index} !~ /$self->{option_results}->{filter_slot_name}/);
        next if (defined($self->{option_results}->{filter_event_severity}) && $self->{option_results}->{filter_event_severity} ne '' &&
            $result->{severity} !~ /$self->{option_results}->{filter_event_severity}/);
        next if (defined($self->{option_results}->{filter_event_name}) && $self->{option_results}->{filter_event_name} ne '' &&
            $result->{eventName} !~ /$self->{option_results}->{filter_event_name}/);

        if (!defined($self->{slots}->{$slot_index})) {
            $self->{slots}->{$slot_index} = {
                slotName => $slots->{$slot_index},
                events => {}
            };
        }

        $self->{slots}->{$slot_index}->{events}->{$instance} = {
            slotName => $slots->{$slot_index},
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check events.

=over 8

=item B<--filter-slot-name>

Filter on slot name (Can be a regexp).

=item B<--filter-event-severity>

Filter on event severity (Can be a regexp) (default: 'major|critical|warning|minor|indetermined').

=item B<--filter-event-name>

Filter on event name (Can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{count} > 0 and %{severity} =~ /indetermined/').
You can use the following variables: %{eventName}, %{slotName}, %{count}, %{severity}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{count} > 0 and %{severity} =~ /warning|minor/').
You can use the following variables: %{eventName}, %{slotName}, %{count}, %{severity}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{count} > 0 and %{severity} =~ /major|critical/').
You can use the following variables: %{eventName}, %{slotName}, %{count}, %{severity}

=back

=cut
