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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [type: %s]",
        $self->{result_values}->{status}, $self->{result_values}->{type}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_Name'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_Type'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_Status'};
    return 0;
}

sub prefix_searches_output {
    my ($self, %options) = @_;

    return 'Searches ';
}

sub prefix_zones_output {
    my ($self, %options) = @_;

    return "Zone '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0},
        { name => 'searches', type => 0, cb_prefix_output => 'prefix_searches_output' },
        { name => 'zones', type => 1, cb_prefix_output => 'prefix_zones_output', message_multiple => 'All zones are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'zones-count', nlabel => 'zones.total.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of zones: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{searches} = [
        { label => 'searches-total', nlabel => 'zones.searches.total.persecond', set => {
                key_values => [ { name => 'total', per_second => 1 } ],
                output_template => 'total: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'searches-dropped', nlabel => 'zones.searches.dropped.persecond', set => {
                key_values => [ { name => 'dropped', per_second => 1 } ],
                output_template => 'dropped: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'searches-maxsub-exceeded', nlabel => 'zones.searches.maxsub.exceeded.count', set => {
                key_values => [ { name => 'max_sub_search_exceeded', diff => 1 } ],
                output_template => 'max sub exceeded: %s',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'searches-maxtargets-exceeded', nlabel => 'zones.searches.maxtargets.exceeded.count', set => {
                key_values => [ { name => 'max_targets_exceeded', diff => 1 } ],
                output_template => 'max targets exceeded: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{zones} = [
        { label => 'status', type => 2, critical_default => '%{status} ne "Active"', set => {
                key_values => [ { name => 'status' }, { name => 'type' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'zone-calls-current', nlabel => 'zone.calls.current.count', set => {
                key_values => [ { name => 'calls' } ],
                output_template => 'current calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-zone-name:s' => { name => 'filter_zone_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/Zones',
        force_array => ['Zone', 'Call']
    );

    $self->{global} = { count =>  0 };
    $self->{searches} = {
        total => $results->{Zones}->{Searches}->{Total}->{content},
        dropped => $results->{Zones}->{Searches}->{Dropped}->{content},
        max_sub_search_exceeded => $results->{Zones}->{Searches}->{MaxSubSearchExceeded}->{content},
        max_targets_exceeded => $results->{Zones}->{Searches}->{MaxTargetsExceeded}->{content}
    };

    $self->{zones} = {};
    foreach my $zone (@{$results->{Zones}->{Zone}}) {
        next if (!defined($zone->{Name}));

        if (defined($self->{option_results}->{filter_zone_name}) && $self->{option_results}->{filter_zone_name} ne '' &&
            $zone->{Name}->{content} !~ /$self->{option_results}->{filter_zone_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $zone->{Name}->{content} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{zones}->{ $zone->{Name}->{content} } = {
            type => $zone->{Type}->{content},
            name => $zone->{Name}->{content},
            calls => (defined($zone->{Calls})) ? scalar(@{$zone->{Calls}->{Call}}) : 0,
            status => $zone->{Status}->{content}
        };

        $self->{global}->{count}++;
    }

    $self->{cache_name} = 'cisco_vcs_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_zone_name}) ? md5_hex($self->{option_results}->{filter_zone_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check zones.

=over 8

=item B<--filter-zone-name>

Filter zones by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'zones-count', 'zone-calls-current', 'searches-total', 
'searches-dropped', 'searches-maxsub-exceeded', 'searches-maxtargets-exceeded'.

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{status}, %{type}, %{name}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} ne "Active"').
Can use special variables like: %{status}, %{type}, %{name}.

=back

=cut
