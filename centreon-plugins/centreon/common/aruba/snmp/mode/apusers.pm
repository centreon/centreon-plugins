#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::aruba::snmp::mode::apusers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    global => {
        '000_total'   => { set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Users : %s',
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '001_total-none'   => { set => {
                key_values => [ { name => 'total_none' } ],
                output_template => 'Total Auth None : %s',
                perfdatas => [
                    { label => 'total_none', value => 'total_none_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '002_total-other'  => { set => {
                key_values => [ { name => 'total_other' } ],
                output_template => 'Total Auth Other : %s',
                perfdatas => [
                    { label => 'total_other', value => 'total_other_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '003_total-web'   => { set => {
                key_values => [ { name => 'total_web' } ],
                output_template => 'Total Auth Web : %s',
                perfdatas => [
                    { label => 'total_web', value => 'total_web_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '004_total-dot1x'   => { set => {
                key_values => [ { name => 'total_dot1x' } ],
                output_template => 'Total Auth Dot1x : %s',
                perfdatas => [
                    { label => 'total_dot1x', value => 'total_dot1x_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '005_total-vpn'   => { set => {
                key_values => [ { name => 'total_vpn' } ],
                output_template => 'Total Auth Vpn : %s',
                perfdatas => [
                    { label => 'total_vpn', value => 'total_vpn_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '006_total-mac'   => { set => {
                key_values => [ { name => 'total_mac' } ],
                output_template => 'Total Auth Mac : %s',
                perfdatas => [
                    { label => 'total_mac', value => 'total_mac_absolute', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        '007_avg-connection-time'   => { set => {
                key_values => [ { name => 'avg_connection_time' } ],
                output_template => 'Users average connection time : %.3f seconds',
                perfdatas => [
                    { label => 'avg_connection_time', value => 'avg_connection_time_absolute', template => '%.3f', 
                      unit => 's', min => 0 },
                ],
            }
        },
    },
    total_ap => {
        '000_total-ap'   => { set => {
                key_values => [ { name => 'users' }, { name => 'bssid' } ],
                output_template => 'Users : %s',
                perfdatas => [
                    { label => 'total', value => 'users_absolute', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'bssid_absolute' },
                ],
            }
        },
    },
    total_essid => {
        '000_total-essid'   => { set => {
                key_values => [ { name => 'users' }, { name => 'essid' } ],
                output_template => 'Users : %s',
                perfdatas => [
                    { label => 'total', value => 'users_absolute', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'essid_absolute' },
                ],
            }
        },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-ip-address:s"   => { name => 'filter_ip_address' },
                                "filter-essid:s"       => { name => 'filter_essid' },
                                });

    foreach my $key (('global', 'total_ap', 'total_essid')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output},
                                                      perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('global', 'total_ap', 'total_essid')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
}

sub run_total {
    my ($self, %options) = @_;

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
}

sub run_ap {
    my ($self, %options) = @_;
    
    my $multiple = 1;
    if (scalar(keys %{$self->{ap_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All users by AP are ok');
    }
    
    foreach my $id (sort keys %{$self->{ap_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{total_ap}}) {
            my $obj = $maps_counters->{total_ap}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{ap_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "AP '$id' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "AP '$id' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "AP '$id' $long_msg");
        }
    }
}

sub run_essid {
    my ($self, %options) = @_;
    
    my $multiple = 1;
    if (scalar(keys %{$self->{essid_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All users by ESSID are ok');
    }
    
    foreach my $id (sort keys %{$self->{essid_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{total_essid}}) {
            my $obj = $maps_counters->{total_essid}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{essid_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "ESSID '$id' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "ESSID '$id' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "ESSID '$id' $long_msg");
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    $self->run_total();
    $self->run_ap();
    $self->run_essid();
     
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_auth_method = (
    0 => 'none', 1 => 'web',
    2 => 'mac', 3 => 'vpn',
    4 => 'dot1x', 5 => 'kerberos',
    7 => 'secureId',
    15 => 'pubcookie', 16 => 'xSec',
    17 => 'xSecMachine',
    28 => 'via-vpn',
    255 => 'other',
);
my %map_role = (
    1 => 'master',
    2 => 'local',
    3 => 'standbymaster',
);
my $mapping = {
    nUserUpTime                => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.5' },
    nUserAuthenticationMethod  => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.6', map => \%map_auth_method },
};
my $mapping2 = {
    nUserApBSSID               => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.11' },
};

my $oid_wlsxUserEntry = '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1';
my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';
my $oid_apESSID = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.2';
my $oid_apIpAddress = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.5';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0, total_none => 0, total_web => 0, total_mac => 0, total_vpn => 0,
                        total_dot1x => 0, total_kerberos => 0, total_secureId => 0, total_pubcookie => 0,
                        total_xSec => 0, xSecMachine => 0, 'total_via-vpn' => 0, total_other => 0 };
    $self->{ap_selected} = {};
    $self->{essid_selected} = {};

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                                                   { oid => $oid_wlsxSwitchRole },
                                                                   { oid => $oid_wlsxUserEntry, start => $mapping->{nUserUpTime}->{oid}, end => $mapping->{nUserAuthenticationMethod}->{oid} },
                                                                   { oid => $mapping2->{nUserApBSSID}->{oid} },
                                                                   { oid => $oid_apESSID },
                                                                   { oid => $oid_apIpAddress },
                                                                 ],
                                                         nothing_quit => 1);
    
    my $role = $map_role{$self->{results}->{$oid_wlsxSwitchRole}->{$oid_wlsxSwitchRole . '.0'}};
    if ($role =~ /standbymaster/) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Cannot get information. Switch role is '" . $role . "'.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my %map_ap = ();
    foreach my $oid (keys %{$self->{results}->{$oid_apESSID}}) {
        $oid =~ /^$oid_apESSID\.(.*)$/;
        $map_ap{$1} = { essid => $self->{results}->{$oid_apESSID}->{$oid}, ip => $self->{results}->{$oid_apIpAddress}->{$oid_apIpAddress . '.' .  $1} };
    }
    
    my $total_timeticks = 0;
    foreach my $oid (keys %{$self->{results}->{$oid_wlsxUserEntry}}) {
        next if ($oid !~ /^$mapping->{nUserAuthenticationMethod}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_wlsxUserEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{nUserApBSSID}->{oid}}, instance => $instance);
        
        # security
        next if (!defined($result2->{nUserApBSSID}));
        my $bssid = join('.', unpack('C*', $result2->{nUserApBSSID}));
        next if (defined($self->{option_results}->{filter_ip_address}) && $self->{option_results}->{filter_ip_address} ne '' &&
            $map_ap{$bssid}->{ip} !~ /$self->{option_results}->{filter_ip_address}/);
        next if (defined($self->{option_results}->{filter_ip_address}) && $self->{option_results}->{filter_ip_address} ne '' &&
            $map_ap{$bssid}->{essid} !~ /$self->{option_results}->{filter_essid}/);
    
        $self->{ap_selected}->{$bssid} = { users => 0, bssid => $bssid } if (!defined($self->{ap_selected}->{$bssid}));
        $self->{ap_selected}->{$bssid}->{users}++;
    
        $self->{essid_selected}->{$map_ap{$bssid}->{essid}} = { users => 0, essid => $map_ap{$bssid}->{essid} } if (!defined($self->{essid_selected}->{$map_ap{$bssid}->{essid}}));
        $self->{essid_selected}->{$map_ap{$bssid}->{essid}}->{users}++;

        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{nUserAuthenticationMethod}}++;
        $total_timeticks += $result->{nUserUpTime};
    }
    
    if ($self->{global}->{total} > 0) {
        $self->{global}->{avg_connection_time} = $total_timeticks / $self->{global}->{total} * 0.01;
    }
}

1;

__END__

=head1 MODE

Check total users connected.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-none', 'total-other', 'total-web',
'total-dot1x', 'total-vpn', 'total-mac', 'avg-connection-time' (seconds).

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-none', 'total-other', 'total-web',
'total-dot1x', 'total-vpn', 'total-mac', 'avg-connection-time' (seconds).

=item B<--filter-ip-address>

Filter by ip address (regexp can be used).

=item B<--filter-essid>

Filter by ESSID (regexp can be used).

=back

=cut
