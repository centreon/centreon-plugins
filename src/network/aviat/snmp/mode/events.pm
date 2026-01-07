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
        $self->{result_values}->{name},
        $self->{result_values}->{count},
        $self->{result_values}->{severity}
    );
}

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'event.detected.count',
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{count}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'events', type => 1, message_multiple => 'All events are ok' }
    ];

    $self->{maps_counters}->{events} = [
        { 
            label => 'status',
            type => 2,
            unknown_default => '%{count} > 0 and %{severity} =~ /indetermined/',
            warning_default => '%{count} > 0 and %{severity} =~ /warning|minor/',
            critical_default => '%{count} > 0 and %{severity} =~ /major|critical/',
            set => {
                key_values => [ { name => 'name' }, { name => 'severity' }, { name => 'count', diff => 1 } ],
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
        'filter-severity:s' => { name => 'filter_severity', default => 'major|critical|warning|minor|indetermined|cleared' },
        'filter-name:s'     => { name => 'filter_name' }
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

my $mapping = {
    name     => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.2' }, # fEventName
    count    => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.3' }, # fEventState
    severity => { oid => '.1.3.6.1.4.1.2509.12.8.1.2.2.1.4', map => \%map_severity }, # fEventSeverity
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "aviat_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{filter_severity}) ? $self->{option_results}->{filter_severity} : '')
        );

    $self->{events} = {};

    my $oid_fEventTable = '.1.3.6.1.4.1.2509.12.8.1.2.2';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_fEventTable,
        start => $mapping->{name}->{oid},
        end => $mapping->{severity}->{oid},
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{severity} = 'unknown' if (!defined($result->{severity}));

        next if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' &&
            $result->{severity} !~ /$self->{option_results}->{filter_severity}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{events}->{$instance} = $result;
    }
}

1;

__END__

=head1 MODE

Check events.

=over 8

=item B<--filter-severity>

Filter on severity name (Can be a regexp) (default: 'major|critical|warning|minor|indetermined').

=item B<--filter-name>

Filter on event name (Can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{count} > 0 and %{severity} =~ /indetermined/').
You can use the following variables: %{name}, %{count}, %{severity}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{count} > 0 and %{severity} =~ /warning|minor/').
You can use the following variables: %{name}, %{count}, %{severity}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{count} > 0 and %{severity} =~ /major|critical/').
You can use the following variables: %{name}, %{count}, %{severity}

=back

=cut
