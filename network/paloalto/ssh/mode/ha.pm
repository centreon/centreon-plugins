#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_sync_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'sync status: %s [enabled: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{enabled}
    );
    return $msg;
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
    return $msg;
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
                { name => 'link', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{sync} = [
        { label => 'sync-status', threshold => 0, set => {
                key_values => [ { name => 'enabled' }, { name => 'status'} ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_sync_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'member-status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{link} = [
        { label => 'link-status',  threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
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
        'unknown-member-status:s'  => { name => 'unknown_member_status', default => '' },
        'warning-member-status:s'  => { name => 'warning_member_status', default => '' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{state} ne %{stateLast}' },
        'unknown-link-status:s'    => { name => 'unknown_link_status', default => '' },
        'warning-link-status:s'    => { name => 'warning_link_status', default => '' },
        'critical-link-status:s'   => { name => 'critical_link_status', default => '%{status} ne "up"' },
        'unknown-sync-status:s'    => { name => 'unknown_sync_status', default => '' },
        'warning-sync-status:s'    => { name => 'warning_sync_status', default => '' },
        'critical-sync-status:s'   => { name => 'critical_sync_status', default => '%{enabled} eq "yes" and %{status} ne "synchronized"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_sync_status', 'warning_sync_status', 'critical_sync_status',
            'unknown_member_status', 'warning_member_status', 'critical_member_status',
            'unknown_link_status', 'warning_link_status', 'critical_link_status'
        ]
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show high-availability state');
    if ($result->{enabled} ne 'yes') {
        $self->{output}->add_option_msg(short_msg => 'high-availibility is disbaled');
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
Can used special variables like: %{enabled}, %{status}

=item B<--warning-sync-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{enabled}, %{status}

=item B<--critical-sync-status>

Set critical threshold for status (Default: '%{enabled} eq "yes" and %{status} ne "synchronized"').
Can used special variables like: %{enabled}, %{status}

=item B<--unknown-member-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{stateLast}

=item B<--warning-member-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{stateLast}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{state} ne %{stateLast}').
Can used special variables like: %{state}, %{stateLast}

=item B<--unknown-link-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{status} ne "up"').
Can used special variables like: %{status}, %{display}

=back

=cut
