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

package apps::backup::netbackup::local::mode::dedupstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    if (!defined($self->{instance_mode}->{option_results}->{'critical-usage'}) || $self->{instance_mode}->{option_results}->{'critical-usage'} eq '') {
        $self->{perfdata}->threshold_validate(label => 'critical-usage', value => $self->{result_values}->{watermark});
    }
    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{usage}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Disk volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All dedup status are ok' }
    ];
    
    $self->{maps_counters}->{volume} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /up/i', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'disk_pool.deduplication.usage.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'watermark' }, { name => 'display' } ],
                output_template => 'use: %s %%',
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                perfdatas => [
                    { label => 'used', template => '%s', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'exec-only'     => { name => 'exec_only' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'nbdevquery',
        command_options => '-listdp -U'
    );

    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    }

    #Disk Pool Name   : NBU-MASTER-DP
    #Disk Pool Id     : NBU-MASTER-DP
    #Disk Type        : PureDisk
    #Status           : UP
    #Flag             : Patchwork
    #Raw Size (GB)    : 19236.97
    #Usable Size (GB) : 19236.97
    #High Watermark   : 99
    #Low Watermark    : 60
    #Num Volumes      : 1
    #Max IO Streams   : -1
    my $watermark = {};
    while ($stdout =~ /^(Disk Pool Name.*?)(?=Disk Pool Name|\z)/msig) {
        my $pool = $1;

        $pool =~ /^Disk Pool Name\s*:\s*(.*?)\n/msi;
        my $display = centreon::plugins::misc::trim($1);
        $pool =~ /^High Watermark\s*:\s*(.*?)\n/msi;
        $watermark->{$display} = centreon::plugins::misc::trim($1);
    }

    ($stdout) = $options{custom}->execute_command(
        command => 'nbdevquery',
        command_options => '-listdv -U -stype PureDisk'
    );
    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    $self->{volume} = {};
    #Disk Pool Name      : NBU-MASTER-DP
    #Disk Type           : PureDisk
    #Disk Volume Name    : PureDiskVolume
    #Disk Media ID       : @aaaah
    #Total Capacity (GB) : 9777.56
    #Free Space (GB)     : 837.72
    #Use%                : 91
    #Status              : UP
    #Flag                : ReadOnWrite
    #Flag                : AdminUp
    #Flag                : InternalUp
    while ($stdout =~ /^(Disk Pool Name.*?)(?=Disk Pool Name|\z)/msig) {
        my $volume = $1;

        my ($pool_name, $volume_name, $usage, $status);
        $pool_name = centreon::plugins::misc::trim($1) if ($volume =~ /^Disk Pool Name\s*:\s*(.*?)\n/msi);
        $volume_name = centreon::plugins::misc::trim($1) if ($volume =~ /^Disk Volume Name\s*:\s*(.*?)\n/msi);
        $status = $1 if ($volume =~ /^Status\s*:\s*(.*?)\n/msi);
        $usage = $1 if ($volume =~ /^Use%\s*:\s*(.*?)\n/msi);

        my $display = $pool_name . '.' . $volume_name;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        $self->{volume}->{$display} = { display => $display, usage => $usage, status => $status, watermark => $watermark->{$pool_name} };
    }

    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No volume found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check deduplication status.

Commands used: 'nbdevquery -listdp -U' and 'nbdevquery -listdv -U -stype PureDisk'

=over 8

=item B<--exec-only>

Print command output

=item B<--filter-name>

Filter pool name (can be a regexp).

=item B<--warning-usage>

Set warning threshold in percent.

=item B<--critical-usage>

Set critical threshold in percent.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{display}, %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /up/i').
You can use the following variables: %{display}, %{status}

=back

=cut
