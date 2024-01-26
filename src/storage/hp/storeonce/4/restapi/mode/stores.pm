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

package storage::hp::storeonce::4::restapi::mode::stores;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub store_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking catalyst store '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_store_output {
    my ($self, %options) = @_;

    return sprintf(
        "catalyst store '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of catalyst stores ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'stores', type => 3, cb_prefix_output => 'prefix_store_output', cb_long_output => 'store_long_output', indent_long_output => '    ', message_multiple => 'All catalyst stores are ok',
            group => [
                { name => 'health', type => 0 },
                { name => 'space', type => 0 },
                { name => 'dedup', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'stores-detected', display_ok => 0, nlabel => 'stores.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{health} = [
        {
            label => 'health',
            type => 2,
            unknown_default => '%{health} =~ /unknown/i',
            warning_default => '%{health} =~ /warning/i',
            critical_default => '%{health} =~ /critical/i',
            set => {
                key_values => [ { name => 'health' }, { name => 'name' } ],
                output_template => 'health: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'disk-space-usage', nlabel => 'store.disk.space.usage.bytes', set => {
                key_values => [ { name => 'disk_used' }, { name => 'name' } ],
                output_template => 'disk space used: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'user-space-usage', nlabel => 'store.user.space.usage.bytes', set => {
                key_values => [ { name => 'user_used' }, { name => 'name' } ],
                output_template => 'user space used: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{dedup} = [
        { label => 'dedup', nlabel => 'store.deduplication.ratio.count', set => {
                key_values => [ { name => 'dedup' }, { name => 'name' } ],
                output_template => 'deduplication ratio: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my %mapping_health_level = (
    0 => 'unknown',
    1 => 'ok',
    2 => 'information',
    3 => 'warning',
    4 => 'critical'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $members = $options{custom}->request_api(endpoint => '/api/v1/data-services/cat/stores');

    $self->{global} = { detected => 0 };
    $self->{stores} = {};

    foreach my $member (@{$members->{members}}) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $member->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $member->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{global}->{detected}++;

        $self->{stores}->{ $member->{id} } = {
            name => $member->{name},
            health => {
                name => $member->{name},
                health => $mapping_health_level{ $member->{healthLevel} }
            },
            space => {
                name => $member->{name},
                disk_used => $member->{diskBytes},
                user_used => $member->{userBytes}
            },
            dedup => {
                name => $member->{name},
                dedup => $member->{dedupeRatio}
            } 
        };
    }
}

1;

__END__

=head1 MODE

Check catalyst stores.

=over 8

=item B<--filter-id>

Filter stores by id.

=item B<--filter-name>

Filter stores by hostname.

=item B<--unknown-health>

Define the conditions to match for the status to be UNKNOWN (default: '%{health} =~ /unknown/i').
You can use the following variables: %{health}, %{name}

=item B<--warning-health>

Define the conditions to match for the status to be WARNING (default: '%{health} =~ /warning/i').
You can use the following variables: %{health}, %{name}

=item B<--critical-health>

Define the conditions to match for the status to be CRITICAL (default: '%{health} =~ /critical/i').
You can use the following variables: %{health}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'stores-detected', 'disk-space-usage, 'user-space-usage', 'dedup'.

=back

=cut
