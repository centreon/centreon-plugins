#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::apache::serverstatus::mode::slotstates;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::values;

my $instance_mode;

my $maps_counters = {
    global => {
        '000_busy'   => { set => {
                key_values => [ { name => 'busy' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'busy' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '001_free'   => { set => {
                key_values => [ { name => 'free' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'free' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '002_waiting'   => { set => {
                key_values => [ { name => 'waiting' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'waiting' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '003_starting'   => { set => {
                key_values => [ { name => 'starting' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'starting' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '004_reading'   => { set => {
                key_values => [ { name => 'reading' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'reading' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '005_sending'   => { set => {
                key_values => [ { name => 'sending' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'sending' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '006_keepalive'   => { set => {
                key_values => [ { name => 'keepalive' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'keepalive' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '007_dns-lookup'   => { set => {
                key_values => [ { name => 'dns_lookup' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'dns_lookup' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '008_closing'   => { set => {
                key_values => [ { name => 'closing' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'closing' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '009_logging'   => { set => {
                key_values => [ { name => 'logging' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'logging' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '007_gracefuly-finished'   => { set => {
                key_values => [ { name => 'gracefuly_finished' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'gracefuly_finished' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
        '007_idle-cleanup-worker'   => { set => {
                key_values => [ { name => 'idle_cleanup_worker' }, { name => 'total' } ],
                closure_custom_calc => \&custom_value_calc, closure_custom_calc_extra_options => { label_ref => 'idle_cleanup_worker' },
                closure_custom_output => \&custom_value_output,
                closure_custom_threshold_check => \&custom_value_threshold,
                closure_custom_perfdata => \&custom_value_perfdata,
            }
        },
    },
};

sub custom_value_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($instance_mode->{option_results}->{units} eq '%') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_value_perfdata {
    my ($self, %options) = @_;
    
    my ($warning, $critical);
    if ($instance_mode->{option_results}->{units} eq '%') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1);
    } else {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }
    
    $self->{output}->perfdata_add(label => $self->{result_values}->{label},
                                  value => $self->{result_values}->{used},
                                  warning => $warning,
                                  critical => $critical,
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_value_output {
    my ($self, %options) = @_;
    
    my $label = $self->{result_values}->{label};
    $label =~ s/_/ /g;
    $label =~ s/(\w+)/\u$1/g;
    my $msg = sprintf("%s : %s (%.2f %%)",
                      ucfirst($label),
                      $self->{result_values}->{used}, $self->{result_values}->{prct});
    return $msg;
}

sub custom_value_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    if ($self->{result_values}->{total} == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};    
    $self->{result_values}->{prct} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "hostname:s"    => { name => 'hostname' },
                                "port:s"        => { name => 'port', },
                                "proto:s"       => { name => 'proto' },
                                "urlpath:s"     => { name => 'url_path', default => "/server-status/?auto" },
                                "credentials"   => { name => 'credentials' },
                                "username:s"    => { name => 'username' },
                                "password:s"    => { name => 'password' },
                                "proxyurl:s"    => { name => 'proxyurl' },
                                "header:s@"     => { name => 'header' },
                                "timeout:s"     => { name => 'timeout' },
                                "units:s"       => { name => 'units', default => '%' },
                                });
    
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    
    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output},
                                                      perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
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
                                    short_msg => "Slots $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Slots $long_msg");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();
    my $ScoreBoard = "";
    if ($webcontent =~ /^Scoreboard:\s+([^\s]+)/mi) {
        $ScoreBoard = $1;
    }
    
    $self->{global} = { total => length($ScoreBoard),
                        free => ($ScoreBoard =~ tr/\.//),
                        busy => length($ScoreBoard) - ($ScoreBoard =~ tr/\.//),
                        waiting => ($ScoreBoard =~ tr/\_//), starting => ($ScoreBoard =~ tr/S//),
                        reading => ($ScoreBoard =~ tr/R//), sending => ($ScoreBoard =~ tr/W//),
                        keepalive => ($ScoreBoard =~ tr/K//), dns_lookup => ($ScoreBoard =~ tr/D//),
                        closing => ($ScoreBoard =~ tr/C//), logging => ($ScoreBoard =~ tr/L//),
                        gracefuly_finished => ($ScoreBoard =~ tr/G//), idle_cleanup_worker => ($ScoreBoard =~ tr/I//)};
}

1;

__END__

=head1 MODE

Check Apache WebServer Slots informations

=over 8

=item B<--hostname>

IP Address or FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Protocol used http or https

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--header>

Set HTTP headers (Multiple option)

=item B<--units>

Threshold unit (Default: '%'. Can be: '%' or 'absolute')

=item B<--warning-*>

Warning threshold.
Can be: 'busy', 'free', 'waiting', 'starting', 'reading',
'sending', 'keepalive', 'dns-lookup', 'closing',
'logging', 'gracefuly-finished', 'idle-cleanup-worker'.

=item B<--critical-*>

Critical threshold.
Can be: 'busy', 'free', 'waiting', 'starting', 'reading',
'sending', 'keepalive', 'dns-lookup', 'closing',
'logging', 'gracefuly-finished', 'idle-cleanup-worker'.

=over 8)

=back

=cut
