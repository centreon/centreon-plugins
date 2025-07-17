#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package storage::hp::alletra::restapi::mode::volumestatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

my %map_state = (
    1  => 'normal',
    2  => 'degraded',
    4  => 'failed',
    99 => 'unknown'
);

my %compression_state = (
    1 => 'YES',
    2 => 'NO',
    3 => 'OFF',
    4 => 'NA',
    5 => 'V1',
    6 => 'v2'
);

my %provisioning_type = (
    1 => 'FULL',
    2 => 'TPVV',
    3 => 'SNP',
    4 => 'PEER',
    5 => 'UNKNOWN',
    6 => 'TDVV',
    7 => 'DDS'
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Volume #%s (%s) uuid: %s (readonly: %s, compression: %s, provisioning: %s)",
        $self->{result_values}->{id},
        $self->{result_values}->{name},
        $self->{result_values}->{uuid},
        $self->{result_values}->{readonly},
        $self->{result_values}->{compression_state},
        $self->{result_values}->{provisioning_type}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Volumes ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
        { name => 'volumes', type => 1, message_multiple => 'All volumes are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'volumes-total', nlabel => 'volumes.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'total: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'volumes-normal', nlabel => 'volumes.normal.count', set => {
            key_values      => [ { name => 'normal' }, { name => 'total' } ],
            output_template => 'normal: %s',
            perfdatas       => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        },
        { label => 'volumes-degraded', nlabel => 'volumes.degraded.count', set => {
            key_values      => [ { name => 'degraded' }, { name => 'total' } ],
            output_template => 'degraded: %s',
            perfdatas       => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        },
        { label => 'volumes-failed', nlabel => 'volumes.failed.count', set => {
            key_values      => [ { name => 'failed' }, { name => 'total' } ],
            output_template => 'failed: %s',
            perfdatas       => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        },
        { label => 'volumes-unknown', nlabel => 'volumes.unknown.count', set => {
            key_values      => [ { name => 'unknown' }, { name => 'total' } ],
            output_template => 'unknown: %s',
            perfdatas       => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        }
    ];
    $self->{maps_counters}->{volumes} = [
        {
            label            => 'status',
            type             => 2,
            warning_default  => '%{status} =~ /^(degraded|unknown)$/',
            critical_default => '%{status} =~ /failed/',
            unknown_default  => '%{status} =~ /NOT_DOCUMENTED$/',
            set              => {
                key_values                     => [
                    { name => 'status' },
                    { name => 'id' },
                    { name => 'name' },
                    { name => 'uuid' },
                    { name => 'compression_state' },
                    { name => 'provisioning_type' },
                    { name => 'readonly' }
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

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_response = $options{custom}->request_api(
        endpoint => '/api/v1/volumes'
    );

    my $volumes = $api_response->{members};

    $self->{global} = {
        total    => 0,
        normal   => 0,
        degraded => 0,
        failed   => 0,
        unknown  => 0
    };

    for my $volume (@{$volumes}) {
        # skip if filtered by name
        if (defined($self->{option_results}->{filter_name})
            and $self->{option_results}->{filter_name} ne '' and $volume->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $volume->{name} because the name does not match the name filter.",
                debug    => 1
            );
            next;
        }

        # skip if filtered by name
        if (defined($self->{option_results}->{filter_id})
            and $self->{option_results}->{filter_id} ne '' and $volume->{id} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $volume->{name} because the id does not match the id filter.",
                debug    => 1
            );
            next;
        }
        my $state = defined($map_state{$volume->{state}}) ? $map_state{$volume->{state}} : 'NOT_DOCUMENTED';

        # increment adequate global counters
        $self->{global}->{total} = $self->{global}->{total} + 1;
        $self->{global}->{$state} = $self->{global}->{$state} + 1;

        # add the instance
        $self->{volumes}->{ $volume->{id} } = {
            status            => $state,
            name              => $volume->{name},
            id                => $volume->{id},
            uuid              => $volume->{uuid},
            compression_state => defined($compression_state{$volume->{compressionState}}) ?
                $compression_state{$volume->{compressionState}} : 'NOT_DOCUMENTED',
            provisioning_type => defined($provisioning_type{$volume->{provisioningType}}) ?
                $provisioning_type{$volume->{provisioningType}} : 'NOT_DOCUMENTED',
            readonly          => $volume->{readOnly}
        }
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor the states of the volumes.

=over 8

=item B<--filter-counters>

Define which counters (filtered by regular expression) should be monitored.
Can be : volumes-total volumes-normal volumes-degraded volumes-failed volumes-unknown status
Example: --filter-counters='^volumes-total$'

=item B<--filter-id>

Define which volumes should be monitored based on their IDs.
This option will be treated as a regular expression.

=item B<--filter-name>

Define which volumes should be monitored based on the volume name.
This option will be treated as a regular expression.

=item B<--warning-status>

Define the condition to match for the returned status to be WARNING.
Default: '%{status} =~ /^(degraded|unknown)$/'

=item B<--critical-status>

Define the condition to match for the returned status to be CRITICAL.
Default: '%{status} =~ /failed/'

=item B<--unknown-status>

Define the condition to match for the returned status to be UNKNOWN.
Default: '%{status} =~ /NOT_DOCUMENTED$/'

=item B<--warning-volumes-degraded>

Threshold.

=item B<--critical-volumes-degraded>

Threshold.

=item B<--warning-volumes-failed>

Threshold.

=item B<--critical-volumes-failed>

Threshold.

=item B<--warning-volumes-normal>

Threshold.

=item B<--critical-volumes-normal>

Threshold.

=item B<--warning-volumes-total>

Threshold.

=item B<--critical-volumes-total>

Threshold.

=item B<--warning-volumes-unknown>

Threshold.

=item B<--critical-volumes-unknown>

Threshold.

=back

=cut
