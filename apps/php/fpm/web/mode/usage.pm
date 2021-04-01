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

package apps::php::fpm::web::mode::usage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use Digest::MD5 qw(md5_hex);

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{active_prct} =  $self->{result_values}->{active} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_active_output {
    my ($self, %options) = @_;

    return sprintf(
        'active processes: %s (%.2f%%)',
        $self->{result_values}->{active},
        $self->{result_values}->{active_prct}
    );
}

sub custom_active_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'active',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_idle_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{idle} = $options{new_datas}->{$self->{instance} . '_idle'};
    $self->{result_values}->{idle_prct} =  $self->{result_values}->{idle} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_idle_output {
    my ($self, %options) = @_;

    return sprintf(
        'idle processes: %s (%.2f%%)',
        $self->{result_values}->{idle},
        $self->{result_values}->{idle_prct}
    );
}

sub custom_idle_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'idle',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{idle},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub prefix_output {
    my ($self, %options) = @_;

    return 'php-fpm ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fpm', type => 0, cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{fpm} = [
        { label => 'active-processes', nlabel => 'fpm.processes.active.count', set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                threshold_use => 'active_prct',
                closure_custom_perfdata =>  => $self->can('custom_active_perfdata')
            }
        },
        { label => 'idle-processes', nlabel => 'fpm.processes.idle.count', set => {
                key_values => [ { name => 'idle' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_idle_calc'),
                closure_custom_output => $self->can('custom_idle_output'),
                threshold_use => 'idle_prct',
                closure_custom_perfdata =>  => $self->can('custom_idle_perfdata')
            }
        },
        { label => 'listen-queue', nlabel => 'fpm.queue.listen.count', set => {
                key_values => [ { name => 'listen_queue' }, { name => 'max_listen_queue' } ],
                output_template => 'listen queue: %s',
                output_use => 'listen_queue', threshold_use => 'listen_queue',
                perfdatas => [
                    { label => 'listen_queue', template => '%s',
                      min => 0, max => 'max_listen_queue' }
                ]
            }
        },
        { label => 'requests', nlabel => 'fpm.requests.persecond', set => {
                key_values => [ { name => 'request', per_second => 1 } ],
                output_template => 'requests: %.2f/s',
                perfdatas => [
                    { label => 'requests', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'hostname:s'  => { name => 'hostname' },
        'port:s'      => { name => 'port', },
        'proto:s'     => { name => 'proto' },
        'urlpath:s'   => { name => 'url_path', default => "/fpm-status" },
        'credentials' => { name => 'credentials' },
        'basic'       => { name => 'basic' },
        'username:s'  => { name => 'username' },
        'password:s'  => { name => 'password' },
        'timeout:s'   => { name => 'timeout', default => 5 }
    });

    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();

    $self->{fpm} = {};
    $self->{fpm}->{request} = $1 if ($webcontent =~ /accepted\s+conn:\s+(\d+)/msi);
    $self->{fpm}->{listen_queue} = $1 if ($webcontent =~ /listen\s+queue:\s+(\d+)/msi);
    $self->{fpm}->{max_listen_queue} = $1 if ($webcontent =~ /max\s+listen\s+queue:\s+(\d+)/msi);
    $self->{fpm}->{idle} = $1 if ($webcontent =~ /idle\s+processes:\s+(\d+)/msi);
    $self->{fpm}->{active} = $1 if ($webcontent =~ /active\s+processes:\s+(\d+)/msi);
    $self->{fpm}->{total} = $1 if ($webcontent =~ /total\s+processes:\s+(\d+)/msi);

    $self->{cache_name} = 'php_fpm_' . $self->{mode} . '_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check php-fpm usage. 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by web server

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/fpm-status')

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

Threshold for HTTP timeout (Default: 5)

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active-processes' (%), 'idle-processes' (%),
'listen-queue', 'requests'.

=back

=cut
