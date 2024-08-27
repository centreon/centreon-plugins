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

package apps::google::workspace::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime;
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status is ' . $self->{result_values}->{status};
    if ($self->{result_values}->{since} ne '') {
        $msg .= sprintf(
            ' [since: %s][message: %s]',
            $self->{result_values}->{since},
            $self->{result_values}->{message},
        );
    }
    return $msg;
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', display_long => 1, cb_long_output => 'long_output', message_multiple => 'All Google workspace services are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'services', nlabel => 'google.workspace.services.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => '%s Google workspace services',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{services} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} eq "disruption"',
            critical_default => '%{status} eq "outage"',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'message' }, { name => 'since' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' }
    });

    return $self;
}

my $status_mapping = {
    SERVICE_DISRUPTION => 'disruption',
    SERVICE_OUTAGE => 'outage',
    SERVICE_INFORMATION => 'information'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $services = $options{custom}->get_services();
    my $history = $options{custom}->request_api();

    $self->{services} = {};
    foreach my $name (keys %$services) {
        next if (
            defined($self->{option_results}->{filter_name})
            && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/i
        );

        $self->{services}->{lc($name)} = {
            name => $name,
            status => 'available',
            message => '-',
            since => ''
        };
    }

    foreach my $entry (@$history) {
        next if (defined($entry->{end}) && $entry->{end} =~ /^\d+-\d+-\d+T\d+:\d+:\d+(.*)$/);
        next if (!defined($entry->{begin}) || $entry->{begin} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(.*)$/);

        my $dt = DateTime->new(
            year => $1, 
            month => $2, 
            day => $3,
            hour => $4,
            minute => $5,
            second => $6,
            time_zone => $7
        );

        my $diff_time = time() - $dt->epoch();
        foreach (@{$entry->{affected_products}}) {
            next if (!defined($self->{services}->{ lc($_->{title}) }));
            $self->{services}->{ lc($_->{title}) }->{status} = $status_mapping->{ $entry->{status_impact} };
            $self->{services}->{ lc($_->{title}) }->{message} = $entry->{external_desc};
            $self->{services}->{ lc($_->{title}) }->{since} = centreon::plugins::misc::change_seconds(value => $diff_time);
        }
    }

    $self->{global} = { total => scalar(keys %{$self->{services}}) };
}

1;

__END__

=head1 MODE

Check Google workspace service status.

=over 8

=item B<--filter-name>

Only display the status for a specific servie
(example: --filter-service='gmail')

=item B<--warning-status>

Set warning threshold for the service status
(default: '%{status} eq "disruption"').

=item B<--critical-status>

Set warning threshold for the service status
(default: '%{status} eq "outage"').

=back

=cut
