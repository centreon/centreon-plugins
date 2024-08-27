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

package storage::hp::3par::ssh::mode::cages;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_status'};
    $self->{result_values}->{cage_id} = $options{new_datas}->{$self->{instance} . '_cage_id'};
    $self->{result_values}->{board_id} = $options{new_datas}->{$self->{instance} . '_board_id'};

    return 0;
}

sub cage_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cage '%s'",
        $options{instance_value}->{cage_id}
    );
}

sub prefix_cage_output {
    my ($self, %options) = @_;

    return sprintf(
        "cage '%s' ",
        $options{instance_value}->{cage_id}
    );
}

sub prefix_board_output {
    my ($self, %options) = @_;

    return "board '" . $options{instance_value}->{board_id} . "' ";
}

sub prefix_psu_output {
    my ($self, %options) = @_;

    return "power supply '" . $options{instance_value}->{psu_id} . "' ";
}

sub prefix_drive_output {
    my ($self, %options) = @_;

    return "drive '" . $options{instance_value}->{drive_id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'cages', type => 3, cb_prefix_output => 'prefix_cage_output', cb_long_output => 'cage_long_output', indent_long_output => '    ', message_multiple => 'All cages are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'boards', display_long => 1, cb_prefix_output => 'prefix_board_output',
                  message_multiple => 'all boards are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'psu', display_long => 1, cb_prefix_output => 'prefix_psu_output',
                  message_multiple => 'all power supplies are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'drives', display_long => 1, cb_prefix_output => 'prefix_drive_output',
                  message_multiple => 'all drives are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /Normal/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'cage_id' } ],
                output_template => 'overall status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{boards} = [
        {
            label => 'board-firmware-status',
            type => 2,
            critical_default => '%{status} !~ /Current/i',
            set => {
                key_values => [ { name => 'firmware_status' }, { name => 'cage_id' }, { name => 'board_id' } ],
                closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => 'firmware' },
                output_template => 'firmware status: %s',
                output_use => 'status',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach ('self', 'partner') {
        push @{$self->{maps_counters}->{boards}}, 
            {
                label => 'board-' . $_ . '-status',
                type => 2,
                critical_default => '%{status} !~ /ok/i',
                set => {
                    key_values => [ { name => $_ . '_status' }, { name => 'cage_id' }, { name => 'board_id' } ],
                    closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    output_template => $_ . ' status: %s',
                    output_use => 'status',
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            };
    }

    $self->{maps_counters}->{psu} = [
        {
            label => 'psu-status',
            type => 2,
            critical_default => '%{status} !~ /ok/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'cage_id' }, { name => 'psu_id' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach ('ac', 'dc', 'fan') {
        push @{$self->{maps_counters}->{psu}}, 
            {
                label => 'psu-' . $_ . '-status',
                type => 2,
                critical_default => '%{status} !~ /ok/i',
                set => {
                    key_values => [ { name => $_ . '_status' }, { name => 'cage_id' }, { name => 'psu_id' } ],
                    closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    output_template => $_ . ' status: %s',
                    output_use => 'status',
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            };
    }

    $self->{maps_counters}->{drives} = [
        {
            label => 'drive-status',
            type => 2,
            critical_default => '%{status} !~ /normal/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'cage_id' }, { name => 'drive_id' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach ('portA', 'portB') {
        push @{$self->{maps_counters}->{drives}}, 
            {
                label => 'drive-' . lc($_) . '-status',
                type => 2,
                critical_default => '%{status} !~ /ok/i',
                set => {
                    key_values => [ { name => $_ . '_status' }, { name => 'cage_id' }, { name => 'drive_id' } ],
                    closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    output_template => $_ . ' status: %s',
                    output_use => 'status',
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            };
    }

    push @{$self->{maps_counters}->{drives}}, 
        { label => 'drive-temperature', nlabel => 'drive.temperature.celsius', set => {
                key_values => [ { name => 'temperature' }, { name => 'cage_id' }, { name => 'drive_id' } ],
                output_template => 'temperature: %s C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => ['cage' . $self->{result_values}->{cage_id}, 'drive' . $self->{result_values}->{drive_id}],
                        value => sprintf('%s', $self->{result_values}->{temperature}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        },
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-cage-id:s' => { name => 'filter_cage_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(commands => ['showcage -d']);

    $self->{cages} = {};
    while ($content =~ /(Cage\s+detail\s+info\s+for\s+cage(\d+).*?)(?=Cage\s+detail\s+info\s+for\s+cage|\Z$)/msig) {
        my ($cage_id, $entry) = ($2, $1);

        next if (defined($self->{option_results}->{filter_cage_id}) && $self->{option_results}->{filter_cage_id} ne '' &&
            $cage_id !~ /$self->{option_results}->{filter_cage_id}/);

        $self->{cages}->{ 'cage' . $cage_id } = {
            cage_id => $cage_id,
            global => { cage_id => $cage_id },
            boards => {},
            psu => {},
            drives => {}
        };
        $self->{cages}->{ 'cage' . $cage_id }->{global}->{status} = $1 if ($entry =~ /^OverallState:\s*(\S+)/msi);

        if ($entry =~ /^Interface\s+Board\s+Info\s+(.*)/m) {
            my @boards = split(/\s+/, $1);
            my (@firmwares, @states);
            @firmwares = split(/\s+/, $1) if ($entry =~ /^Firmware_status\s+(.*)/m);
            @states = split(/\s+/, $1) if ($entry =~ /^State\(self,partner\)\s+(.*)/m);
            for (my $i = 0; $i < scalar(@boards); $i++) {
                next if ($boards[$i] !~ /(\d+)/);
                my $board_id = $1;
                $self->{cages}->{ 'cage' . $cage_id }->{boards}->{$board_id} = {
                    cage_id => $cage_id,
                    board_id => $board_id
                };
                $self->{cages}->{ 'cage' . $cage_id }->{boards}->{$board_id}->{firmware_status} = $firmwares[$i];
                my ($itself, $partner) = split(/,/, $states[$i]);
                $self->{cages}->{ 'cage' . $cage_id }->{boards}->{$board_id}->{self_status} = $itself;
                $self->{cages}->{ 'cage' . $cage_id }->{boards}->{$board_id}->{partner_status} = $partner;
            }
        }

        while ($entry =~ /^\s*ps(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/mg) {
            my ($psu_id, $status, $ac_status, $dc_status, $fan_status) = ($1, $2, $3, $4, $5);
            $self->{cages}->{ 'cage' . $cage_id }->{psu}->{$psu_id} = {
                cage_id => $cage_id,
                psu_id => $psu_id,
                status => $status,
                ac_status => $ac_status,
                dc_status => $dc_status,
                fan_status => $fan_status
            };
        }

        while ($entry =~ /^\s*(\d+:\d+)\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/mg) {
            $self->{cages}->{ 'cage' . $cage_id }->{drives}->{$1} = {
                cage_id => $cage_id,
                drive_id => $1,
                status => $2,
                temperature => $3,
                portA_status => $4,
                portB_status => $5
            };
        }
    }

    if (scalar(keys %{$self->{cages}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get cages information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check cages.

=over 8

=item B<--filter-cage-id>

Filter cages by ID (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /Normal/i')
You can use the following variables: %{status}, %{cage_id}

=item B<--unknown-board-firmware-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-board-firmware-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-board-firmware-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /Current/i')
You can use the following variables: %{status}, %{cage_id}, %{board_id}

=item B<--unknown-board-[self|partner]-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-board-[self|partner]-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-board-[self|partner]-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i')
You can use the following variables: %{status}, %{cage_id}, %{board_id}


=item B<--unknown-psu-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-psu-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-psu-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i')
You can use the following variables: %{status}, %{cage_id}, %{psu_id}

=item B<--unknown-psu-[ac|dc|fan]-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-psu-[ac|dc|fan]-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-psu-[ac|dc|fan]-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i')
You can use the following variables: %{status}, %{cage_id}, %{psu_id}

=item B<--unknown-drive-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-drive-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-drive-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /normal/i')
You can use the following variables: %{status}, %{cage_id}, %{drive_id}

=item B<--unknown-drive-[porta|portb]-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-drive-[porta|portb]-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-drive-[porta|portb]-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i')
You can use the following variables: %{status}, %{cage_id}, %{drive_id}

=item B<--warning-drive-temperature>

Define WARNING threshold for the temperature of the drives.

=item B<--critical-drive-temperature>

Define CRITICAL threshold for the temperature of the drives.

=back

=cut
