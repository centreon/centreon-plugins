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

package apps::php::apc::web::mode::filecache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use Digest::MD5 qw(md5_hex);

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

sub prefix_output {
    my ($self, %options) = @_;

    return 'Apc File Cache Information ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fcache', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{fcache} = [
        { label => 'request-rate', nlabel => 'filecache.requests.persecond', set => {
                key_values => [ { name => 'rr' } ],
                output_template => 'Request Rate (global): %.2f',
                perfdatas => [
                    { label => 'request_rate', template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'request-rate-now', nlabel => 'filecache.requests.now.persecond', set => {
                key_values => [ { name => 'hits', diff => 1 }, { name => 'misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_rr_calc'),
                output_template => 'Request Rate : %.2f', output_error_template => 'Request Rate : %s',
                output_use => 'rr_now', threshold_use => 'rr_now',
                perfdatas => [
                    { label => 'request_rate_now', template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'hit-rate', nlabel => 'filecache.hits.persecond', set => {
                key_values => [ { name => 'hr' } ],
                output_template => 'Hit Rate (global): %.2f',
                perfdatas => [
                    { label => 'hit_rate',template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'hit-rate-now', nlabel => 'filecache.hits.now.persecond', set => {
                key_values => [ { name => 'hits', diff => 1 } ],
                closure_custom_calc => $self->can('custom_hr_calc'),
                output_template => 'Hit Rate : %.2f', output_error_template => 'Hit Rate : %s',
                output_use => 'hr_now', threshold_use => 'hr_now',
                perfdatas => [
                    { label => 'hit_rate_now', template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'miss-rate', nlabel => 'filecache.misses.persecond', set => {
                key_values => [ { name => 'mr' } ],
                output_template => 'Miss Rate (global): %.2f',
                perfdatas => [
                    { label => 'miss_rate',template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'miss-rate-now', nlabel => 'filecache.misses.now.persecond', set => {
                key_values => [ { name => 'misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_mr_calc'),
                output_template => 'Miss Rate : %.2f', output_error_template => 'Miss Rate : %s',
                output_use => 'mr_now', threshold_use => 'mr_now',
                perfdatas => [
                    { label => 'miss_rate_now', value => 'mr_now', template => '%.2f',
                      unit => 'r/s', min => 0 }
                ]
            }
        },
        { label => 'hit-percent', nlabel => 'filecache.hits.percentage', set => {
                key_values => [ { name => 'hits' }, { name => 'misses' } ],
                closure_custom_calc => $self->can('custom_hit_percent_calc'),
                output_template => 'Hit Ratio (global) : %.2f %%', output_error_template => 'Hit Ratio (global): %s',
                output_use => 'hit_ratio', threshold_use => 'hit_ratio',
                perfdatas => [
                    { label => 'hit_ratio', value => 'hit_ratio', template => '%.2f',
                      unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'hit-percent-now', nlabel => 'filecache.hits.now.percentage', set => {
                key_values => [ { name => 'hits', diff => 1 }, { name => 'misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_hit_percent_now_calc'),
                output_template => 'Hit Ratio : %.2f %%', output_error_template => 'Hit Ratio : %s',
                output_use => 'hit_ratio_now', threshold_use => 'hit_ratio_now',
                perfdatas => [
                    { label => 'hit_ratio_now', value => 'hit_ratio_now', template => '%.2f',
                      unit => '%', min => 0, max => 100 }
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
        'urlpath:s'   => { name => 'url_path', default => "/apc.php" },
        'credentials' => { name => 'credentials' },
        'basic'       => { name => 'basic' },
        'username:s'  => { name => 'username' },
        'password:s'  => { name => 'password' },
        'timeout:s'   => { name => 'timeout', default => 30 }
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

    $self->{fcache} = {};
    $self->{fcache}->{hits} = $webcontent =~ /File Cache Information.*?Hits.*?(\d+)/msi ? $1 : undef;
    $self->{fcache}->{misses} = $webcontent =~ /File Cache Information.*?Misses.*?(\d+)/msi ? $1 : undef;
    $self->{fcache}->{rr} = $webcontent =~ /File Cache Information.*?Request Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{hr} = $webcontent =~ /File Cache Information.*?Hit Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{mr} = $webcontent =~ /File Cache Information.*?Miss Rate.*?([0-9\.]+)/msi ? $1 : undef;
    $self->{fcache}->{ir} = $webcontent =~ /File Cache Information.*?Insert Rate.*?([0-9\.]+)/msi ? $1 : undef;

    $self->{cache_name} = 'apc_' . $self->{mode} . '_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
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
Can be: 'request-rate', 'request-rate-now', 
'hit-rate', 'hit-rate-now', 'miss-rate', 'miss-rate-now',
'hit-percent', 'hit-percent-now'.
'*-now' are rate between two calls.

=item B<--critical-*>

Threshold critical.
Can be: 'request-rate', 'request-rate-now', 
'hit-rate', 'hit-rate-now', 'miss-rate', 'miss-rate-now',
'hit-percent', 'hit-percent-now'.
'*-now' are rate between two calls.

=back

=cut
