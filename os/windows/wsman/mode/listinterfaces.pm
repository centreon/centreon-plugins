#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package os::windows::wsman::mode::listinterfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use snmp_standard::mode::resources::types qw($map_iftype);

#my $oid_speed32 = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
#my $oid_speed64 = '.1.3.6.1.2.1.31.1.1.1.15';
#
sub set_status {
    my ($self, %options) = @_;
#
    $self->{adminstatus_mapping} = {
        'true' => 'up', '' => 'down'
    };
    $self->{opstatus_mapping} = {
        0  => 'down', 
        1  => 'connecting', 
        2  => 'up', 
        3  => 'disconnecting', 
        4  => 'hardwareNotPresent', 
        5  => 'hardwareDisable', 
        6  => 'hardwarMalfunction', 
        7  => 'mediaDisconnect', 
        8  => 'auth', 
        9  => 'authSucceeded', 
        10 => 'ÁuthFailed', 
        11 => 'invalidAddress', 
        12 => 'credentialsRequired'
    };
}

sub is_admin_status_down {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{use_adminstatus}) && defined($options{admin_status}) && 
        $self->{adminstatus_mapping}->{$options{admin_status}} ne 'up') {
        return 1;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;

    $self->{no_speed} = defined($options{no_speed}) && $options{no_speed} =~ /^[01]$/ ? $options{no_speed} : 0;
    $options{options}->add_options(arguments => { 
        'name'                    => { name => 'use_name' },
        'interface:s'             => { name => 'interface' },
        'speed:s'                 => { name => 'speed' },
        'filter-status:s'         => { name => 'filter_status' },
        'skip-speed0'             => { name => 'skip_speed0' },
        'use-adminstatus'         => { name => 'use_adminstatus' },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
    });

    $self->{interface_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->set_status();
}

sub run {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};

    my $WQL = $self->manage_selection();
    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'hash',
        hash_key => 'DeviceID'
    );

    #
    #CLASS: Win32_NetworkAdapter
    #DeviceID;MaxSpeed;Name;NetConnectionStatus;NetEnabled
    #0;0;Microsoft Kernel Debug Network Adapter;0;False
    #1;0;Amazon Elastic Network Adapter;0;False
    #2;0;AWS PV Network Device #0;2;True
    #3;0;WAN Miniport (SSTP);0;False
    #4;0;WAN Miniport (IKEv2);0;False
    #

    if ((!defined($self->{result}) || $self->{result} eq '') && !defined($options{disco})) {
            $self->{output}->add_option_msg(short_msg => 'No entry found');
            $self->{output}->option_exit();
    }
    foreach my $device_id (sort(keys %{$self->{result}})) {
        my $id = $self->{result}->{$device_id}->{DeviceID};
        my $speed = (!defined($self->{result}->{$device_id}->{MaxSpeed}) || $self->{result}->{$device_id}->{MaxSpeed} eq '') ? '0' : $self->{result}->{$device_id}->{MaxSpeed};
        my $name = $self->{result}->{$device_id}->{Name}; 
        my $opstatus = (!defined($self->{result}->{$device_id}->{NetConnectionStatus}) || $self->{result}->{$device_id}->{NetConnectionStatus} eq '') ? '0' : $self->{result}->{$device_id}->{NetConnectionStatus};
        my $adminstatus = $self->{result}->{$device_id}->{NetEnabled};
        my $display_value = $self->get_display_value(name => $name);

        my $interface_speed = 0;
        if ($self->{no_speed} == 0) {
            $interface_speed = (defined($speed) && $speed ne '') ? '0' : $speed;
        }
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }

        if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': interface speed is 0 and option --skip-speed0 is set");
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && defined($opstatus) && 
            $self->{opstatus_mapping}->{$opstatus} !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': no matching filter status");
            next;
        }
        if ($self->is_admin_status_down(admin_status => $adminstatus)) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': adminstatus is not 'up' and option --use-adminstatus is set");
            next;
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "'%s' [speed = %s][status = %s][id = %s]",
                $display_value,
                $interface_speed,
                (defined($opstatus) ?  $self->{opstatus_mapping}->{$opstatus} : ''),
                $id
            )
        );
   }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_display_value {
    my ($self, %options) = @_;

    my $value = $options{name};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $WQL = 'select DeviceID, MaxSpeed ,Name, NetConnectionStatus, NetEnabled from Win32_NetworkAdapter';

    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        $WQL .= ' where DeviceID="' . $self->{option_results}->{interface} .'"';
    } elsif (defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        $WQL .= '  where Name like "%' . $self->{option_results}->{interface} . '%"';
    }

    return $WQL;
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'total', 'status', 'interfaceid'];
    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        push @$names, keys %{$self->{extra_oids}};
    }
    if (defined($self->{option_results}->{add_mac_address})) {
        push @$names, 'macaddress';
    }
    push @$names, 'type' if (defined($self->{oid_iftype}));

    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};

    my $WQL = $self->manage_selection();
    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'hash',
        hash_key => 'DeviceID'
    );

    foreach my $device_id (sort(keys %{$self->{result}})) {
        my $id = $self->{result}->{$device_id}->{DeviceID};
        my $speed = (!defined($self->{result}->{$device_id}->{MaxSpeed}) || $self->{result}->{$device_id}->{MaxSpeed} eq '') ? '0' : $self->{result}->{$device_id}->{MaxSpeed};
        my $name = $self->{result}->{$device_id}->{Name};
        my $opstatus = (!defined($self->{result}->{$device_id}->{NetConnectionStatus}) || $self->{result}->{$device_id}->{NetConnectionStatus} eq '') ? '0' : $self->{result}->{$device_id}->{NetConnectionStatus};
        my $adminstatus = $self->{result}->{$device_id}->{NetEnabled};
        my $display_value = $self->get_display_value(name => $name);

        my $interface_speed = 0;
        if ($self->{no_speed} == 0) {
            $interface_speed = (defined($speed) && $speed ne '' && $speed == 0) ? '0' : $speed;
        }
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }

        if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': interface speed is 0 and option --skip-speed0 is set");
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && defined($opstatus) &&
            $self->{opstatus_mapping}->{$opstatus} !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': no matching filter status");
            next;
        }
        if ($self->is_admin_status_down(admin_status => $adminstatus)) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': adminstatus is not 'up' and option --use-adminstatus is set");
            next;
        }
        $self->{output}->add_disco_entry(
            name => $display_value,
            total => $interface_speed,
            status => defined($opstatus) ? $self->{opstatus_mapping}->{$opstatus} : '',
            interfaceid => $id
            );
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-status>

Display interfaces matching the filter (example: 'up').

=item B<--use-adminstatus>

Display interfaces with AdminStatus 'up'.

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=back

=cut
