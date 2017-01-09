#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package centreon::common::aruba::snmp::mode::apconnections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    ap => { 
        '000_total-time'   => { set => {
                        key_values => [ { name => 'apTotalTime' }, { name => 'bssid' }, ],
                        output_template => 'Current total connection time : %.3f s',
                        perfdatas => [
                            { label => 'total_time', value => 'apTotalTime_absolute', template => '%.3f',
                              min => 0, unit => 's', label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        '001_inactive-time'   => { set => {
                        key_values => [ { name => 'apInactiveTime' }, { name => 'bssid' }, ],
                        output_template => 'Current inactive time : %.3f s',
                        perfdatas => [
                            { label => 'inactive_time', value => 'apInactiveTime_absolute', template => '%.3f',
                              min => 0, unit => 's', label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        '002_channel-noise'   => { set => {
                        key_values => [ { name => 'apChannelNoise' }, { name => 'bssid' }, ],
                        output_template => 'Channel noise : %d',
                        perfdatas => [
                            { label => 'channel_noise', value => 'apChannelNoise_absolute', template => '%d',
                              label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        '003_snr'   => { set => {
                        key_values => [ { name => 'apSignalToNoiseRatio' }, { name => 'bssid' }, ],
                        output_template => 'Signal to noise ratio : %d',
                        perfdatas => [
                            { label => 'snr', value => 'apSignalToNoiseRatio_absolute', template => '%d',
                              label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        },
    total => {
        '000_total'   => { set => {
                        key_values => [ { name => 'total' } ],
                        output_template => 'AP connected : %d',
                        perfdatas => [
                            { label => 'total', value => 'total_absolute', template => '%d', min => 0 },
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
                                  "filter-ip-address:s"  => { name => 'filter_ip_address' },
                                  "filter-bssid:s"  => { name => 'filter_bssid' },
                                  "filter-essid:s"  => { name => 'filter_essid' },
                                  "filter-type:s"   => { name => 'filter_type', default => 'ap' },
                                  "skip-total"      => { name => 'skip_total' },
                                });                         

    foreach my $key (('ap', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('ap', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }    
}

sub check_total {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits = ();
    foreach (sort keys %{$maps_counters->{total}}) {
        my $obj = $maps_counters->{total}->{$_}->{obj};
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
                                    short_msg => "Total $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Total $long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{ap}}) == 1) {
        $multiple = 0;
    }

    if (!defined($self->{option_results}->{skip_total})) {
        $self->check_total();
    }
    
    ####
    # By AP
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All AP are ok');
    }
    
    foreach my $id (sort keys %{$self->{ap}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{ap}}) {
            my $obj = $maps_counters->{ap}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{ap}->{$id});

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
            
            $maps_counters->{ap}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "AP [bssid: '$self->{ap}->{$id}->{bssid}', essid: $self->{ap}->{$id}->{apESSID}, ip: $self->{ap}->{$id}->{apIpAddress}] Usage $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "AP [bssid: '$self->{ap}->{$id}->{bssid}', essid: $self->{ap}->{$id}->{apESSID}, ip: $self->{ap}->{$id}->{apIpAddress}] Usage $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "AP [bssid: '$self->{ap}->{$id}->{bssid}', [essid: $self->{ap}->{$id}->{apESSID}, ip: $self->{ap}->{$id}->{apIpAddress}] Usage $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_role = (
    1 => 'master',
    2 => 'local',
    3 => 'standbymaster',
);
my %map_type = (
    1 => 'ap',
    2 => 'am',
);

my $mapping = {
    apESSID => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.2' },  
};
my $mapping2 = {
    apIpAddress => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.5' },
};
my $mapping3 = {
    apType => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.7', map => \%map_type },
};
my $mapping4 = {
    apTotalTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.10' },
    apInactiveTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.11' },
};
my $mapping5 = {
    apChannelNoise => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.13' },
    apSignalToNoiseRatio => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.14' },
};
    
my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';
my $oid_wlsxSwitchAccessPointTable = '.1.3.6.1.4.1.14823.2.2.1.1.3.3';
my $oid_wlsxSwitchAccessPointEntry = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1';
my $oid_wlsxSwitchTotalNumAccessPoints = '.1.3.6.1.4.1.14823.2.2.1.1.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_wlsxSwitchTotalNumAccessPoints },
                                                            { oid => $oid_wlsxSwitchRole },
                                                            { oid => $mapping->{apESSID}->{oid} },
                                                            { oid => $mapping2->{apIpAddress}->{oid} },
                                                            { oid => $mapping3->{apType}->{oid} },
                                                            { oid => $oid_wlsxSwitchAccessPointEntry, start => $mapping4->{apTotalTime}->{oid}, end => $mapping4->{apInactiveTime}->{oid} },
                                                            { oid => $oid_wlsxSwitchAccessPointTable, start => $mapping5->{apChannelNoise}->{oid}, end => $mapping5->{apSignalToNoiseRatio}->{oid} },
                                                         ],
                                                         , nothing_quit => 1);
    my $role = $map_role{$self->{results}->{$oid_wlsxSwitchRole}->{$oid_wlsxSwitchRole . '.0'}};
    if ($role =~ /standbymaster/) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Cannot get information. Switch role is '" . $role . "'.");
        $self->{output}->display();
        $self->{output}->exit();
    }    
    
    $self->{ap} = {};
    foreach my $oid (keys %{$self->{results}->{$mapping->{apESSID}->{oid}}}) {
        next if ($oid !~ /^$mapping->{apESSID}->{oid}\.(.*)$/);
        my $bssid = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{apESSID}->{oid}}, instance => $bssid);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{apIpAddress}->{oid}}, instance => $bssid);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{apType}->{oid}}, instance => $bssid);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$oid_wlsxSwitchAccessPointEntry}, instance => $bssid);
        my $result5 = $self->{snmp}->map_instance(mapping => $mapping5, results => $self->{results}->{$oid_wlsxSwitchAccessPointTable}, instance => $bssid);
        
        if (defined($self->{option_results}->{filter_bssid}) && $self->{option_results}->{filter_bssid} ne '' &&
            $bssid !~ /$self->{option_results}->{filter_bssid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $bssid . "': no matching filter bssid.");
            next;
        }
        if (defined($self->{option_results}->{filter_ip_address}) && $self->{option_results}->{filter_ip_address} ne '' &&
            $result2->{apIpAddress} !~ /$self->{option_results}->{filter_ip_address}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result2->{apIpAddress} . "': no matching filter ip-address.");
            next;
        }
        if (defined($self->{option_results}->{filter_essid}) && $self->{option_results}->{filter_essid} ne '' &&
            $result->{apESSID} !~ /$self->{option_results}->{filter_essid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{apESSID} . "': no matching filter essid.");
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result3->{apType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{apType} . "': no matching filter type.");
            next;
        }
        
        $self->{ap}->{$bssid} = { bssid => $bssid, %$result2, %$result, %$result4, %$result5};
        $self->{ap}->{$bssid}->{apInactiveTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apInactiveTime}));
        $self->{ap}->{$bssid}->{apTotalTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apTotalTime}));
    }
    
    if (defined($self->{results}->{$oid_wlsxSwitchTotalNumAccessPoints}->{$oid_wlsxSwitchTotalNumAccessPoints . '.0'})) {
        $self->{global} = { total => $self->{results}->{$oid_wlsxSwitchTotalNumAccessPoints}->{$oid_wlsxSwitchTotalNumAccessPoints . '.0'} };
    }
}

1;

__END__

=head1 MODE

Check AP connections.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-time', 'inactive-time', 'channel-noise', 'snr'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-time', 'inactive-time', 'channel-noise', 'snr'.

=item B<--filter-bssid>

Filter by physical address (regexp can be used).

=item B<--filter-ip-address>

Filter by ip address (regexp can be used).

=item B<--filter-essid>

Filter by ESSID (regexp can be used).

=item B<--filter-type>

Filter by type (regexp can be used. Can be: 'ap' or 'am'. Default: 'ap').

=item B<--skip-total>

Don't display total AP connected (useful when you check each AP).

=back

=cut
