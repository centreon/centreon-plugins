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

package apps::virtualization::hpe::simplivity::restapi::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of hosts ';
}

sub prefix_components_output {
    my ($self, %options) = @_;

    return 'number of components ';
}

sub host_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking host '%s'",
        $options{instance}
    );
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return sprintf(
        "host '%s' ",
        $options{instance}
    );
}

sub prefix_ldrive_output {
    my ($self, %options) = @_;

    return "logical drive '" . $options{instance} . "' ";
}

sub prefix_pdrive_output {
    my ($self, %options) = @_;

    return "physical drive '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'hosts', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All hosts are ok',
            group => [
                { name => 'host_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'components', type => 0, cb_prefix_output => 'prefix_components_output', skipped_code => { -10 => 1 } },
                { name => 'raid', type => 0, skipped_code => { -10 => 1 } },
                { name => 'ldrives', display_long => 1, cb_prefix_output => 'prefix_ldrive_output', message_multiple => 'logical drives are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'pdrives', display_long => 1, cb_prefix_output => 'prefix_pdrive_output', message_multiple => 'physical drives are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('alive', 'faulty', 'managed', 'removed', 'suspected', 'unknown') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'hosts-' . $_, nlabel => 'hosts.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s' }
                ]
            }
        };
    }

    $self->{maps_counters}->{components} = [];
    foreach ('green', 'yellow', 'red', 'unknown') {
        push @{$self->{maps_counters}->{components}}, {
            label => 'host-components-' . $_, nlabel => 'host.components.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', label_extra_instance => 1 }
                ]
            }
        };
    }

    $self->{maps_counters}->{host_status} = [
        {
            label => 'host-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/',
            warning_default => '%{status} =~ /suspected/',
            critical_default => '%{status} =~ /faulty/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{raid} = [
        {
            label => 'raid-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/',
            warning_default => '%{status} =~ /yellow/',
            critical_default => '%{status} =~ /red/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'raid card status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{ldrives} = [
        {
            label => 'logical-drive-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/',
            warning_default => '%{status} =~ /yellow/',
            critical_default => '%{status} =~ /red/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{pdrives} = [
        {
            label => 'physical-drive-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/',
            warning_default => '%{status} =~ /yellow/',
            critical_default => '%{status} =~ /red/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $hosts = $options{custom}->get_hosts();

    $self->{global} = { alive => 0, faulty => 0, managed => 0, removed => 0, suspected => 0, unknown => 0 };
    $self->{hosts} = {};
    foreach my $host (@{$hosts->{hosts}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $host->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $host->{name}  . "': no matching filter.", debug => 1);
            next;
        }

        $host->{state} = lc($host->{state});
        $self->{global}->{ $host->{state} }++;
        $self->{hosts}->{ $host->{name} } = {
            host_status => { status => $host->{state}, name => $host->{name} },
            components => { green => 0, yellow => 0, red => 0, unknown => 0 },
            ldrives => {},
            pdrives => {}
        };

        my $hw = $options{custom}->get_host_hardware(id => $host->{id});
        $self->{hosts}->{ $host->{name} }->{raid} = {
            status => lc($hw->{host}->{raid_card}->{status})
        };
        $self->{hosts}->{ $host->{name} }->{components}->{ lc($hw->{host}->{raid_card}->{status}) }++;

        foreach my $ldrive (@{$hw->{host}->{logical_drives}}) {
            $ldrive->{name} = $1 if ($ldrive->{name} =~ /Logical\s+Drive\s+(\d+)/);
            $self->{hosts}->{ $host->{name} }->{components}->{ lc($ldrive->{status}) }++;
            $self->{hosts}->{ $host->{name} }->{ldrives}->{ $ldrive->{name} } = {
                name => $ldrive->{name},
                status => lc($ldrive->{status})
            };

            foreach my $entry (@{$ldrive->{drive_sets}}) {
                foreach my $pdrive (@{$entry->{physical_drives}}) {
                    $self->{hosts}->{ $host->{name} }->{components}->{ lc($pdrive->{status}) }++;
                    my $name = $ldrive->{name} . ':' . $pdrive->{drive_position};
                    $self->{hosts}->{ $host->{name} }->{pdrives}->{$name} = {
                        name => $name,
                        status => lc($pdrive->{status})
                    };
                }
            }
        }
    }
}


1;

__END__

=head1 MODE

Check hosts.

=over 8

=item B<--filter-name>

Filter hosts by name.

=item B<--unknown-host-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown/').
You can use the following variables: %{status}, %{name}

=item B<--warning-host-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /suspected/').
You can use the following variables: %{status}, %{name}

=item B<--critical-host-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /faulty/').
You can use the following variables: %{status}, %{name}

=item B<--unknown-raid-status>

Set unknown threshold for component status (default: '%{status} =~ /unknown/').
You can use the following variables: %{status}, %{name}

=item B<--warning-raid-status>

Set warning threshold for component status (default: '%{status} =~ /yellow/').
You can use the following variables: %{status}, %{name}

=item B<--critical-raid-status>

Set critical threshold for component status (default: '%{status} =~ /red/').
You can use the following variables: %{status}, %{name}

=item B<--unknown-logical-drive-status>

Set unknown threshold for component status (default: '%{status} =~ /unknown/').
You can use the following variables: %{status}, %{name}

=item B<--warning-logical-drive-status>

Set warning threshold for component status (default: '%{status} =~ /yellow/').
You can use the following variables: %{status}, %{name}

=item B<--critical-logical-drive-status>

Set critical threshold for component status (default: '%{status} =~ /red/').
You can use the following variables: %{status}, %{name}

=item B<--unknown-physical-drive-status>

Set unknown threshold for component status (default: '%{status} =~ /unknown/').
You can use the following variables: %{status}, %{name}

=item B<--warning-physical-drive-status>

Set warning threshold for component status (default: '%{status} =~ /yellow/').
You can use the following variables: %{status}, %{name}

=item B<--critical-physical-drive-status>

Set critical threshold for component status (default: '%{status} =~ /red/').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'hosts-alive', 'hosts-faulty', 'hosts-managed', 'hosts-removed', 'hosts-suspected', 'hosts-unknown',
'host-components-green', 'host-components-yellow', 'host-components-red', 'host-components-unknown'.

=back

=cut
