package storage::datacore::api::custom::api;
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub empty {
    my $value = shift;
    if (!defined($value) || $value eq '') {
        return 1;
    }
    return 0;
}

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
    if (empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option');
        $self->{output}->option_exit();
    }
    $self->{cache}->check_options(option_results => $self->{option_results});
    # Set parameters for http module, note that the $self->{option_results} is a hash containing
    # all your options key/value pairs.
    $self->{http}->set_options(%{$self->{option_results}});
    if (empty($self->{option_results}->{username})) {
        $self->{output}->add_option_msg(short_msg => 'Please set hostname option to authenticate against datacore rest api');
        $self->{output}->option_exit();
    }
    if (empty($self->{option_results}->{password})) {
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
    if (!empty($options{filter_server})) {
        push(@get_filter, { server => $options{filter_server} });
    }
    if (!empty($options{filter_pool})) {
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