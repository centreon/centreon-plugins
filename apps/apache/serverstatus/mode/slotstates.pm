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

package apps::apache::serverstatus::mode::slotstates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;

sub custom_value_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_value_perfdata {
    my ($self, %options) = @_;
    
    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1);
    } else {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    
    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label},
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{used},
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_value_output {
    my ($self, %options) = @_;
    
    my $label = $self->{result_values}->{label};
    $label =~ s/_/ /g;
    return sprintf(
        "%s: %s (%.2f %%)",
        $label,
        $self->{result_values}->{used},
        $self->{result_values}->{prct}
    );
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -2 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'busy', nlabel => 'apache.slot.busy.count', set => {
                key_values => [ { name => 'busy' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'busy' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'free', nlabel => 'apache.slot.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'free' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'waiting', nlabel => 'apache.slot.waiting.count', set => {
                key_values => [ { name => 'waiting' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'waiting' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'starting', nlabel => 'apache.slot.starting.count', set => {
                key_values => [ { name => 'starting' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'starting' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'reading', nlabel => 'apache.slot.reading.count', set => {
                key_values => [ { name => 'reading' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'reading' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'sending', nlabel => 'apache.slot.sending.count', set => {
                key_values => [ { name => 'sending' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'sending' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'keepalive', nlabel => 'apache.slot.keepalive.count', set => {
                key_values => [ { name => 'keepalive' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'keepalive' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'dns-lookup', nlabel => 'apache.slot.dnslookup.count', set => {
                key_values => [ { name => 'dns_lookup' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'dns_lookup' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'closing', nlabel => 'apache.slot.closing.count', set => {
                key_values => [ { name => 'closing' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'closing' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'logging', nlabel => 'apache.slot.logging.count', set => {
                key_values => [ { name => 'logging' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'logging' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
        { label => 'gracefuly-finished', nlabel => 'apache.slot.gracefulyfinished.count', set => {
                key_values => [ { name => 'gracefuly_finished' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'gracefuly_finished' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
         { label => 'idle-cleanup-worker', nlabel => 'apache.slot.idlecleanupworker.count', set => {
                key_values => [ { name => 'idle_cleanup_worker' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_value_calc'), closure_custom_calc_extra_options => { label_ref => 'idle_cleanup_worker' },
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_threshold_check => $self->can('custom_value_threshold'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'hostname:s'  => { name => 'hostname' },
        'port:s'      => { name => 'port', },
        'proto:s'     => { name => 'proto' },
        'urlpath:s'   => { name => 'url_path', default => "/server-status/?auto" },
        'credentials' => { name => 'credentials' },
        'basic'       => { name => 'basic' },
        'username:s'  => { name => 'username' },
        'password:s'  => { name => 'password' },
        'header:s@'   => { name => 'header' },
        'timeout:s'   => { name => 'timeout' },
        'units:s'     => { name => 'units', default => '%' }
    });
    
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{http}->set_options(%{$self->{option_results}});
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Slots ';
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($webcontent) = $self->{http}->request();
    my $ScoreBoard = "";
    if ($webcontent =~ /^Scoreboard:\s+([^\s]+)/mi) {
        $ScoreBoard = $1;
    }

    $self->{global} = { 
        total => length($ScoreBoard),
        free => ($ScoreBoard =~ tr/\.//) + ($ScoreBoard =~ tr/\_//),
        busy => length($ScoreBoard) - ($ScoreBoard =~ tr/\.//) - ($ScoreBoard =~ tr/\_//),
        waiting => ($ScoreBoard =~ tr/\_//), starting => ($ScoreBoard =~ tr/S//),
        reading => ($ScoreBoard =~ tr/R//), sending => ($ScoreBoard =~ tr/W//),
        keepalive => ($ScoreBoard =~ tr/K//), dns_lookup => ($ScoreBoard =~ tr/D//),
        closing => ($ScoreBoard =~ tr/C//), logging => ($ScoreBoard =~ tr/L//),
        gracefuly_finished => ($ScoreBoard =~ tr/G//), idle_cleanup_worker => ($ScoreBoard =~ tr/I//)
    };
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

=item B<--proto>

Protocol used http or https

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

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
