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

package storage::hp::p2000::xmlapi::mode::volumesstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    read   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [
                                        { name => 'data-read-numeric', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Read I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'data-read-numeric_absolute', 
                              unit => 'B/s', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    write   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'data-written-numeric', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Write I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'data-written-numeric_absolute', 
                              unit => 'B/s', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    iops   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'iops' },
                                      ],
                        output_template => 'IOPs : %s',
                        perfdatas => [
                            { value => 'iops_absolute', 
                              unit => 'iops', min => 0, label_extra_instance => 1 },
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
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{volume_name_selected} = [];
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
    }
 

    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{p2000}->get_infos(cmd => 'show volume-statistics', 
                                                 base_type => 'volume-statistics',
                                                 key => 'volume-name',
                                                 properties_name => '^data-read-numeric|data-written-numeric|write-cache-hits|write-cache-misses|read-cache-hits|read-cache-misses|iops$');
    foreach my $name (keys %{$self->{results}}) {
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{volume_name_selected}}, $name; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name}) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }        
    }

    if (scalar(@{$self->{volume_name_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{p2000} = $options{custom};
    
    $self->{p2000}->login(); 
    $self->manage_selection();
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All volumes statistics are ok.');
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_hp_p2000_" . $self->{p2000}->{hostname}  . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $name (sort @{$self->{volume_name_selected}}) {     
        my ($short_msg, $long_msg) = ('', '');
        my @exits;
        foreach (keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $name, 
                                           %{$maps_counters->{$_}->{set}},
                                           );
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{results}->{$name},
                                                                     new_datas => $self->{new_datas});

            next if (!defined($value_check));
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= ' ' . $output;
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= ' ' . $output;
            }
            
            $maps_counters->{$_}->{obj}->perfdata();
        }

        $self->{output}->output_add(long_msg => "Volume '$name':$long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Volume '$name':$short_msg"
                                        );
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check volume statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', .

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', .

=item B<--name>

Set the volume name.

=item B<--regexp>

Allows to use regexp to filter volume name (with option --name).

=back

=cut
    