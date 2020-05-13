#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::vcs::restapi::mode::zones;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s' [Type: %s]",
        $self->{result_values}->{status}, $self->{result_values}->{type});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_Name'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_Type'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_Status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0},
        { name => 'searches', type => 0, cb_prefix_output => 'prefix_searches_output' },
        { name => 'zones', type => 1, cb_prefix_output => 'prefix_zones_output', message_multiple => 'All zones are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'zones-count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of zones: %d',
                perfdatas => [
                    { label => 'zones_count', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{searches} = [
        { label => 'searches-total', set => {
                key_values => [ { name => 'Total', per_second => 1 } ],
                output_template => 'Total: %.2f/s',
                perfdatas => [
                    { label => 'searches_total', template => '%.2f', min => 0, unit => 'searches/s' },
                ],
            }
        },
        { label => 'searches-dropped', set => {
                key_values => [ { name => 'Dropped', per_second => 1 } ],
                output_template => 'Dropped: %.2f/s',
                perfdatas => [
                    { label => 'searches_dropped', template => '%.2f', min => 0, unit => 'searches/s' },
                ],
            }
        },
        { label => 'searches-max-sub-search-exceeded', set => {
                key_values => [ { name => 'MaxSubSearchExceeded', per_second => 1 } ],
                output_template => 'Max Sub Search Exceeded: %.2f/s',
                perfdatas => [
                    { label => 'searches_max_sub_search_exceeded', template => '%.2f',
                      min => 0, unit => 'searches/s' },
                ],
            }
        },
        { label => 'searches-max-targets-exceeded', set => {
                key_values => [ { name => 'MaxTargetsExceeded', per_second => 1 } ],
                output_template => 'Max Targets Exceeded: %.2f/s',
                perfdatas => [
                    { label => 'searches_max_targets_exceeded', template => '%.2f', min => 0, unit => 'searches/s' },
                ],
            }
        }
    ];

    $self->{maps_counters}->{zones} = [
        { label => 'status', set => {
                key_values => [ { name => 'Status' }, { name => 'Type' }, { name => 'Name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'calls-count', set => {
                key_values => [ { name => 'Calls' }, { name => 'Name' } ],
                output_template => 'Number of Calls: %d',
                perfdatas => [
                    { label => 'calls_count', template => '%d', min => 0, label_extra_instance => 1, instance_use => 'Name' }
                ]
            }
        }
    ];
}

sub prefix_searches_output {
    my ($self, %options) = @_;

    return "Searches ";
}

sub prefix_zones_output {
    my ($self, %options) = @_;

    return "Zone '" . $options{instance_value}->{Name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} ne "Active"' }
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

    my $results = $options{custom}->get_endpoint(method => '/Status/Zones');

    $self->{global}->{count} = 0;
    $self->{searches} = {};
    $self->{zones} = {};
    
    $self->{searches}->{Total} = $results->{Zones}->{Searches}->{Total}->{content};
    $self->{searches}->{Dropped} = $results->{Zones}->{Searches}->{Dropped}->{content};
    $self->{searches}->{MaxSubSearchExceeded} = $results->{Zones}->{Searches}->{MaxSubSearchExceeded}->{content};
    $self->{searches}->{MaxTargetsExceeded} = $results->{Zones}->{Searches}->{MaxTargetsExceeded}->{content};

    foreach my $zone (@{$results->{Zones}->{Zone}}) {
        next if (!defined($zone->{Name}));
        $self->{zones}->{$zone->{Name}->{content}} = {
            Type => $zone->{Type}->{content},
            Name => $zone->{Name}->{content},
            Calls => (defined($zone->{Calls})) ? scalar(@{$zone->{Calls}->{Call}}) : 0,
            Status => $zone->{Status}->{content},
        };

        $self->{global}->{count}++;
    }

    $self->{cache_name} = "cisco_vcs_" . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check zones count and state.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'zones-count', 'calls-count', 'searches-total' (/s), 'searches-dropped' (/s),
'searches-max-sub-search-exceeded' (/s), 'searches-max-targets-exceeded' (/s).

=item B<--critical-*>

Threshold critical.
Can be: 'zones-count', 'calls-count', 'searches-total' (/s), 'searches-dropped' (/s),
'searches-max-sub-search-exceeded' (/s), 'searches-max-targets-exceeded' (/s).

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{status}, %{type}, %{name}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} ne "Active"').
Can use special variables like: %{status}, %{type}, %{name}.

=back

=cut
