################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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
                            { label => 'cpu_30secs', value => 'apChannelNoise_absolute', template => '%d',
                              label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        '003_nsr'   => { set => {
                        key_values => [ { name => 'apSignalToNoiseRatio' }, { name => 'bssid' }, ],
                        output_template => 'Signal to noise ratio : %d',
                        perfdatas => [
                            { label => 'cpu_1min', value => 'apSignalToNoiseRatio_absolute', template => '%d',
                              label_extra_instance => 1, instance_use => 'bssid_absolute' },
                        ],
                    }
               },
        },
    total => {
        '000_total'   => { set => {
                        key_values => [ { name => 'total' } ],
                        output_template => 'AP connected : %d %%',
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
    # $options{snmp} = snmp object
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

        $self->{output}->output_add(long_msg => "BSSID '" . $self->{ap}->{$id}->{bssid} . "' Usage $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "BSSID '" . $self->{ap}->{$id}->{bssid} . "' Usage $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "BSSID '" . $self->{ap}->{$id}->{bssid} . "' Usage $long_msg");
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
    apType  => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.7', map => \%map_type },
    apTotalTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.10' },
    apInactiveTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.11' },
    apChannelNoise => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.13' },
    apSignalToNoiseRatio => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.14' },
};

my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';
my $oid_wlsxSwitchAccessPointEntry = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_extremeCpuMonitorSystemEntry = '.1.3.6.1.4.1.1916.1.32.1.4.1';
    my $oid_extremeCpuMonitorTotalUtilization = '.1.3.6.1.4.1.1916.1.32.1.2'; # without .0
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_wlsxSwitchRole },
                                                            { oid => $oid_wlsxSwitchAccessPointEntry },
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
    $self->{global} = { total => 0 };
    foreach my $oid (keys %{$self->{results}->{$oid_wlsxSwitchAccessPointEntry}}) {
        next if ($oid !~ /^$mapping->{apESSID}->{oid}\.(.*)$/);
        my $bssid = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_wlsxSwitchAccessPointEntry}, instance => $bssid);
        
        if (defined($self->{option_results}->{filter_bssid}) && $self->{option_results}->{filter_bssid} ne '' &&
            $bssid !~ /$self->{option_results}->{filter_bssid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $bssid . "': no matching filter bssid.");
            next;
        }
        if (defined($self->{option_results}->{filter_essid}) && $self->{option_results}->{filter_essid} ne '' &&
            $result->{apESSID} !~ /$self->{option_results}->{filter_essid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{apESSID} . "': no matching filter essid.");
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{apType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{apType} . "': no matching filter type.");
            next;
        }
        
        $self->{ap}->{$bssid} = {bssid => $bssid, %$result};
        $self->{ap}->{$bssid}->{apInactiveTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apInactiveTime}));
        $self->{ap}->{$bssid}->{apTotalTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apTotalTime}));
        
        $self->{global}->{total} += 1;
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

=item B<--filter-essid>

Filter by ESSID (regexp can be used).

=item B<--filter-type>

Filter by type (regexp can be used. Can be: 'ap' or 'am'. Default: 'ap').

=item B<--skip-total>

Don't display total AP connected (useful when you check each AP).

=back

=cut
