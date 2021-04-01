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

package apps::antivirus::kaspersky::snmp::mode::updates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Updates status is '%s'", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_updatesStatus'};
    return 0;
}

sub custom_last_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'last_server_update',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{diff},
        unit => 's',
        min => 0
    );
}

sub custom_last_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{diff},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_last_output {
    my ($self, %options) = @_;

    return sprintf(
        'Last server update: %s [%s]',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{diff}), $self->{result_values}->{date_time}
    );
}

sub custom_last_calc {
    my ($self, %options) = @_;

    my $time = $options{new_datas}->{$self->{instance} . '_lastServerUpdateTime'};
    #2018-3-30,7:43:58.0
    if ($time =~ /^\s*(\d+)-(\d+)-(\d+),(\d+):(\d+):(\d+)\.(\d+)/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            %{$self->{instance_mode}->{tz}}
        );
        $self->{result_values}->{diff} = time() - $dt->epoch;
        $self->{result_values}->{date_time} = $dt->datetime();
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /Warning/i',
            critical_default => '%{status} =~ /Critical/i',
            set => {
                key_values => [ { name => 'updatesStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'last-server-update', nlabel => 'update.server.freshness.seconds', set => {
                key_values => [ { name => 'lastServerUpdateTime' } ],
                closure_custom_calc => $self->can('custom_last_calc'),
                closure_custom_output => $self->can('custom_last_output'),
                closure_custom_threshold_check => $self->can('custom_last_threshold'),
                closure_custom_perfdata => $self->can('custom_last_perfdata')
            }
        },
        { label => 'not-updated', nlabel => 'update.hosts.outdated.count', set => {
                key_values => [ { name => 'hostsNotUpdated' } ],
                output_template => '%d host(s) not up to date',
                perfdatas => [
                    { label => 'not_updated', template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub check_options {	
    my ($self, %options) = @_;	
    $self->SUPER::check_options(%options);	

    $self->{tz} = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});	
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timezone:s' => { name => 'timezone', default => 'GMT' }
    });

    return $self;
}

my $map_status = {
    0 => 'OK',
    1 => 'Info',
    2 => 'Warning',
    3 => 'Critical'
};

my $oid_updatesStatus = '.1.3.6.1.4.1.23668.1093.1.2.1';
my $oid_lastServerUpdateTime = '.1.3.6.1.4.1.23668.1093.1.2.3';
my $oid_hostsNotUpdated = '.1.3.6.1.4.1.23668.1093.1.2.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_updatesStatus, $oid_lastServerUpdateTime,
            $oid_hostsNotUpdated
        ], 
        nothing_quit => 1
    );

    $self->{global} = { 
        updatesStatus => $map_status->{$snmp_result->{$oid_updatesStatus}},
        lastServerUpdateTime => $snmp_result->{$oid_lastServerUpdateTime},
        hostsNotUpdated => $snmp_result->{$oid_hostsNotUpdated},
    };
}

1;

__END__

=head1 MODE

Check updates status.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} =~ /Warning/i').
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} =~ /Critical/i').
Can use special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'last-server-update', 'not-updated'.

=item B<--critical-*>

Threshold critical.
Can be: 'last-server-update', 'not-updated'.

=item B<--timezone>

Timezone options. Default is 'GMT'.

=back

=cut
