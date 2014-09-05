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

package apps::apc::web::mode::filecache;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::values;

my $maps_counters = {
    'request-rate' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'rr' },
                                      ],
                        output_template => 'Request Rate (global): %.2f',
                        perfdatas => [
                            { value => 'rr_absolute', label => 'request_rate',template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'request-rate-now' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'hits', diff => 1 }, { name => 'misses', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_rr_calc, per_second => 1,
                        output_template => 'Request Rate : %.2f', output_error_template => 'Request Rate : %s',
                        output_use => 'rr_now', threshold_use => 'rr_now',
                        perfdatas => [
                            { value => 'rr_now', label => 'request_rate_now', template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'hit-rate' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'hr' },
                                      ],
                        output_template => 'Hit Rate (global): %.2f',
                        perfdatas => [
                            { value => 'hr_absolute', label => 'hit_rate',template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'hit-rate-now' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'hits', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_hr_calc, per_second => 1,
                        output_template => 'Hit Rate : %.2f', output_error_template => 'Hit Rate : %s',
                        output_use => 'hr_now', threshold_use => 'hr_now',
                        perfdatas => [
                            { value => 'hr_now', label => 'hit_rate_now', template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'miss-rate' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'mr' },
                                      ],
                        output_template => 'Miss Rate (global): %.2f',
                        perfdatas => [
                            { value => 'mr_absolute', label => 'miss_rate',template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'miss-rate-now' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'misses', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_mr_calc, per_second => 1,
                        output_template => 'Miss Rate : %.2f', output_error_template => 'Miss Rate : %s',
                        output_use => 'mr_now', threshold_use => 'mr_now',
                        perfdatas => [
                            { value => 'mr_now', label => 'miss_rate_now', template => '%.2f',
                              unit => 'r/s', min => 0 },
                        ],
                    }
               },
    'hit-percent' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'hits' }, { name => 'misses' },
                                      ],
                        closure_custom_calc => \&custom_hit_percent_calc,
                        output_template => 'Hit Ratio (global) : %.2f %%', output_error_template => 'Hit Ratio (global): %s',
                        output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                        perfdatas => [
                            { value => 'hit_ratio', label => 'hit_ratio', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
    'hit-percent-now' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'hits', diff => 1 }, { name => 'misses', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_hit_percent_now_calc,
                        output_template => 'Hit Ratio : %.2f %%', output_error_template => 'Hit Ratio : %s',
                        output_use => 'hit_ratio_now', threshold_use => 'hit_ratio_now',
                        perfdatas => [
                            { value => 'hit_ratio_now', label => 'hit_ratio_now', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
};

sub custom_rr_calc {
    my ($self, %options) = @_;
    my $total = ($options{new_datas}->{$self->{instance} . '_hits'} - $options{old_datas}->{$self->{instance} . '_hits'})
                + ($options{new_datas}->{$self->{instance} . '_misses'} - $options{old_datas}->{$self->{instance} . '_misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{rr_now} = $total / $options{delta_time};
    return 0;
}

sub custom_hr_calc {
    my ($self, %options) = @_;
    my $total = ($options{new_datas}->{$self->{instance} . '_hits'} - $options{old_datas}->{$self->{instance} . '_hits'});
                
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{hr_now} = $total / $options{delta_time};
    return 0;
}

sub custom_mr_calc {
    my ($self, %options) = @_;
    my $total = ($options{new_datas}->{$self->{instance} . '_misses'} - $options{old_datas}->{$self->{instance} . '_misses'});
                
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{mr_now} = $total / $options{delta_time};
    return 0;
}

sub custom_hit_percent_now_calc {
    my ($self, %options) = @_;
    my $hits = ($options{new_datas}->{$self->{instance} . '_hits'} - $options{old_datas}->{$self->{instance} . '_hits'});
    my $total = $hits + ($options{new_datas}->{$self->{instance} . '_misses'} - $options{old_datas}->{$self->{instance} . '_misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{hit_ratio_now} = $hits * 100 / $total;
    return 0;
}

sub custom_hit_percent_calc {
    my ($self, %options) = @_;
    my $hits = ($options{new_datas}->{$self->{instance} . '_hits'});
    my $total = $hits + ($options{new_datas}->{$self->{instance} . '_misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{hit_ratio} = $hits * 100 / $total;
    return 0;
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

    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{webcontent} = centreon::plugins::httplib::connect($self);

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile =>  "apc_" . $self->{option_results}->{hostname}  . '_' . centreon::plugins::httplib::get_port($self) . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'fcache');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{fcache},
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
                                    short_msg => "Apc File Cache Information $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Apc File Cache Information $long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{fcache} = {};
    $self->{fcache}->{hits} = $self->{webcontent} =~ /File Cache Information.*?Hits.*?(\d+)/msi ? $1 : undef;
    $self->{fcache}->{misses} = $self->{webcontent} =~ /File Cache Information.*?Misses.*?(\d+)/msi ? $1 : undef;
    $self->{fcache}->{rr} = $self->{webcontent} =~ /File Cache Information.*?Request Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{hr} = $self->{webcontent} =~ /File Cache Information.*?Hit Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{mr} = $self->{webcontent} =~ /File Cache Information.*?Miss Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{ir} = $self->{webcontent} =~ /File Cache Information.*?Insert Rate.*?([0-9\.]+)/msi ? $1 : undef;
}

1;

__END__

=head1 MODE

Check file cache informations. 

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
Can be: 'request-rate', 'request-rate-now', 
'hit-rate', 'hit-rate-now', 'miss-rate', 'miss-rate-now', 'insert-rate',
'hit-percent', 'hit-percent-now'.
'*-now' are rate between two calls.

=item B<--critical-*>

Threshold critical.
Can be: 'request-rate', 'request-rate-now', 
'hit-rate', 'hit-rate-now', 'miss-rate', 'miss-rate-now', 'insert-rate',
'hit-percent', 'hit-percent-now'.
'*-now' are rate between two calls.

=back

=cut
