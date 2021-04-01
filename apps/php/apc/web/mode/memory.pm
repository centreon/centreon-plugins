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

package apps::php::apc::web::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc;

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

    return sprintf(
        "Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_value . " " . $total_unit,
        $used_value . " " . $used_unit, $self->{result_values}->{used_prct},
        $free_value . " " . $free_unit, $self->{result_values}->{free_prct}
    );
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Apc ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'mem', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{mem} = [
        { label => 'used', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'free' } ],
                closure_custom_calc => $self->can('custom_used_calc'),
                closure_custom_output => $self->can('custom_used_output'),
                threshold_use => 'used_prct',
                output_error_template => 'Memory Usage: %s',
                perfdatas => [
                    { label => 'used', template => '%d',
                      unit => 'B', min => 0, max => 'total', threshold_total => 'total' }
                ]
            }
        },
        { label => 'fragmentation', nlabel => 'memory.fragmentation.percentage', set => {
                key_values => [ { name => 'fragmentation' } ],
                output_template => 'Memory Fragmentation: %.2f %%', output_error_template => 'Memory Fragmentation: %s',
                output_use => 'fragmentation', threshold_use => 'fragmentation',
                perfdatas => [
                    { label => 'fragmentation', template => '%.2f',
                      unit => '%', min => 0, max => 100 }
                ]
            }
        }
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
        'urlpath:s'   => { name => 'url_path', default => "/apc.php" },
        'credentials' => { name => 'credentials' },
        'basic'       => { name => 'basic' },
        'username:s'  => { name => 'username' },
        'password:s'  => { name => 'password' },
        'timeout:s'   => { name => 'timeout', default => 30 },
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

    my ($free, $used);
    if ($webcontent =~ /Memory Usage.*?Free:.*?([0-9\.]+)\s*(\S*)/msi) {
        $free = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
    }
    if ($webcontent =~ /Memory Usage.*?Used:.*?([0-9\.]+)\s*(\S*)/msi) {
        $used = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
    }
    $self->{mem} = {};
    $self->{mem}->{free} = $free;
    $self->{mem}->{used} = $used;
    $self->{mem}->{fragmentation} = $webcontent =~ /Fragmentation:.*?([0-9\.]+)/msi ? $1 : undef;
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

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/apc.php')

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

Threshold for HTTP timeout (Default: 30)

=item B<--warning-*>

Threshold warning.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=item B<--critical-*>

Threshold critical.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=back

=cut
