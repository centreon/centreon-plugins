#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package notification::ovhsms::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use Data::Dumper qw(Dumper);

my $ovh_url='https://www.ovh.com/cgi-bin/sms/http2sms.cgi';


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "account:s"   => { name => 'account' },
                                  "username:s"      => { name => 'username' },
                                  "password:s"      => { name => 'password' },
                                  "phonenumber:s"   => { name => 'phonenumber' },
                                  "message:s"       => { name => 'message' },
                                  "nostop:s"        => { name => 'nostop',default => 1 },
                                  "from:s"          => { name => 'from'},
                                  "class:s"        => { name => 'class' ,default => 1 },
                                  "proxyurl:s"      => { name => 'proxyurl' },
                                  "proxypac:s"      => { name => 'proxypac' },
                                  "timeout:s"       => { name => 'timeout' },
                                  "ssl-opt:s@"      => { name => 'ssl_opt' },
                                });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;
}


sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
    if ((!defined($self->{option_results}->{username}) && !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{account})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --account option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{phonenumber})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --phonenumber option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}}, hostname => 'dummy');

}

sub run {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml');
    $self->{http}->add_header(key => 'Accept', value => 'text/xml');

    my $sms_arg={};

    $sms_arg->{account} = $self->{option_results}->{account};
    $sms_arg->{login} = $self->{option_results}->{username};
    $sms_arg->{password} = $self->{option_results}->{password};
    $sms_arg->{to} = $self->{option_results}->{phonenumber};
    $sms_arg->{noStop} = $self->{option_results}->{nostop};
    $sms_arg->{class} = $self->{option_results}->{class};
    $sms_arg->{from} = $self->{option_results}->{from};
    $sms_arg->{message} = $self->{option_results}->{message};


    my $url = $ovh_url;
    print Dumper($sms_arg);
    my $response = $self->{http}->request(full_url => $url,  get_params =>$sms_arg, method => 'GET');

    $self->{output}->output_add(short_msg => 'push_id : ' . $response);
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send SMS with OVH API.

=over 6

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--account>

Specify SMS Account for API authentification.

=item B<--username>

Specify username for API authentification.

=item B<--password>

Specify password for API authentification.

=item B<--timeout>

Threshold for HTTP timeout

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=item B<--phonenumber>

Specify phone number (format 00336xxxx for French Number)

=item B<--message>

Specify the message to send.

=item B<--sender>

Specify the sender Name . It is mandatory to create it before on OVH Console.

=back

=cut
