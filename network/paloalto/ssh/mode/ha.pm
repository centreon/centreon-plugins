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

package network::paloalto::ssh::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_sync_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'sync status: %s [enabled: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{enabled}
    );
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{stateLast} = $options{old_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    if (!defined($options{old_datas}->{$self->{instance} . '_state'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s',
        $self->{result_values}->{status},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sync', type => 0 },
        { name => 'member', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All members are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'link', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{sync} = [
        { label => 'sync-status', type => 2, critical_default => '%{enabled} eq "yes" and %{status} ne "synchronized"', set => {
                key_values => [ { name => 'enabled' }, { name => 'status'} ],
                closure_custom_output => $self->can('custom_sync_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'member-status', type => 2, critical_default => '%{state} ne %{stateLast}', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{link} = [
        { label => 'link-status', type => 2, critical_default => '%{status} ne "up"', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub member_long_output {
    my ($self, %options) = @_;

    return "checking member '" . $options{instance_value}->{display} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{display} . "' ";
}

sub prefix_link_output {
    my ($self, %options) = @_;

    return "link '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show high-availability state');
    if ($result->{enabled} ne 'yes') {
        $self->{output}->add_option_msg(short_msg => 'high-availibility is disabled');
        $self->{output}->option_exit();
    }

    $self->{member} = {
        local => { display => 'local', global => { display => 'local' } },
        peer =>  { display => 'peer', global => { display => 'peer' }, link => {} }
    };
    $self->{member}->{local}->{global}->{state} = $result->{group}->{'local-info'}->{state};
    $self->{member}->{peer}->{global}->{state} = $result->{group}->{'peer-info'}->{state};

    foreach (keys %{$result->{group}->{'peer-info'}}) {
        next if (!/^conn-(.*)$/ || ref($result->{group}->{'peer-info'}->{$_}) ne 'HASH');
        my $name = $1 . '-' . $result->{group}->{'peer-info'}->{$_}->{'conn-desc'};
        $self->{member}->{peer}->{link}->{$name} = {
            display => $name,
            status => $result->{group}->{'peer-info'}->{$_}->{'conn-status'}
        };
    }

    $self->{sync} = {
        enabled => $result->{group}->{'running-sync-enabled'},
        status  => $result->{group}->{'running-sync'}
    };

    $self->{cache_name} = "paloalto_" . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check high availability.

=over 8

=item B<--unknown-sync-status>

Set unknown threshold for status (Default: '').
Can use special variables like: %{enabled}, %{status}

=item B<--warning-sync-status>

Set warning threshold for status (Default: '').
Can use special variables like: %{enabled}, %{status}

=item B<--critical-sync-status>

Set critical threshold for status (Default: '%{enabled} eq "yes" and %{status} ne "synchronized"').
Can use special variables like: %{enabled}, %{status}

=item B<--unknown-member-status>

Set unknown threshold for status (Default: '').
Can use special variables like: %{state}, %{stateLast}

=item B<--warning-member-status>

Set warning threshold for status (Default: '').
Can use special variables like: %{state}, %{stateLast}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{state} ne %{stateLast}').
Can use special variables like: %{state}, %{stateLast}

=item B<--unknown-link-status>

Set unknown threshold for status (Default: '').
Can use special variables like: %{status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status (Default: '').
Can use special variables like: %{status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{status} ne "up"').
Can use special variables like: %{status}, %{display}

=back

=cut
