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

package apps::drbd::local::mode::resources;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_role_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s',
        $self->{result_values}->{role}
    );
}

sub custom_disk_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{disk_status}
    );
}

sub custom_peer_role_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s',
        $self->{result_values}->{role}
    );
}

sub custom_peer_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection status: %s',
        $self->{result_values}->{connection_status}
    );
}

sub custom_peer_device_replication_output {
    my ($self, %options) = @_;

    return sprintf(
        'replication status: %s',
        $self->{result_values}->{device_replication_status}
    );
}

sub custom_peer_device_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        'disk status: %s',
        $self->{result_values}->{device_disk_status}
    );
}

sub resource_long_output {
    my ($self, %options) = @_;

    return "checking resource '" . $options{instance_value}->{display} . "'";
}

sub prefix_resource_output {
    my ($self, %options) = @_;

    return "resource '" . $options{instance_value}->{display} . "' ";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return 'device disk ';
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    return "peer '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'resources', type => 3, cb_prefix_output => 'prefix_resource_output', cb_long_output => 'resource_long_output', indent_long_output => '    ', message_multiple => 'All drbd resources are ok',
            group => [
                { name => 'role', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device', type => 0, cb_prefix_output => 'prefix_device_output', skipped_code => { -10 => 1 } },
                { name => 'peers', display_long => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All peers are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'resources-total', nlabel => 'resources.total.count', set => {
                key_values => [ { name => 'resources_total' } ],
                output_template => 'total resources: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{role} = [
        {
            label => 'role',
            type => 2,
            unknown_default => '%{role} =~ /unknown/i',
            critical_default => '%{role} =~ /unconfigured/i',
            set => {
                key_values => [ { name => 'role' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_role_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{device} = [
        {
            label => 'disk-status',
            type => 2,
            unknown_default => '%{disk_status} =~ /dunknown/i',
            warning_default => '%{disk_status} =~ /attaching|detaching|negotiating/i',
            critical_default => '%{disk_status} =~ /outdated|inconsistent|failed|diskless/i',
            set => {
                key_values => [ { name => 'disk_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_disk_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'data-read', nlabel => 'disk.data.read.bytespersecond', set => {
                key_values => [ { name => 'data_read', per_second => 1 }, { name => 'display' } ],
                output_template => 'data read: %s%s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'data-written', nlabel => 'disk.data.written.bytespersecond', set => {
                key_values => [ { name => 'data_written', per_second => 1 }, { name => 'display' } ],
                output_template => 'data written: %s%s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{peers} = [
        {
            label => 'peer-role',
            type => 2,
            unknown_default => '%{role} =~ /unknown/i',
            critical_default => '%{role} =~ /unconfigured/i',
            set => {
                key_values => [ { name => 'role' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_peer_role_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'peer-connection-status',
            type => 2,
            warning_default => '%{connection_status} =~ /^(?:connecting|disconnecting|standalone|teardown)$/i',
            critical_default => '%{connection_status} =~ /^(?:brokenpipe|networkfailure|protocolerror|timeout|unconnected|wfconnection|wfreportparams)$/i',
            set => {
                key_values => [ { name => 'connection_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_peer_connection_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'peer-device-replication-status',
            type => 2,
            warning_default => '%{device_replication_status} =~ /^(?:ahead|off|startingsyncs|startingsynct|syncsource|synctarget|verifys|verifyt|wfsyncuuid|syncingall|syncingquick)$/i',
            critical_default => '%{device_replication_status} =~ /^(?:behind|pausedsyncs|pausedsynct|wfbitmaps|wfbitmapt|syncpaused|skippedsyncs|skippedsynct)$/i',
            set => {
                key_values => [ { name => 'device_replication_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_peer_device_replication_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
             label => 'peer-device-disk-status',
             type => 2,
             unknown_default => '%{device_disk_status} =~ /dunknown/i',
             warning_default => '%{device_disk_status} =~ /^(?:attaching|detaching|diskless|failed|inconsistent|negotiating|outdated)$/i',
             set => {
                key_values => [ { name => 'device_disk_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_peer_device_disk_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'peer-traffic-in', nlabel => 'peer.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'peer-traffic-out', nlabel => 'peer.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
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
         'filter-resource-name:s' => { name => 'filter_resource_name' },
         'legacy-proc'            => { name => 'legacy_proc' }
    });

    return $self;
}

=pod
replication:
    ahead          [WARN]
    behind         [CRIT]
    off            [WARN]
    established    [OK]
    pausedsyncs    [CRIT]
    pausedsynct    [CRIT]
    startingsyncs  [WARN]
    startingsynct  [WARN]
    syncsource     [WARN]
    synctarget     [WARN]
    verifys        [WARN]
    verifyt        [WARN]
    wfbitmaps      [CRIT]
    wfbitmapt      [CRIT]
    wfsyncuuid     [WARN]

connection states:
    brokenpipe     [CRIT]
    connected      [OK]
    connecting     [WARN]
    disconnecting  [WARN]
    networkfailure [CRIT]
    protocolerror  [CRIT]
    standalone     [WARN]
    teardown       [WARN]
    timeout        [CRIT]
    unconnected    [CRIT]
    wfconnection   [CRIT]
    wfreportparams [CRIT]

    # old version - connection and replication are merged (and also unconfigured)
    unconfigured   [CRIT]
    syncingall     [WARN]
    syncingquick   [WARN]
    syncpaused     [CRIT]
    skippedsyncs   [CRIT]
    skippedsynct   [CRIT]

disk states:
    attaching      [WARN]
    consistent     [OK]
    detaching      [WARN]
    diskless       [CRIT]
    dunknown       [WARN]
    failed         [CRIT]
    inconsistent   [CRIT]
    negotiating    [WARN]
    outdated       [CRIT]
    uptodate       [OK]

peer-disk: 
    attaching      [WARN]
    consistent     [OK]
    detaching      [WARN]
    diskless       [WARN]
    dunknown       [WARN]
    failed         [WARN]
    inconsistent   [WARN]
    negotiating    [WARN]
    outdated       [WARN]
    uptodate       [OK]

role:
    primary        [OK]
    secondary      [OK]
    unknown        [WARN]
    unconfigured   [CRIT]

-----------------------
old versions /proc/drbd
-----------------------

0: cs:Connected st:Secondary/Secondary ld:Inconsistent
   ns:0 nr:0 dw:0 dr:0 al:0 bm:17408 lo:0 pe:0 ua:0 ap:0
1: cs:Unconfigured

st = role
ld = Local data consistency

-------------------------

version: 8.3.7 (api:88/proto:86-91)
GIT-hash: ea9e28dbff98e331a62bcbcc63a6135808fe2917 build by root@xxxx, 2012-05-09 11:46:08
 0: cs:Connected ro:Secondary/Primary ds:UpToDate/UpToDate C r----
    ns:17 nr:4207 dw:4224 dr:24 al:1 bm:1 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:0
 1: cs:Connected ro:Secondary/Primary ds:UpToDate/UpToDate C r----
    ns:100808 nr:1272593360 dw:1272711944 dr:19001 al:13 bm:23 lo:0 pe:0 ua:0 ap:0 ep:1 wo:d oos:0

=cut

sub legacy_proc {
    my ($self, %options) = @_;

    # 0 = replication
    # 1 = connection
    # 2 = role
    my $map_connection = {
        ahead => 0, behind => 0, off => 0, established => 0, pausedsyncs => 0,
        pausedsynct => 0, startingsyncs => 0, startingsynct => 0,
        syncsource => 0, synctarget => 0, verifys => 0, verifyt => 0, wfbitmaps => 0,
        wfbitmapt => 0, wfsyncuuid => 0, syncingall => 0, syncingquick => 0,
        syncpaused => 0, skippedsyncs => 0, skippedsynct => 0,
        brokenpipe => 1, connected => 1, connecting => 1,
        disconnecting => 1, networkfailure => 1, protocolerror => 1,
        standalone => 1, teardown => 1, timeout => 1,
        unconnected => 1, wfconnection => 1, wfreportparams => 1,
        unconfigured => 2
    };

    $self->{resources} = {};
    while ($options{stdout} =~ /^\s*(\d+):(.*?)(?=\n\s*(\d+):|\Z$)/msg) {
        my ($res_name, $content) = ($1, $2);

        if (defined($self->{option_results}->{filter_resource_name}) && $self->{option_results}->{filter_resource_name} ne '' &&
            $res_name !~ /$self->{option_results}->{filter_resource_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $res_name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{resources}->{$res_name} = {
            display => $res_name,
            role => { display => $res_name, role => '-' },
            device => { display => $res_name, disk_status => '-' },
            peers => {
                0 => {
                    display => 0,
                    role => '-',
                    connection_status => '-',
                    device_replication_status => '-',
                    device_disk_status => '-'
                }
            }
        };

        if ($content =~ /cs:(\S+)/ms) {
            my $cs = lc($1);
            if ($map_connection->{$cs} == 0) {
                $self->{resources}->{$res_name}->{peers}->{0}->{device_replication_status} = $cs;
            } elsif ($map_connection->{$cs} == 1) {
                $self->{resources}->{$res_name}->{peers}->{0}->{connection_status} = $cs;
            } elsif ($map_connection->{$cs} == 2) {
                $self->{resources}->{$res_name}->{role}->{role} = $cs;
            }
        }

        if ($content =~ /(?:ro|st):(.*?)\/(.*?)\s/ms) {
            $self->{resources}->{$res_name}->{role}->{role} = lc($1);
            $self->{resources}->{$res_name}->{peers}->{0}->{role} = lc($2);
        }

        if ($content =~ /ds:(.*?)\/(.*?)\s/ms) {
            $self->{resources}->{$res_name}->{device}->{disk_status} = lc($1);
            $self->{resources}->{$res_name}->{peers}->{0}->{device_disk_status} = lc($2);
        }
        if ($content =~ /ld:(\S+)/ms) {
            $self->{resources}->{$res_name}->{device}->{disk_status} = lc($1);
        }

        if ($content =~ /dw:(\d+).*?dr:(\d+)/ms) {
            $self->{resources}->{$res_name}->{device}->{data_written} = $1 * 1024;
            $self->{resources}->{$res_name}->{device}->{data_read} = $2 * 1024;
        }
        if ($content =~ /ns:(\d+).*?nr:(\d+)/ms) {
            $self->{resources}->{$res_name}->{peers}->{0}->{traffic_out} = $1 * 1024 * 8;
            $self->{resources}->{$res_name}->{peers}->{0}->{traffic_in} = $2 * 1024 * 8;
        }
    }
}

sub drbdsetup_events2 {
    my ($self, %options) = @_;

    #exists resource name:drbd1 role:Secondary suspended:no write-ordering:flush
    #exists connection name:drbd1 peer-node-id:0 conn-name:central-2004 connection:Connected role:Primary congested:no ap-in-flight:0 rs-in-flight:0
    #exists connection name:drbd1 peer-node-id:1 conn-name:poller-2004-1 connection:Connected role:Secondary congested:no ap-in-flight:0 rs-in-flight:0
    #exists device name:drbd1 volume:0 minor:1 disk:UpToDate client:no quorum:yes size:765868 read:0 written:765868 al-writes:0 bm-writes:0 upper-pending:0 lower-pending:0 al-suspended:no blocked:no
    #exists peer-device name:drbd1 peer-node-id:0 conn-name:central-2004 volume:0 replication:Established peer-disk:UpToDate peer-client:no resync-suspended:no received:765868 sent:0 out-of-sync:0 pending:0 unacked:0
    #exists peer-device name:drbd1 peer-node-id:1 conn-name:poller-2004-1 volume:0 replication:Established peer-disk:UpToDate peer-client:no resync-suspended:no received:0 sent:0 out-of-sync:0 pending:0 unacked:0
    #exists -

    $self->{resources} = {};
    foreach my $line (split /\n/, $options{stdout}) {
        next if ($line !~ /^exists\s+(?:resource|connection|device|peer-device)\s+name:(\S+)/);

        my $res_name = $1;
        if (defined($self->{option_results}->{filter_resource_name}) && $self->{option_results}->{filter_resource_name} ne '' &&
            $res_name !~ /$self->{option_results}->{filter_resource_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $res_name . "': no matching filter.", debug => 1);
            next;
        }

        if ($line =~ /^exists\s+resource\s+.*?role:(\S+)/) {
            $self->{resources}->{ $res_name } = {
                display => $res_name,
                role => { display => $res_name, role => $1 },
                device => { display => $res_name },
                peers => {}
            };
        } elsif ($line =~ /^exists\s+connection.*?conn-name:(\S+)\s+connection:(\S+)\s+role:(\S+)/) {
            $self->{resources}->{ $res_name }->{peers}->{ $1 } = { display => $1 }
                if (!defined($self->{resources}->{ $res_name }->{peers}->{ $1 }));
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{connection_status} = $2;
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{role} = $3;
        } elsif ($line =~ /^exists\s+device.*?disk:(\S+).*?read:(\d+)\s+written:(\d+)/) {
            $self->{resources}->{ $res_name }->{device}->{disk_status} = $1;
            $self->{resources}->{ $res_name }->{device}->{data_read} = $2 * 1024;
            $self->{resources}->{ $res_name }->{device}->{data_written} = $3 * 1024;
        } elsif ($line =~ /^exists\s+peer-device.*?conn-name:(\S+).*?replication:(\S+).*?peer-disk:(\S+).*?received:(\d+)\s+sent:(\d+)/) {
            $self->{resources}->{ $res_name }->{peers}->{ $1 } = { display => $1 }
                if (!defined($self->{resources}->{ $res_name }->{peers}->{ $1 }));
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{device_replication_status} = $2;
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{device_disk_status} = $3;
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{traffic_in} = $4 * 1024 * 8;
            $self->{resources}->{ $res_name }->{peers}->{ $1 }->{traffic_out} = $5 * 1024 * 8;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($command, $command_path, $command_options) = ('drbdsetup', '/usr/sbin', 'events2 --now --statistics all 2>&1');
    if (defined($self->{option_results}->{legacy_proc})) {
        ($command, $command_path, $command_options) = ('cat', undef, '/proc/drbd');
    }
    my ($stdout) = $options{custom}->execute_command(
        command => $command,
        command_path => $command_path,
        command_options => $command_options
    );

    if (defined($self->{option_results}->{legacy_proc})) {
        $self->legacy_proc(stdout => $stdout);
    } else {
        $self->drbdsetup_events2(stdout => $stdout);
    }

    $self->{global} = {
        resources_total => scalar(keys %{$self->{resources}})
    };

    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_resource_name}) ? md5_hex($self->{option_results}->{filter_resource_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check DRBD resources.

Command used: /usr/sbin/drbdsetup events2 --now --statistics all 2>&1

Legacy used: cat /proc/drbd

=over 8

=item B<--filter-resource-name>

Filter resource name (Can be a regexp).

=item B<--legacy-proc>

Use legacy proc file.

=item B<--unknown-*> B<--warning-*> B<--critical-*>

Available threshold options

=over 4

resources-total

data-read

data-written

peer-traffic-in

peer-traffic-out

role:

=over 4

[unknown] %{role} =~ /unknown/i

[critical] %{role} =~ /unconfigured/i

=back

disk-status:

=over 4

[unknown] %{disk_status} =~ /dunknown/i

[warning] %{disk_status} =~ /attaching|detaching|negotiating/i

[critical] %{disk_status} =~ /outdated|inconsistent|failed|diskless/i

=back

peer-role:

=over 4

[unknown] %{role} =~ /unknown/i

[critical] %{role} =~ /unconfigured/i

=back

peer-connection-status:

=over 4

[warning] %{connection_status} =~ /^(?:connecting|disconnecting|standalone|teardown)$/i

[critical] %{connection_status} =~ /^(?:brokenpipe|networkfailure|protocolerror|timeout|unconnected|wfconnection|wfreportparams)$/i

=back

peer-device-replication-status:

=over 4

[warning] %{device_replication_status} =~ /^(?:ahead|off|startingsyncs|startingsynct|syncsource|synctarget|verifys|verifyt|wfsyncuuid|syncingall|syncingquick)$/i

[critical] %{device_replication_status} =~ /^(?:behind|pausedsyncs|pausedsynct|wfbitmaps|wfbitmapt|syncpaused|skippedsyncs|skippedsynct)$/i 

=back

peer-device-disk-status:

=over 4

[unknown] %{device_disk_status} =~ /dunknown/i

[warning] %{device_disk_status} =~ /^(?:attaching|detaching|diskless|failed|inconsistent|negotiating|outdated)$/i

=back

=back

=back

=cut
