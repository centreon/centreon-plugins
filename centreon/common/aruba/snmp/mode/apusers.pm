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

package centreon::common::aruba::snmp::mode::apusers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {               
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
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });

    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                                     label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }    
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_auth_method = (
    1 => 'none',
    2 => 'other',
    3 => 'web',
    4 => 'dot1x',
    5 => 'vpn',
    6 => 'mac',
);
my %map_role = (
    1 => 'master',
    2 => 'local',
    3 => 'standbymaster',
);
my $mapping = {
    userUpTime                => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.2.1.1.5' },
    userAuthenticationMethod  => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.2.1.1.6', map => \%map_auth_method },
};

my $oid_wlsxSwitchUserEntry = '.1.3.6.1.4.1.14823.2.2.1.1.2.1.1';
my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0, total_none => 0, total_other => 0, total_web => 0,
                        total_dot1x => 0, total_vpn => 0, total_mac => 0};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                                                   { oid => $oid_wlsxSwitchRole },
                                                                   { oid => $oid_wlsxSwitchUserEntry, start => $mapping->{userUpTime}->{oid}, end => $mapping->{userAuthenticationMethod}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    
    my $role = $map_role{$self->{results}->{$oid_wlsxSwitchRole}->{$oid_wlsxSwitchRole . '.0'}};
    if ($role =~ /standbymaster/) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Cannot get information. Switch role is '" . $role . "'.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $total_timeticks = 0;
    foreach my $oid (keys %{$self->{results}->{$oid_wlsxSwitchUserEntry}}) {
        $oid =~ /^$mapping->{userAuthenticationMethod}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_wlsxSwitchUserEntry}, instance => $instance);

        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{userAuthenticationMethod}}++;
        $total_timeticks += $result->{userUpTime};
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

=back

=cut
