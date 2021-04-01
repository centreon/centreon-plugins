#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::checkmyws::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
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

    $options{options}->add_options(arguments => {
        "hostname:s"            => { name => 'hostname', default => 'api.checkmy.ws'},
        "port:s"                => { name => 'port', },
        "proto:s"               => { name => 'proto', default => "https" },
        "urlpath:s"             => { name => 'url_path', default => "/api/status" },
        "uid:s"                 => { name => 'uid' },
        "timeout:s"             => { name => 'timeout' },
        "threshold-overload:s@" => { name => 'threshold_overload' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
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
    
    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."/".$self->{option_results}->{uid};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $jsoncontent = $self->{http}->request();

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

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get checkmyws information (Default: '/api/status')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--uid>

ID for checkmyws API

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(0)$)'

=back

=cut
