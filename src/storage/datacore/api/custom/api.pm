#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
package storage::datacore::api::custom::api;
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc qw(empty);

sub new {
    my ($class, %options) = @_;
    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    my $self = {};
    bless $self, $class;

    $options{options}->add_options(arguments => {

        'hostname:s'        => { name => 'hostname' },
        'port:s'            => { name => 'port', default => 443 },
        'proto:s'           => { name => 'proto', default => 'https' },
        'timeout:s'         => { name => 'timeout' },
        'username:s'        => { name => 'username' },
        'password:s'        => { name => 'password' },
        # These options are here to defined conditions about which status the plugin will return regarding HTTP response code
        'unknown-status:s'  => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });
    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}
sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    # Check if the user provided a value for --hostname option. If not, display a message and exit
    if (centreon::plugins::misc::empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }
    $self->{cache}->check_options(option_results => $self->{option_results});
    # Set parameters for http module, note that the $self->{option_results} is a hash containing
    # all your options key/value pairs.
    $self->{http}->set_options(%{$self->{option_results}});
    if (centreon::plugins::misc::empty($self->{option_results}->{username})) {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option to authenticate against datacore rest api');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::empty($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => 'Please set password option to authenticate against datacore rest api');
        $self->{output}->option_exit();
    }

}
sub request_pool_id {
    my ($self, %options) = @_;

    if ($self->{cache}->read('statefile' => 'datacore_api_pool' . md5_hex($options{filter_server} . $options{filter_pool}))
        && $self->{cache}->get(name => 'expires_on') - time() < 10) {
        return $self->{cache}->get(name => 'access_token');
    }

    my @get_filter;
    if (!centreon::plugins::misc::empty($options{filter_server})) {
        push(@get_filter, { server => $options{filter_server} });
    }
    if (!centreon::plugins::misc::empty($options{filter_pool})) {
        push(@get_filter, { pool => $options{filter_pool} });
    }
    my $result = $self->request_api(
        get_param => \@get_filter,
        url_path  => '/RestService/rest.svc/1.0/pools');

    my $pool_id = $result->[0]->{Id};
    my $datas = { last_timestamp => time(), access_token => $pool_id, expires_on => time() + 3600 };
    $self->{cache}->write(data => $datas);
    return $pool_id;

}

sub request_api {
    my ($self, %options) = @_;
    my $result = $self->{http}->request(
        basic       => 1,
        username    => $self->{option_results}->{username},
        password    => $self->{option_results}->{password},
        headers     => ["ServerHost" => $self->{option_results}->{hostname} ],
        credentials => 1,
        %options,
    );
    # Declare a scalar deserialize the JSON content string into a perl data structure
    my $decoded_content;
    eval {
        $decoded_content = JSON::XS->new->decode($result);
    };
    # Catch the error that may arise in case the data received is not JSON
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON result");
        $self->{output}->option_exit();
    }
    return $decoded_content;

}
1;