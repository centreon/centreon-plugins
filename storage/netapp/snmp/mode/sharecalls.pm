################################################################################
# Copyright 2005-2013 MERETHIS
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

package storage::netapp::snmp::mode::sharecalls;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    cifs   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'cifs', diff => 1 }, ],
                        per_second => 1,
                        output_template => 'CIFS : %s calls/s',
                        perfdatas => [
                            { value => 'cifs_per_second', template => '%d', min => 0 },
                        ],
                    }
               },
    nfs   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'nfs', diff => 1 }, ],
                        per_second => 1,
                        output_template => 'NFS : %s calls/s',
                        perfdatas => [
                            { value => 'nfs_per_second', template => '%d', min => 0 },
                        ],
                    }
               },
};

my $oid_miscHighNfsOps = '.1.3.6.1.4.1.789.1.2.2.5.0';
my $oid_miscLowNfsOps = '.1.3.6.1.4.1.789.1.2.2.6.0';
my $oid_miscHighCifsOps = '.1.3.6.1.4.1.789.1.2.2.7.0';
my $oid_miscLowCifsOps = '.1.3.6.1.4.1.789.1.2.2.8.0';
my $oid_misc64NfsOps = '.1.3.6.1.4.1.789.1.2.2.27.0';
my $oid_misc64CifsOps = '.1.3.6.1.4.1.789.1.2.2.28.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);  
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
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
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_netapp_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global},
                                                                 new_datas => $self->{new_datas});

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
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [$oid_miscHighNfsOps, $oid_miscLowNfsOps,
                   $oid_miscHighCifsOps, $oid_miscLowCifsOps];
    if (!$self->{snmp}->is_snmpv1()) {
        push @{$request}, ($oid_misc64NfsOps, $oid_misc64CifsOps);
    }
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{cifs} = defined($self->{results}->{$oid_misc64CifsOps}) ?
                                $self->{results}->{$oid_misc64CifsOps} : 
                                ($self->{results}->{$oid_miscHighCifsOps} << 32) + $self->{results}->{$oid_miscLowCifsOps};
    $self->{global}->{nfs} = defined($self->{results}->{$oid_misc64NfsOps}) ?
                                $self->{results}->{$oid_misc64NfsOps} : 
                                ($self->{results}->{$oid_miscHighNfsOps} << 32) + $self->{results}->{$oid_miscLowNfsOps};
}

1;

__END__

=head1 MODE

Check cifs and nfs calls per seconds.
If you are in cluster mode, the following mode doesn't work. Ask to netapp to add it :)

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'cifs', 'nfs'.

=item B<--critical-*>

Threshold critical.
Can be: 'cifs', 'nfs'.

=back

=cut
    