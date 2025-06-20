#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

use Net::Curl::Easy qw(:constants);
use Data::Dumper;
use File::Copy;
use IO::Socket::INET;

# Here, we test that in various cases, requests made using the centreon
# curl backend and the curl utility send the same headers and data to the
# HTTP server.

use FindBin;
use lib "$FindBin::RealBin/../../../src";

my $port = 7654;
my @output=();
my $pid;

{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

{
    package MockOutput;

    sub new { bless {}, shift }
    sub add_option_msg {  }
    sub output_add {
        my ($self, %options) = @_;

        push @output, $options{long_msg};

    }
    sub is_status {  }
    sub display {  }
    sub exit {  }
    sub option_exit {  }
    sub is_debug { 1 }
    sub test_eval {  }
}

use centreon::plugins::http;
use centreon::plugins::misc;

my $http;

sub curl_client
{
    my $curlbackend = centreon::plugins::http->new(options=>MockOptions->new(), output=> MockOutput->new(), default_backend => 'curl',);
    $curlbackend->set_options(port => $port);
    return $curlbackend;
}

sub test_backend
{
    my (%options) = @_;

    @output=();

    my $curl = curl_client();

    if ($options{headers} && ref $options{headers} eq 'ARRAY') {
        $curl->add_header(key => $_->{key}, value => $_->{value}) foreach @{$options{headers}}
    }

    $curl->request(%options);
    # Retrieve headers and data from centreon curl backend output.
    my @cupscmd = map { /:\s(.+)$/; $1 } grep { defined && /^curl request.*:/ } @output;
    my @sendheader = map { s/^=> Send header: //; s/[\r\n]//g; $_ } grep { defined && /^=> Send header: / } @output;
    my @senddata = map { s/^=> Send data: //; s/[\r\n]//g; $_ } grep { defined && /^=> Send data: / } @output;
    return { command => @cupscmd == 1 ? $cupscmd[0] : '',
             sendheader => @sendheader == 1 ? $sendheader[0] : '',
             senddata => @senddata == 1 ? $senddata[0] : '',
           };
}

sub test_curl
{
    my ($cmd) = @_;

    # Retrieve headers and data from curl output.
    # We need to remove the User-Agent header and add the --trace-ascii option,
    # otherwise curl does not display the data part.
    open my $pipe, '-|', 'sh', '-c', $cmd. ' -H User-Agent: --trace-ascii - 2>&1', or die;

    my $state = 0;
    my (@send_header, @send_data);
    foreach my $read (<$pipe>) {
        if ($read =~ /^=> Send header/) {
            $state = 1;
            next;
        } elsif ($read =~ /^=> Send data/) {
            $state = 2;
            next;
        } elsif ($read =~ /^[=<]/ || $read =~ /^=> R/) {
            $state = 0;
            next;
        }
        next unless $read =~ /^0[^:]+:\s(.*)/;
        if ($state == 1) {
            push @send_header, $1;
        } elsif ($state == 2) {
            push @send_data, $1;
        }
    }

    close($pipe);

    return {
             sendheader => (join '', @send_header),
	     senddata  => (join '', @send_data)
	    };
}

sub test_full
{
    my ($title, $contains, %options) = @_;
    print "test $title\n";

    my $backend = test_backend(%options);

    # Backend output shoud contain valid curl command
    if ($contains && ref $contains eq 'ARRAY') {
        my $match = 0;
        foreach (@$contains) {
            $match++ if $backend->{command} =~ /$_/;
	}
	ok($match == @$contains, "Command contains required parameters");
    } else {
        ok($backend->{command} =~ /^curl/, "Command ok");
    }

    # Backend output should contain a header and/or a data part
    ok($backend->{sendheader} || $backend->{senddata}, "Retrieved header/data with backend");
    my $curl = test_curl($backend->{command});

    # Curl output should contain a header and/or a data part
    ok($curl->{sendheader} || $curl->{senddata}, "Retrieved header/data with curl");

    # We update boundary lines, which normally changes between requests
    $backend->{sendheader} =~ s/boundary=----[-a-zA-Z0-9]+/boundary=----XXXXXX/;
    $curl->{sendheader}=~ s/boundary=----[-a-zA-Z0-9]+/boundary=----XXXXXX/;

    # We update aws signature lines, which normally changes between requests
    $backend->{sendheader} =~ s/(user-agent;)?x-osc-date, Signature=[-a-f0-9]+X-Osc-Date: [\dTZ]+/x-osc-date, Signature=AAAAAAX-Osc-Date: 20250620T140600Z/;
    $curl->{sendheader} =~ s/(user-agent;)?x-osc-date, Signature=[-a-f0-9]+X-Osc-Date: [\dTZ]+/x-osc-date, Signature=AAAAAAX-Osc-Date: 20250620T140600Z/;

    $backend->{senddata} =~ s/-------[-a-zA-Z0-9]+/--------XXXXXX/g;
    $curl->{senddata}=~ s/-------[-a-zA-Z0-9]+/--------XXXXXX/g;

    # Backend and curl outputs should be the same
    ok($backend->{sendheader} eq $curl->{sendheader}, "Headers part match");
    ok($backend->{senddata} eq $curl->{senddata}, "Data part match\n");
}

sub setup_env
{
    $pid = fork();

    # Simulate an HTTP server otherwise curl will not generate any output
    if ($pid == 0) {
        my $client;
        $SIG{'TERM'} = sub {
            close($client);
            exit(0);
        };

        my $server = IO::Socket::INET->new( LocalHost => '127.0.0.1',
                                            LocalPort => $port, Proto => 'TCP',
                                            Reuse => 1, Listen => 50 );

        die unless $server;
        while (1) {
            $client = $server->accept();
            next unless $client;
            <$client>;
            sleep 1;
            close $client if $client;
        }
    }
}

setup_env();

my $tmpfile = "/tmp/curllogger.cookies";
copy("$FindBin::RealBin/curllogger.cookies", "$tmpfile");

# All requests to be tested
foreach ( { title => "GET with timeout",
            options => { full_url => "http://localhost:$port/fake", timeout => 10 } },
          { title => "GET with headers",
            options => { full_url => "http://localhost:$port/fake",
                         headers => [ { key => "header1", value => "valeur 1" }, { key => "header2", value => "valeur 2" } ] } },
          { title => "POST with post_params",
            options => { full_url => "http://localhost:$port/fake", method => "POST",
                         post_params => { "key 1" => "value 1", "key 2" => "value 2" } } },
          { title => "PATCH with timeout",
            options => { method => 'PATCH', full_url => "http://localhost:$port/fake", timeout => 10 } },
          { title => "DELETE with timeout",
            options => { method => 'DELETE', full_url => "http://localhost:$port/fake", timeout => 10 } },
          { title => "GET with get_params",
            options => { full_url => "http://localhost:$port/fake", get_params => [ 'para1', 'valeur1', 'para2', 'valeur2' ] } },
          { title => "GET with no_follow",
            options => { full_url => "http://localhost:$port/fake", no_follow => 1 } },
          { title => "GET with cookies_file",
            options => { full_url => "http://localhost:$port/fake", cookies_file => $tmpfile },
            contains => [ '--cookie-jar' ] },
          { title => "POST with query_form_post",
            options => { full_url => "http://localhost:$port/fake", query_form_post => "une data",
                         headers => [ { key => "header1", value => "valeur 1" }, { key => "content-type", value => "text/html" } ] } },
          { title => "GET with cert",
            options => { full_url => "http://localhost:$port/fake", insecure => 1, cacert_file => '/tmp/ca-fake.crt',
                         cert_file => '/tmp/cert-fake.crt', key_file => '/tmp/key-fake.pem', cert_pwd => 't@t@' },
                         contains => [ '--insecure', '--cert', '--cacert' , '--key', '--pass', ] },
          { title => "GET with pkcs12",
            options => { full_url => "http://localhost:$port/fake", cert_pkcs12 => 'P12' },
            contains => [ '--cert-type' ]  },
          { title => "GET with proxyurl",
            options => { full_url => "http://localhost:$port/fake", proxyurl => "http://localhost:$port" } },
          { title => "GET with authent basic",
            options => { full_url => "http://localhost:$port/fake", credentials => 1, basic => 1, username => 'User',
                         password => 'Pa$$w@rd' },
            contains => [ '--basic' ] },
          { title => "GET with authent ntlmv2",
            options => { full_url => "http://localhost:$port/fake", credentials => 1, ntlmv2 => 1, username => 'User',
                         password => 'Pa$$w@rd' },
            contains => [ '--ntlm' ] },
          { title => "GET with authent digest",
            options => { full_url => "http://localhost:$port/fake", credentials => 1, digest => 1, username => 'User',
                         password => 'Pa$$w@rd' },
            contains => [ '--digest' ] },
          { title => "GET with authent anyauth",
            options => { full_url => "http://localhost:$port/fake", credentials => 1, username => 'User',
                         password => 'Pa$$w@rd' },
            contains => [ '--anyauth' ] },
          { title => "POST with form",
            options => { full_url => "http://localhost:$port/fake", method => "POST",
                         form => [ { copyname => 'part 1', copycontents => 'content 1' },  { copyname => 'part 2',
                         copycontents => 'content 2' }, ] } },
) {
    test_full($_->{title}, $_->{contains} // '', %{$_->{options}});
}

# This test is skipped if the platform does not support CURLOPT_AWS_SIGV4 ( libcurl >= 7.75.0 required ).
SKIP: {
    my $test = { title => "GET with curl_opt",
            options => { full_url => "http://fake.execute-api.eu-west-1.amazonaws.com:$port/fake", credentials => 1,
                         username => 'User', http_peer_addr => "127.0.0.1",
                         password => 'Pa$$w@rd' , curl_opt => [ "CURLOPT_AWS_SIGV4 => osc" ] } };

    eval "CURLOPT_AWS_SIGV4";
    if ($@) {
        print "test ".$test->{title}."\n";
        skip "CURLOPT_AWS_SIGV4 is unsupported on this platform", 5;
    }

    test_full($test->{title}, $test->{contains} // '', %{$test->{options}});
};

unlink $tmpfile;

kill 'TERM', $pid;
waitpid ($pid, 0);

done_testing();
