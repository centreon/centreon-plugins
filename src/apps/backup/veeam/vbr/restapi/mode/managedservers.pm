#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::vbr::restapi::mode::managedservers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded value_of/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of managed servers ';
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return sprintf(
        "managed server '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'servers', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_server_output', message_multiple => 'All managed servers are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'servers-detected', nlabel => 'managedservers.detected.count', unknown_default => '@0', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    foreach my $status ('available', 'unavailable') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'servers-' . $status, nlabel => 'managedservers.' . $status . '.count', set => {
                key_values => [ { name => $status }, { name => 'detected' } ],
                output_template => $status . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'detected' }
                ]
            }
        };
    }

    $self->{maps_counters}->{servers} = [
        {
            label => 'server-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /unavailable/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'type' } ],
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
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'include-type:s' => { name => 'include_type', default => '' },
        'exclude-type:s' => { name => 'exclude_type', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $servers = $options{custom}->get_managed_servers();

    $self->{global} = { detected => 0, available => 0, unavailable => 0 };
    $self->{servers} = {};

    foreach my $server (@$servers) {
        next if is_excluded($server->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
            || is_excluded($server->{type}, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});

        my $status = value_of($server, '->{status}', 'Unknown');
        $self->{servers}->{ $server->{id} } = {
            id => $server->{id},
            name => $server->{name},
            type => value_of($server, '->{type}', 'Unknown'),
            status => $status
        };

        $self->{global}->{detected}++;
        $self->{global}->{ lc($status) }++
            if defined($self->{global}->{ lc($status) });
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'type', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $server (sort { $a->{name} cmp $b->{name} } values %{$self->{servers}}) {
        $self->{output}->add_disco_entry(
            id => $server->{id},
            name => $server->{name},
            type => $server->{type},
            status => $server->{status}
        );
    }
}

1;

__END__

=head1 MODE

Check managed servers (backup infrastructure hosts such as vCenter, Hyper-V, Windows or Linux servers) availability.

=over 8

=item B<--include-name>

Filter managed servers by name (can be a regexp).

=item B<--exclude-name>

Exclude managed servers by name (can be a regexp).

=item B<--include-type>

Filter managed servers by type (can be a regexp). Example: C<ViHost>, C<WindowsHost>, C<LinuxHost>.

=item B<--exclude-type>

Exclude managed servers by type (can be a regexp).

=item B<--warning-server-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}, %{type}

=item B<--critical-server-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /unavailable/i').
You can use the following variables: %{status}, %{name}, %{type}

=item B<--warning-servers-detected>

Threshold.

=item B<--critical-servers-detected>

Threshold.

=item B<--warning-servers-available>

Threshold.

=item B<--critical-servers-available>

Threshold.

=item B<--warning-servers-unavailable>

Threshold.

=item B<--critical-servers-unavailable>

Threshold.

=back

=cut
