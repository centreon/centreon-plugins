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

package apps::apc::web::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use centreon::plugins::values;

my $maps_counters = {
    'used' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'free' }, { name => 'used' }, 
                                      ],
                        closure_custom_calc => \&custom_used_calc,
                        closure_custom_output => \&custom_used_output,
                        threshold_use => 'used_prct',
                        output_error_template => 'Memory Usage: %s',
                        perfdatas => [
                            { value => 'used', label => 'used', template => '%d',
                              unit => 'B', min => 0, max => 'total', threshold_total => 'total' },
                        ],
                    }
               },
    'fragmentation' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'fragmentation' },
                                      ],
                        output_template => 'Memory Fragmentation: %.2f %%', output_error_template => 'Memory Fragmentation: %s',
                        output_use => 'fragmentation_absolute', threshold_use => 'fragmentation_absolute',
                        perfdatas => [
                            { value => 'fragmentation_absolute', label => 'fragmentation', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
};

sub custom_used_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_free'} + $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free_prct} =  $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{used_prct} =  $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_used_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf("Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_value . " " . $total_unit,
                   $used_value . " " . $used_unit, $self->{result_values}->{used_prct},
                   $free_value . " " . $free_unit, $self->{result_values}->{free_prct});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "hostname:s"        => { name => 'hostname' },
                                "port:s"            => { name => 'port', },
                                "proto:s"           => { name => 'proto', default => "http" },
                                "urlpath:s"         => { name => 'url_path', default => "/apc.php" },
                                "credentials"       => { name => 'credentials' },
                                "username:s"        => { name => 'username' },
                                "password:s"        => { name => 'password' },
                                "proxyurl:s"        => { name => 'proxyurl' },
                                "timeout:s"         => { name => 'timeout', default => 30 },
                                });
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{webcontent} = centreon::plugins::httplib::connect($self);

    $self->manage_selection();

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'mem');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{mem});

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
                                    short_msg => "Apc $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Apc $long_msg");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub in_bytes {
    my ($self, %options) = @_;
    my $value = $options{value};
    
    if ($options{unit} =~ /^G/) {
        $value *= 1024 * 1024 * 1024;
    } elsif ($options{unit} =~ /^M/) {
        $value *= 1024 * 1024;
    } elsif ($options{unit} =~ /^K/) {
        $value *= 1024;
    }
    
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my ($free, $used);
    if ($self->{webcontent} =~ /Memory Usage.*?Free:.*?([0-9\.]+)\s*(\S*)/msi) {
        $free = $self->in_bytes(value => $1, unit => $2);
    }
    if ($self->{webcontent} =~ /Memory Usage.*?Used:.*?([0-9\.]+)\s*(\S*)/msi) {
        $used = $self->in_bytes(value => $1, unit => $2);
    }
    $self->{mem} = {};
    $self->{mem}->{free} = $free;
    $self->{mem}->{used} = $used;
    $self->{mem}->{fragmentation} = $self->{webcontent} =~ /Fragmentation:.*?([0-9\.]+)/msi ? $1 : undef;
}

1;

__END__

=head1 MODE

Check memory usage. 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by web server

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/apc.php')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout (Default: 30)

=item B<--warning-*>

Threshold warning.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=item B<--critical-*>

Threshold critical.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=back

=cut
