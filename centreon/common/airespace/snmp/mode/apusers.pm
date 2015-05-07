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

package centreon::common::airespace::snmp::mode::apusers;

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
    '001_idle'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [ { name => 'idle' } ],
                        output_template => 'Total Idle Users : %s',
                        perfdatas => [
                            { label => 'total_idle', value => 'idle_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
     '002_aaapending'  => { set => {
                        key_values => [ { name => 'aaapending' } ],
                        output_template => 'Total AaaPending Users : %s',
                        perfdatas => [
                            { label => 'total_aaapending', value => 'aaapending_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '003_authenticated'   => { set => {
                        key_values => [ { name => 'authenticated' } ],
                        output_template => 'Total Authenticated Users : %s',
                        perfdatas => [
                            { label => 'total_authenticated', value => 'authenticated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '004_associated'   => { set => {
                        key_values => [ { name => 'associated' } ],
                        output_template => 'Total Associated Users : %s',
                        perfdatas => [
                            { label => 'total_associated', value => 'associated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '005_powersave'   => { set => {
                        key_values => [ { name => 'idle' } ],
                        output_template => 'Total Powersave Users : %s',
                        perfdatas => [
                            { label => 'total_powersave', value => 'powersave_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '006_disassociated'   => { set => {
                        key_values => [ { name => 'disassociated' } ],
                        output_template => 'Total Disassociated Users : %s',
                        perfdatas => [
                            { label => 'total_disassociated', value => 'disassociated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '007_tobedeleted'   => { set => {
                        key_values => [ { name => 'tobedeleted' } ],
                        output_template => 'Total ToBeDeleted Users : %s',
                        perfdatas => [
                            { label => 'total_tobedeleted', value => 'tobedeleted_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '008_probing'   => { set => {
                        key_values => [ { name => 'probing' } ],
                        output_template => 'Total Probing Users : %s',
                        perfdatas => [
                            { label => 'total_probing', value => 'probing_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '009_blacklisted'   => { set => {
                        key_values => [ { name => 'blacklisted' } ],
                        output_template => 'Total Blacklisted Users : %s',
                        perfdatas => [
                            { label => 'total_blacklisted', value => 'blacklisted_absolute', template => '%s', 
                              unit => 'users', min => 0 },
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
                                  "filter-ssid:s"     => { name => 'filter_ssid' },
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

my %map_station_status = (
    0 => 'idle',
    1 => 'aaapending',
    2 => 'authenticated',
    3 => 'associated',
    4 => 'powersave',
    5 => 'disassociated',
    6 => 'tobedeleted',
    7 => 'probing',
    8 => 'blacklisted',
);
my $mapping = {
    bsnMobileStationStatus  => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.9', map => \%map_station_status },
};
my $mapping2 = {
    bsnMobileStationSsid    => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0 };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $mapping->{bsnMobileStationStatus}->{oid} },
                                                                   { oid => $mapping2->{bsnMobileStationSsid}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }}) {
        $oid =~ /^$mapping->{bsnMobileStationStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping->{bsnMobileStationSsid}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result2->{bsnMobileStationSsid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result2->{bsnMobileStationSsid} . "': no matching filter.");
            next;
        }
        $self->{global}->{total}++;
        $self->{global}->{$result->{bsnMobileStationStatus}} = 0 if (!defined($self->{global}->{$result->{bsnMobileStationStatus}}));
        $self->{global}->{$result->{bsnMobileStationStatus}}++;
    }
}

1;

__END__

=head1 MODE

Check total users connected and status on AP.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted'.

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=back

=cut
