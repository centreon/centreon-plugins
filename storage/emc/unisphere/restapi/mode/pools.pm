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

package storage::emc::unisphere::restapi::mode::pools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use storage::emc::unisphere::restapi::mode::components::resources qw($health_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub custom_subscribed_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_sub});
    $self->{result_values}->{free_sub} = 0 if ($self->{result_values}->{free_sub} < 0);
    $self->{result_values}->{prct_free_sub} = 0 if ($self->{result_values}->{prct_free_sub} < 0);
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_sub});
    return sprintf(
        'subscribed usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_sub},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_sub}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pool', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All pools are ok' }
    ];

    $self->{maps_counters}->{pool} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /ok_but|degraded|minor/i',
            critical_default => '%{status} =~ /major|critical|non_recoverable/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'subscribed', nlabel => 'pool.subscribed.usage.bytes', display_ok => 0, set => {
                key_values => [ { name => 'used_sub' }, { name => 'free_sub' }, { name => 'prct_used_sub' }, { name => 'prct_free_sub' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_subscribed_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'subscribed-prct', display_ok => 0, nlabel => 'pool.subscribed.usage.percentage', set => {
                key_values => [ { name => 'prct_used_sub' }, { name => 'display' } ],
                output_template => 'subcribed used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
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

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return "Pool '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/api/types/pool/instances?fields=name,sizeFree,sizeSubscribed,sizeTotal,health');

    $self->{pool} = {};
    foreach (@{$results->{entries}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{content}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $_->{content}->{name} . "': no matching filter.", debug => 1);
            next;
        }

        my $used = $_->{content}->{sizeTotal} - $_->{content}->{sizeFree};
        $self->{pool}->{$_->{content}->{id}} = {
            display => $_->{content}->{name},
            status => $health_status->{ $_->{content}->{health}->{value} },
            total_space => $_->{content}->{sizeTotal},
            used_space => $used,
            free_space => $_->{content}->{sizeFree},
            prct_used_space => $used * 100 / $_->{content}->{sizeTotal},
            prct_free_space => $_->{content}->{sizeFree} * 100 / $_->{content}->{sizeTotal},

            used_sub => $_->{content}->{sizeSubscribed},
            free_sub => $_->{content}->{sizeTotal} - $_->{content}->{sizeSubscribed},
            prct_used_sub => $_->{content}->{sizeSubscribed} * 100 / $_->{content}->{sizeTotal},
            prct_free_sub => 100 - ($_->{content}->{sizeSubscribed} * 100 / $_->{content}->{sizeTotal}),
        };
    }

    if (scalar(keys %{$self->{pool}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No pool found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check pool usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter pool name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /ok_but|degraded|minor/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /major|critical|non_recoverable/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'subscribed', 'subscribed-prct'.

=back

=cut
