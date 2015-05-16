###############################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

package apps::checkmyws::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use JSON;

my $thresholds = {
    ws => [
        ['^0$', 'OK'],
        ['^1$', 'WARNING'],
        ['^2$', 'CRITICAL'],
        ['.*', 'UNKNOWN'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"            => { name => 'hostname', default => 'api.checkmy.ws'},
            "port:s"                => { name => 'port', },
            "proto:s"               => { name => 'proto', default => "https" },
            "urlpath:s"             => { name => 'url_path', default => "/api/status" },
            "proxyurl:s"            => { name => 'proxyurl' },
            "uid:s"                 => { name => 'uid' },
            "timeout:s"             => { name => 'timeout', default => '3' },
            "threshold-overload:s@" => { name => 'threshold_overload' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if ((!defined($self->{option_results}->{uid}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set uid option");
        $self->{output}->option_exit();
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('ws', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."/".$self->{option_results}->{uid};

    my $jsoncontent = centreon::plugins::httplib::connect($self);

    my $json = JSON->new;

    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my %map_output = (
        -3 => 'Disable', 
        -2 => 'Not scheduled', 
        -1 => 'Pending...', 
    );
    my $state = $webcontent->{state};
    my $output = defined($map_output{$state}) ? $map_output{$state} : $webcontent->{state_code_str};    
    
    my $exit = $self->get_severity(section => 'ws', value => $state);
    $self->{output}->output_add(severity => $exit,
                                short_msg => $output);

    if (defined($webcontent->{lastvalues}->{httptime})) {
        my $perfdata = $webcontent->{lastvalues}->{httptime};

        my $mean_time = 0;
        foreach my $location (keys %$perfdata) { 
            $mean_time += $perfdata->{$location};
            $self->{output}->perfdata_add(label => $location,  unit => 'ms',
              value => $perfdata->{$location},
              min => 0
            );
        }
        
        $self->{output}->perfdata_add(label => 'mean_time', unit => 'ms',
              value => $mean_time / scalar(keys %$perfdata),
              min => 0
            ) if (scalar(keys %$perfdata) > 0);
        $self->{output}->perfdata_add(label => 'yslow_page_load_time', unit => 'ms',
              value => $webcontent->{metas}->{yslow_page_load_time},
              min => 0
            ) if (defined($webcontent->{metas}->{yslow_page_load_time}));
        $self->{output}->perfdata_add(label => 'yslow_score',
              value => $webcontent->{metas}->{yslow_score},
              min => 0, max => 100
            ) if (defined($webcontent->{metas}->{yslow_score}));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check website status

=over 8

=item B<--hostname>

Checkmyws api host (Default: 'api.checkmy.ws')

=item B<--port>

Port used by checkmyws

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get checkmyws information (Default: 'api/status')

=item B<--proxyurl>

Proxy URL if any

=item B<--uid>

ID for checkmyws API

=item B<--timeout>

Threshold for HTTP timeout (Default: '3')

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(0)$)'

=back

=cut
