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

package network::cisco::vcs::restapi::mode::endpoints;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_endpoint_output {
    my ($self, %options) = @_;

    return "Endpoint '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'endpoints', type => 1, cb_prefix_output => 'prefix_endpoint_output', message_multiple => 'All endpoints are ok' }
    ];

    $self->{maps_counters}->{endpoints} = [
        { label => 'usage', nlabel => 'endpoint.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'endpoint.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'endpoint.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/SystemUnit/Software/Configuration/'
    );

    $self->{endpoints} = {};
    if (defined($results->{SystemUnit}->{Software}->{Configuration}->{TPRoom})) {
        $self->{endpoints}->{tproom} = { name => 'tproom', total => $results->{SystemUnit}->{Software}->{Configuration}->{TPRoom}->{content} };
    }
    if (defined($results->{SystemUnit}->{Software}->{Configuration}->{UserDevice})) {
        $self->{endpoints}->{userdevice} = { name => 'userdevice', total => $results->{SystemUnit}->{Software}->{Configuration}->{UserDevice}->{content} };
    }

    $results = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/ResourceUsage/'
    );
    if (defined($results->{ResourceUsage}->{TPRoom}->{Current})) {
        $self->{endpoints}->{tproom}->{used} = $results->{ResourceUsage}->{TPRoom}->{Current}->{content};
        $self->{endpoints}->{tproom}->{free} = $self->{endpoints}->{tproom}->{total} - $self->{endpoints}->{tproom}->{used};
        $self->{endpoints}->{tproom}->{prct_used} = $self->{endpoints}->{tproom}->{used} * 100 / $self->{endpoints}->{tproom}->{total};
        $self->{endpoints}->{tproom}->{prct_free} = 100 - $self->{endpoints}->{tproom}->{prct_used};
    }
    if (defined($results->{ResourceUsage}->{UserDevice}->{Current})) {
        $self->{endpoints}->{userdevice}->{used} = $results->{ResourceUsage}->{UserDevice}->{Current}->{content};
        $self->{endpoints}->{userdevice}->{free} = $self->{endpoints}->{userdevice}->{total} - $self->{endpoints}->{userdevice}->{used};
        $self->{endpoints}->{userdevice}->{prct_used} = $self->{endpoints}->{userdevice}->{used} * 100 / $self->{endpoints}->{userdevice}->{total};
        $self->{endpoints}->{userdevice}->{prct_free} = 100 - $self->{endpoints}->{userdevice}->{prct_used};
    }

    if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
        foreach my $name (('tproom', 'userdevice')) {
            delete $self->{endpoints}->{$name} if ($name !~ /$self->{option_results}->{filter_name}/);
        }
    }
}

1;

__END__

=head1 MODE

Check endpoints (tproom and userdevice).

=over 8

=item B<--filter-name>

Filter endpoints by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-free', 'usage-prct'.

=back

=cut
