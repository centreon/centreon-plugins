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

package snmp_standard::mode::diskio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::values;

my $maps_counters = {
    read   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'read', diff => 1 }, { name => 'display' },
                                      ],
                        per_second => 1,
                        output_template => 'Read I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'read_per_second', template => '%d',
                              unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    write   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'write', diff => 1 }, { name => 'display' },
                                      ],
                        per_second => 1,
                        output_template => 'Write I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'write_per_second', template => '%d',
                              unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    'read-iops'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'read_iops', diff => 1 }, { name => 'display' },
                                      ],
                        per_second => 1,
                        output_template => 'Read IOPs : %.2f',
                        perfdatas => [
                            { value => 'read_iops_per_second',  template => '%.2f',
                              unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    'write-iops'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'write_iops', diff => 1 }, { name => 'display' },
                                      ],
                        per_second => 1,
                        output_template => 'Write IOPs : %.2f',
                        perfdatas => [
                            { value => 'write_iops_per_second', template => '%.2f',
                              unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
};

my $oid_diskIODevice = '.1.3.6.1.4.1.2021.13.15.1.1.2';
my $oid_diskIOReads = '.1.3.6.1.4.1.2021.13.15.1.1.5';
my $oid_diskIOWrites = '.1.3.6.1.4.1.2021.13.15.1.1.6';
my $oid_diskIONReadX = '.1.3.6.1.4.1.2021.13.15.1.1.12'; # in B
my $oid_diskIONWrittenX = '.1.3.6.1.4.1.2021.13.15.1.1.13'; # in B

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name"                    => { name => 'use_name' },
                                  "device:s"                => { name => 'device' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },                                  
                                });

    $self->{device_id_selected} = {};
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
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{device_id_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All devices are ok.');
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{device}) ? md5_hex($self->{option_results}->{device}) : md5_hex('all')));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{device_id_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{device_id_selected}->{$id},
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
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Device '" . $self->{device_id_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Device '" . $self->{device_id_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Device '" . $self->{device_id_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub add_result {
    my ($self, %options) = @_;
    
    $self->{device_id_selected}->{$options{instance}} = {};
    $self->{device_id_selected}->{$options{instance}}->{display} = $self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $options{instance}};    
    $self->{device_id_selected}->{$options{instance}}->{read} = (defined($self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}}) && $self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}} != 0) ?
        $self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}} : 0;
    $self->{device_id_selected}->{$options{instance}}->{write} = (defined($self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}}) && $self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}} != 0) ? 
        $self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}} : undef;
    $self->{device_id_selected}->{$options{instance}}->{read_iops} = $self->{results}->{$oid_diskIOReads}->{$oid_diskIOReads . '.' . $options{instance}};
    $self->{device_id_selected}->{$options{instance}}->{write_iops} = $self->{results}->{$oid_diskIOWrites}->{$oid_diskIOWrites . '.' . $options{instance}};
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_diskIODevice },
                                                            { oid => $oid_diskIOReads },
                                                            { oid => $oid_diskIOWrites },
                                                            { oid => $oid_diskIONReadX },
                                                            { oid => $oid_diskIONWrittenX },
                                                         ],
                                                         , nothing_quit => 1);
 
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{device})) {
        if (!defined($self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $self->{option_results}->{device}})) {
            $self->{output}->add_option_msg(short_msg => "No device found for id '" . $self->{option_results}->{device} . "'.");
            $self->{output}->option_exit();
        }
        $self->add_result(instance => $self->{option_results}->{device});
    } else {
        foreach my $oid (keys %{$self->{results}->{$oid_diskIODevice}}) {
            $oid =~ /\.(\d+)$/;
            my $instance = $1;
            my $filter_name = $self->{results}->{$oid_diskIODevice}->{$oid}; 
            if (!defined($self->{option_results}->{device})) {
                $self->add_result(instance => $instance);
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{device}/i) {
                $self->add_result(instance => $instance);
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{device}/) {
                $self->add_result(instance => $instance);
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{device}) {
                $self->add_result(instance => $instance);
            }
        }    
    }
    
    if (scalar(keys %{$self->{device_id_selected}}) <= 0 && !defined($options{disco})) {
        if (defined($self->{option_results}->{device})) {
            $self->{output}->add_option_msg(short_msg => "No device found '" . $self->{option_results}->{device} . "' (or counter values are 0).");
        } else {
            $self->{output}->add_option_msg(short_msg => "No device found (or values are 0).");
        }
        $self->{output}->option_exit();
    }    
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'deviceid']);
}

sub disco_show {
    my ($self, %options) = @_;

    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->manage_selection(disco => 1);
    foreach (sort keys %{$self->{device_id_selected}}) {
        $self->{output}->add_disco_entry(name => $self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $_},
                                         deviceid => $_);
    }
}


1;

__END__

=head1 MODE

Check read/write I/O disks (bytes per secondes, IOPs). 

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', 'read-iops', 'write-iops'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', 'read-iops', 'write-iops'.

=item B<--device>

Set the device (number expected) ex: 1, 2,... (empty means 'check all devices').

=item B<--name>

Allows to use device name with option --device instead of devoce oid index.

=item B<--regexp>

Allows to use regexp to filter devices (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
