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

package storage::hp::p2000::xmlapi::mode::controllers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_write_cache_calc {
    my ($self, %options) = @_;

    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_write-cache-hits'} - $options{old_datas}->{$self->{instance} . '_write-cache-hits'});
    my $total = $diff_hits
        + ($options{new_datas}->{$self->{instance} . '_write-cache-misses'} - $options{old_datas}->{$self->{instance} . '_write-cache-misses'});

    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{'write-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub custom_read_cache_calc {
    my ($self, %options) = @_;

    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_read-cache-hits'} - $options{old_datas}->{$self->{instance} . '_read-cache-hits'});
    my $total = $diff_hits
        + ($options{new_datas}->{$self->{instance} . '_read-cache-misses'} - $options{old_datas}->{$self->{instance} . '_read-cache-misses'});

    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }

    $self->{result_values}->{'read-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s%s',
        $self->{result_values}->{status},
        $self->{result_values}->{status} ne 'ok' ?
            '[reason: ' . $self->{result_values}->{reason} . '][recommendation: ' . $self->{result_values}->{recommendation} . ']' : ''
    );
}

sub controller_long_output {
    my ($self, %options) = @_;

    return "checking controller '" . $options{instance_value}->{name} . "'";
}

sub prefix_controller_output {
    my ($self, %options) = @_;

    return "Controller '" . $options{instance_value}->{name} . "' ";
}

sub prefix_network_output {
    my ($self, %options) = @_;

    return "network '" . $options{instance_value}->{name} . "' ";
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "port '" . $options{instance_value}->{name} . "' ";
}

sub prefix_expander_port_output {
    my ($self, %options) = @_;

    return "expander port '" . $options{instance_value}->{name} . "' ";
}

