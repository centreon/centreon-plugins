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

package apps::vmware::connector::mode::storagehost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{status} . ', maintenance mode is ' . $self->{result_values}->{maintenance};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{maintenance} = $options{new_datas}->{$self->{instance} . '_maintenance'};
    return 0;
}

sub custom_adapter_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance} . "'";
}

sub prefix_adapters_output {
    my ($self, %options) = @_;

    return 'adapters ';
}

sub prefix_adapter_output {
    my ($self, %options) = @_;

    return "adapter '" . $options{instance_value}->{name} . "' ";
}

sub prefix_luns_output {
    my ($self, %options) = @_;

    return 'luns ';
}

sub prefix_lun_output {
    my ($self, %options) = @_;

    return "lun '" . $options{instance_value}->{name} . "' ";
}

sub prefix_paths_output {
    my ($self, %options) = @_;

    return 'paths ';
}

sub prefix_path_output {
    my ($self, %options) = @_;

    return "path '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'adapters_global', type => 0, cb_prefix_output => 'prefix_adapters_output', skipped_code => { -10 => 1 } },
                { name => 'luns_global', type => 0, cb_prefix_output => 'prefix_luns_output', skipped_code => { -10 => 1 } },
                { name => 'paths_global', type => 0, cb_prefix_output => 'prefix_paths_output', skipped_code => { -10 => 1 } },
                { name => 'adapters', type => 1, display_long => 1, cb_prefix_output => 'prefix_adapter_output', message_multiple => 'All adapters are ok', skipped_code => { -10 => 1 } },
                { name => 'luns', type => 1, display_long => 1, cb_prefix_output => 'prefix_lun_output', message_multiple => 'All luns are ok', skipped_code => { -10 => 1 } },
                { name => 'paths', type => 1, display_long => 1, cb_prefix_output => 'prefix_path_output', message_multiple => 'All paths are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i && %{maintenance} =~ /false/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'maintenance' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{adapters_global} = [];
    foreach ('total', 'online', 'offline', 'fault', 'unknown') {
        push @{$self->{maps_counters}->{adapters_global}}, {
            label => 'adapters-' . $_, nlabel => 'host.adapters.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        };
    }

    $self->{maps_counters}->{luns_global} = [];
    foreach ('total', 'ok', 'error', 'off', 'unknown', 'quiesced', 'degraded') {
        push @{$self->{maps_counters}->{luns_global}}, {
            label => 'luns-' . $_, nlabel => 'host.luns.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        };
    }

    $self->{maps_counters}->{paths_global} = [];
    foreach ('total', 'active', 'disabled', 'standby', 'dead', 'unknown') {
        push @{$self->{maps_counters}->{paths_global}}, {
            label => 'paths-' . $_, nlabel => 'host.paths.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        };
    }

    $self->{maps_counters}->{adapters} = [
        {
            label => 'adapter-status', type => 2, critical_default => '%{status} =~ /fault/',
            set => {
                key_values => [ { name => 'name' }, { name => 'status' }, { name => 'host' } ],
                closure_custom_output => $self->can('custom_adapter_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{luns} = [
        {
            label => 'lun-status',
            type => 2,
            warning_default => '%{status} =~ /degraded|quiesced/',
            critical_default => '%{status} =~ /lostcommunication|error/',
            set => {
                key_values => [ { name => 'name' }, { name => 'status' }, { name => 'host' } ],
                closure_custom_output => $self->can('custom_adapter_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{paths} = [
        {
            label => 'path-status',
            type => 2,
            critical_default => '%{status} =~ /dead/',
            set => {
                key_values => [ { name => 'name' }, { name => 'status' }, { name => 'host' } ],
                closure_custom_output => $self->can('custom_adapter_output'),
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
        'esx-hostname:s'        => { name => 'esx_hostname' },
        'filter'                => { name => 'filter' },
        'scope-datacenter:s'    => { name => 'scope_datacenter' },
        'scope-cluster:s'       => { name => 'scope_cluster' },
        'filter-adapter-name:s' => { name => 'filter_adapter_name' },
        'filter-lun-name:s'     => { name => 'filter_lun_name' },
        'filter-path-name:s'    => { name => 'filter_path_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'storagehost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = {
            global => {
                state => $response->{data}->{$host_id}->{state},
                maintenance => $response->{data}->{$host_id}->{inMaintenanceMode}
            }
        };

        if (defined($response->{data}->{$host_id}->{adapters})) {
            $self->{host}->{$host_name}->{adapters} = {};
            $self->{host}->{$host_name}->{adapters_global} = {
                online => 0, offline => 0, fault => 0, unknown => 0, total => 0
            };
            foreach (@{$response->{data}->{$host_id}->{adapters}}) {
                next if (defined($self->{option_results}->{filter_adapter_name}) && $self->{option_results}->{filter_adapter_name} ne '' &&
                    $_->{name} !~ /$self->{option_results}->{filter_adapter_name}/);

                $self->{host}->{$host_name}->{adapters_global}->{total}++;
                if (defined($self->{host}->{$host_name}->{adapters_global}->{ $_->{status} })) {
                    $self->{host}->{$host_name}->{adapters_global}->{ $_->{status} }++;
                } else {
                    $self->{host}->{$host_name}->{adapters_global}->{unknown}++;
                }
                $self->{host}->{$host_name}->{adapters}->{ $_->{name} } = {
                    name => $_->{name}, 
                    host => $host_name,
                    status => $_->{status}
                };
            }
        }

        if (defined($response->{data}->{$host_id}->{luns})) {
            $self->{host}->{$host_name}->{luns} = {};
            $self->{host}->{$host_name}->{luns_global} = {
                ok => 0, error => 0, off => 0, unknown => 0, quiesced => 0, degraded => 0, total => 0
            };
            foreach (@{$response->{data}->{$host_id}->{luns}}) {
                next if (defined($self->{option_results}->{filter_lun_name}) && $self->{option_results}->{filter_lun_name} ne '' &&
                    $_->{name} !~ /$self->{option_results}->{filter_lun_name}/);

                $self->{host}->{$host_name}->{luns_global}->{total}++;
                foreach my $state (@{$_->{operational_states}}) {
                    if (defined($self->{host}->{$host_name}->{luns_global}->{$state})) {
                    $self->{host}->{$host_name}->{luns_global}->{$state}++;
                    } else {
                        $self->{host}->{$host_name}->{luns_global}->{unknown}++;
                    }
                }

                $self->{host}->{$host_name}->{luns}->{ $_->{name} } = {
                    name => $_->{name}, 
                    host => $host_name,
                    status => join(',', @{$_->{operational_states}})
                };
            }
        }

        if (defined($response->{data}->{$host_id}->{paths})) {
            $self->{host}->{$host_name}->{paths} = {};
            $self->{host}->{$host_name}->{paths_global} = {
                active => 0, disabled => 0, standby => 0, dead => 0, unknown => 0
            };
            foreach (@{$response->{data}->{$host_id}->{paths}}) {
                next if (defined($self->{option_results}->{filter_path_name}) && $self->{option_results}->{filter_path_name} ne '' &&
                    $_->{name} !~ /$self->{option_results}->{filter_path_name}/);

                $self->{host}->{$host_name}->{paths_global}->{total}++;
                if (defined($self->{host}->{$host_name}->{paths_global}->{ $_->{state} })) {
                    $self->{host}->{$host_name}->{paths_global}->{ $_->{state} }++;
                } else {
                    $self->{host}->{$host_name}->{paths_global}->{unknown}++;
                }

                $self->{host}->{$host_name}->{paths}->{ $_->{name} } = {
                    name => $_->{name}, 
                    host => $host_name,
                    status => $_->{state}
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check ESX storage infos.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--filter-adapter-name>

Filter adapters by name (can be a regexp).

=item B<--filter-lun-name>

Filter luns by name (can be a regexp).

=item B<--filter-path-name>

Filter paths by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} !~ /^connected$/i && %{maintenance} =~ /false/i').
You can use the following variables: %{status}, %{maintenance}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{maintenance}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{maintenance}

=item B<--warning-adapter-status>

Set warning threshold for adapter status.
You can use the following variables: %{name}, %{host}, %{status}

=item B<--critical-adapter-status>

Set critical threshold for adapter status (default: '%{status} =~ /fault/').
You can use the following variables: %{name}, %{host}, %{status}

=item B<--warning-lun-status>

Set warning threshold for lun status (default: '%{status} =~ /degraded|quiesced/').
You can use the following variables: %{name}, %{host}, %{status}

=item B<--critical-lun-status>

Set critical threshold for lun status (default: '%{status} =~ /lostcommunication|error/').
You can use the following variables: %{name}, %{host}, %{status}

=item B<--warning-path-status>

Set warning threshold for path status.
You can use the following variables: %{name}, %{host}, %{status}

=item B<--critical-path-status>

Set critical threshold for path status (default: '%{status} =~ /dead/').
You can use the following variables: %{name}, %{host}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'adapters-total', 'adapters-online', 'adapters-offline', 'adapters-fault', 'adapters-unknown',


=back

=cut
