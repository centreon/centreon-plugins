use strict;
use warnings;
use Test2::V0;
use FindBin;
use MIME::Base64 qw(decode_base64);
use lib "$FindBin::RealBin/../../../../src";
use apps::vmware::vsphere8::custom::api;


# Mock options class
{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

{
    package MockOutput;
    sub new { bless {}, shift }
    sub add_option_msg { }
    sub option_exit { }

}

{
    package MockHttp;
    sub new { bless { requests => [] }, shift }
    sub request {
        my ($self, %options) = @_;
        push @{$self->{requests}}, \%options;
        return '"abcdef00-0000-0000-0000-000000000001"';
    }
}

{
    package MockTokenCache;
    sub new { bless {}, shift }
    sub read { 0 }
    sub get { undef }
    sub write { }
}

sub test_authorization_header {
    my ($username, $password, $description) = @_;

    my $api = apps::vmware::vsphere8::custom::api->new(
        options => MockOptions->new(),
        output  => MockOutput->new()
    );
    $api->{hostname}      = 'localhost';
    $api->{port}          = 3000;
    $api->{username}      = $username;
    $api->{password}      = $password;
    $api->{http}          = MockHttp->new();
    $api->{token_cache}   = MockTokenCache->new();
    $api->{settings_done} = 1;

    is($api->get_token(), 'abcdef00-0000-0000-0000-000000000001', "$description: token returned");

    my ($auth_header) = grep { /^Authorization:/ } @{$api->{http}->{requests}->[0]->{header}};
    unlike($auth_header, qr/\n/, "$description: Authorization header is a single line");
    my ($auth_string) = $auth_header =~ m{^Authorization: Basic ([A-Za-z0-9+/]+=*)$};
    ok(defined($auth_string), "$description: Authorization header is a Basic one");
    # decode_base64 ignores newlines, hence the single line check above
    is(decode_base64($auth_string // ''), "$username:$password", "$description: credentials decoded from the header");
}

sub process_test {
    my ($hostname, $port, $proto, $url_path, $timeout, $username, $password) = @_;

    # Create mock object
    my $options = MockOptions->new();
    my $output  = MockOutput->new();

    # Add options to the $options hashref
    $options->{hostname}    = $hostname;
    $options->{port}        = $port;
    $options->{proto}       = $proto;
    $options->{timeout}     = $timeout;
    $options->{username}    = $username;
    $options->{password}    = $password;

    # Test object creation
    my $api;
    eval {
        $api = apps::vmware::vsphere8::custom::api->new(
            options => $options,
            output => $output
        );
    };
    ok(!$@, 'Object creation without errors');

    # Test if the object is blessed correctly
    is(ref($api), 'apps::vmware::vsphere8::custom::api', 'Object is of correct class');

    # Test if the object has the expected attributes
    can_ok($api, qw(new set_options check_options));

    $api->set_options(option_results => $options);
    # Verify that option_results is set correctly
    is($api->{option_results}, $options, 'option_results set correctly');

    # Test check_options method
    eval { $api->check_options(option_results => $options) };
    ok(!$@, 'check_options method executed without errors');

    is($api->{hostname},    $hostname,  'hostname set correctly');
    is($api->{port},        defined($port)      ? $port     : 443,      'port set correctly');
    is($api->{proto},       defined($proto)     ? $proto    : 'https',  'proto set correctly');
    is($api->{timeout},     defined($timeout)   ? $timeout  : 10,       'timeout set correctly');
    is($api->{username},    defined($username)  ? $username : '',       'username set correctly');
    is($api->{password},    defined($password)  ? $password : '',       'password set correctly');

}

sub main {
    #process_test('localhost', 443, 'https', '/v2', 10, 'user', 'pass');
    process_test('localhost', 3000, 'http', undef, 10, 'login', 'password');

    test_authorization_header('login', 'password', 'short credentials');
    # 83 characters: encode_base64 wraps its output beyond 57 input characters
    test_authorization_header('user@vsphere.local', 'abcdefgh' x 8, 'long credentials');
}

main();

done_testing();


__END__



# Test check_options method with missing username
$option_results = {
    hostname => 'localhost',
    port => 443,
    proto => 'https',
    url_path => '/v2',
    timeout => 10,
    password => 'pass'
};
$api->set_options(option_results => $option_results);
eval { $api->check_options() };
like($@, qr/Need to specify --username option/, 'Missing username handled correctly');

# Test check_options method with missing password
$option_results = {
    hostname => 'localhost',
    port => 443,
    proto => 'https',
    url_path => '/v2',
    timeout => 10,
    username => 'user'
};
$api->set_options(option_results => $option_results);
eval { $api->check_options() };
like($@, qr/Need to specify --password option/, 'Missing password handled correctly');


done_testing();