sub prefix_compact_flash_output {
    my ($self, %options) = @_;

    return "compact flash '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'controllers', type => 3, cb_prefix_output => 'prefix_controller_output', cb_long_output => 'controller_long_output', indent_long_output => '    ', message_multiple => 'All controllers are ok',
            group => [
                { name => 'controller_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'controller_stats', type => 0, skipped_code => { -10 => 1 } },
                { name => 'networks', display_long => 1, cb_prefix_output => 'prefix_network_output', message_multiple => 'networks are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'ports', display_long => 1, cb_prefix_output => 'prefix_port_output', message_multiple => 'ports are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'expander_ports', display_long => 1, cb_prefix_output => 'prefix_expander_port_output', message_multiple => 'expander ports are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'compact_flash', display_long => 1, cb_prefix_output => 'prefix_compact_flash_output', message_multiple => 'compact flash are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{controller_status} = [
        {
            label => 'controller-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'recommendation' }, { name => 'reason' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{networks} = [
        {
            label => 'network-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'recommendation' }, { name => 'reason' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{ports} = [
        {
            label => 'port-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'recommendation' }, { name => 'reason' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{expander_ports} = [
        {
            label => 'expander-port-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'recommendation' }, { name => 'reason' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{compact_flash} = [
        {
            label => 'compact-flash-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'recommendation' }, { name => 'reason' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{controller_stats} = [
        { label => 'read', nlabel => 'controller.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'data-read-numeric', per_second => 1 } ],
                output_template => 'read i/o: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'controller.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'data-written-numeric', per_second => 1 } ],
                output_template => 'write i/o: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'read-cache-hits', nlabel => 'controller.cache.read.hits.percentage', set => {
                key_values => [ { name => 'read-cache-hits', diff => 1 }, { name => 'read-cache-misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_read_cache_calc'),
                output_template => 'read cache hits: %.2f %%',
                output_use => 'read-cache-hits_prct',  threshold_use => 'read-cache-hits_prct',
                perfdatas => [
                    { value => 'read-cache-hits_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-cache-hits', nlabel => 'controller.cache.write.hits.percentage', set => {
                key_values => [ { name => 'write-cache-hits', diff => 1 }, { name => 'write-cache-misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_write_cache_calc'),
                output_template => 'write cache hits: %.2f %%',
                output_use => 'write-cache-hits_prct', threshold_use => 'write-cache-hits_prct',
                perfdatas => [
                    { value => 'write-cache-hits_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'iops', nlabel => 'controller.io.usage.iops', set => {
                key_values => [ { name => 'iops' } ],
                output_template => 'iops: %s',
                perfdatas => [
                    { unit => 'iops', min => 0, label_extra_instance => 1 }
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
        'filter-controller-name:s' => { name => 'filter_controller_name' }
    });

    return $self;
}

my $map_health = {
    0 => 'ok', 1 => 'degraded',
    2 => 'failed', 3 => 'unknown',
    4 => 'not available',
};
my $map_base_type = {
    'compact-flash' => 'compact_flash',
    'expander-ports' => 'expander_ports',
    'port' => 'ports',
    'network-parameters' => 'networks'
};

sub manage_selection {
    my ($self, %options) = @_;

    my ($controllers) = $options{custom}->get_infos(
        cmd => 'show controllers', 
        base_type => 'controllers',
        properties_name => '^OBJECT|durable-id|health-numeric|health-reason|health-recommendation$'
    );

    $self->{controllers} = {};
    foreach my $ctrl (@$controllers) {
        my $name = lc($ctrl->{'durable-id'});

        if (defined($self->{option_results}->{filter_controller_name}) && $self->{option_results}->{filter_controller_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_controller_name}/) {
            $self->{output}->output_add(long_msg => "skipping controller '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{controllers}->{$name} = {
            name => $name,
            controller_status => {
                name => $name,
                status => $map_health->{ $ctrl->{'health-numeric'} },
                reason => defined($ctrl->{'health-reason'}) ? $ctrl->{'health-reason'} : '-',
                recommendation => defined($ctrl->{'health-recommendation'}) ? $ctrl->{'health-recommendation'} : '-'
            },
            compact_flash => {},
            networks => {},
            ports => {},
            expander_ports => {},
        };

        foreach (@{$ctrl->{OBJECT}}) {
            next if (!defined($map_base_type->{ $_->{basetype} }));
            my ($id, $status, $reason, $recommendation);
            foreach my $prop (@{$_->{PROPERTY}}) {
                $id = $prop->{content} if ($prop->{name} eq 'durable-id');
                $status = $map_health->{ $prop->{content} } if ($prop->{name} eq 'health-numeric');
                $reason = $prop->{content} if ($prop->{name} eq 'health-reason');
                $recommendation = $prop->{content} if ($prop->{name} eq 'health-recommendation');
            }

            $self->{controllers}->{$name}->{ $map_base_type->{ $_->{basetype} } }->{$id} = {
                name => $id,
                status => $status,
                reason => defined($reason) ? $reason : '-',
                recommendation => defined($recommendation) ? $recommendation : '-'
            };
        }
    }

    if (scalar(keys %{$self->{controllers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No controller found.');
        $self->{output}->option_exit();
    }

    my ($stats) = $options{custom}->get_infos(
        cmd => 'show controller-statistics', 
        base_type => 'controller-statistics',
        properties_name => '^durable-id|data-read-numeric|data-written-numeric|write-cache-hits|write-cache-misses|read-cache-hits|read-cache-misses|iops$'
    );

    foreach (@$stats) {
        my $name = lc($_->{'durable-id'});
        next if (!defined($self->{controllers}->{$name}));
        $self->{controllers}->{$name}->{controller_stats} = $_;
    }

    $self->{cache_name} = 'hp_p2000_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_controller_name}) ? md5_hex($self->{option_results}->{filter_controller_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check controllers.

=over 8

=item B<--filter-controller-name>

Filter controllers by controller name (can be a regexp).

=item B<--unknown-controller-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-controller-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-controller-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-network-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-network-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-network-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-port-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-port-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-port-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-expander-port-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-expander-port-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-expander-port-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-compact-flash-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-compact-flash-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-compact-flash-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read', 'write', 'iops', 'write-cache-hits', 'read-cache-hits'.

=back

=cut
