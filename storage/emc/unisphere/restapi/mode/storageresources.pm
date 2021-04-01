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

package storage::emc::unisphere::restapi::mode::storageresources;

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

sub custom_allocated_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_alloc});
    $self->{result_values}->{free_alloc} = 0 if ($self->{result_values}->{free_alloc} < 0);
    $self->{result_values}->{prct_free_alloc} = 0 if ($self->{result_values}->{prct_free_alloc} < 0);
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_alloc});
    return sprintf(
        'allocated usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_alloc},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_alloc}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sr', type => 1, cb_prefix_output => 'prefix_sr_output', message_multiple => 'All storage resources are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{sr} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{health_status} =~ /unknown/i',
            warning_default => '%{health_status} =~ /ok_but|degraded|minor/i',
            critical_default => '%{health_status} =~ /major|critical|non_recoverable/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'storageresource.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'storageresource.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'storageresource.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used_space', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'allocated', nlabel => 'storageresource.allocated.usage.bytes', display_ok => 0, set => {
                key_values => [ { name => 'used_alloc' }, { name => 'free_alloc' }, { name => 'prct_used_alloc' }, { name => 'prct_free_alloc' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_allocated_output'),
                perfdatas => [
                    {  template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'allocated-prct', display_ok => 0, nlabel => 'storageresource.allocated.usage.percentage', set => {
                key_values => [ { name => 'prct_used_alloc' }, { name => 'display' } ],
                output_template => 'allocated used : %.2f %%',
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

sub prefix_sr_output {
    my ($self, %options) = @_;
    
    return "Storage resource '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/api/types/storageResource/instances?fields=name,health,sizeUsed,sizeAllocated,sizeTotal');

    $self->{sr} = {};
    foreach (@{$results->{entries}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{content}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping storage resource '" . $_->{content}->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sr}->{$_->{content}->{id}} = {
            display => $_->{content}->{name},
            status => $health_status->{ $_->{content}->{health}->{value} },
            total_space => $_->{content}->{sizeTotal},
        };

        if (defined($_->{content}->{sizeUsed})) {
            $self->{sr}->{$_->{content}->{id}}->{used_space} = $_->{content}->{sizeUsed};
            $self->{sr}->{$_->{content}->{id}}->{free_space} = $_->{content}->{sizeTotal} - $_->{content}->{sizeUsed};
            $self->{sr}->{$_->{content}->{id}}->{prct_used_space} = $_->{content}->{sizeUsed} * 100 / $_->{content}->{sizeTotal};
            $self->{sr}->{$_->{content}->{id}}->{prct_free_space} = 100 - ($_->{content}->{sizeUsed} * 100 / $_->{content}->{sizeTotal});
        }
        if (defined($_->{content}->{sizeAllocated})) {
            $self->{sr}->{$_->{content}->{id}}->{used_alloc} = $_->{content}->{sizeAllocated};
            $self->{sr}->{$_->{content}->{id}}->{free_alloc} = $_->{content}->{sizeTotal} - $_->{content}->{sizeAllocated};
            $self->{sr}->{$_->{content}->{id}}->{prct_used_alloc} = $_->{content}->{sizeAllocated} * 100 / $_->{content}->{sizeTotal};
            $self->{sr}->{$_->{content}->{id}}->{prct_free_alloc} = 100 - ($_->{content}->{sizeAllocated} * 100 / $_->{content}->{sizeTotal});
        }
    }

    if (scalar(keys %{$self->{sr}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage resource found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage resources.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter name (can be a regexp).

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
'allocated', 'allocated-prct'.

=back

=cut
