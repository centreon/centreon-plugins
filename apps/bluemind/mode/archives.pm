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


package apps::bluemind::mode::archives;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use Data::Dumper;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;


    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"              => { name => 'hostname' },
                                  "port:s"                  => { name => 'port', default => 443 },
                                  "proto:s"                 => { name => 'proto', default => 'https' },
                                  "credentials"             => { name => 'credentials' },
                                  "username:s"              => { name => 'username' },
                                  "password:s"              => { name => 'password' },
                                  "domainUid:s"             => { name => 'domainUid' },
                                });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ((!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password})))
    {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{domainUid}))
    {
        $self->{output}->add_option_msg(short_msg => "Please set the --domainUid option");
        $self->{output}->option_exit();
    }


    $self->{http}->set_options(%{$self->{option_results}});

}

sub run {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    my $password='"'.$self->{option_results}->{password}.'"';

    my $url_path='/api/auth/login?login='.$self->{option_results}->{username};

    my $jsoncontent = $self->{http}->request(full_url => $self->{option_results}->{proto}
                                            . '://'
                                            . $self->{option_results}->{hostname}
                                            . $url_path,
                                            method => 'POST',
                                            query_form_post =>$password);



    my $json = JSON->new;

    my $webcontent = $json->decode($jsoncontent);


    $self->{http}->add_header(key => 'X-BM-ApiKey', value => $webcontent->{'authKey'});

    my $jsoncontent2 = $self->{http}->request(full_url => $self->{option_results}->{proto}
                                               . '://'
                                               . $self->{option_results}->{hostname}
                                               .'/api/users/'
                                               . $self->{option_results}->{domainUid}
                                               . '/_alluids',
                                               method => 'GET');


   my $json2 = JSON->new;

   my $webcontent2 = $json2->decode($jsoncontent2);

   my $jsoncontent3;

   my $somme=0;


   foreach my $item(@$webcontent2)
   {

     if ($item ne 'bmhiddensysadmin')
     {

      $jsoncontent3 = $self->{http}->request(full_url => $self->{option_results}->{proto}
                                             . '://'
                                             . $self->{option_results}->{hostname}
                                             . '/api/hsm/'
                                             . $self->{option_results}->{domainUid}
                                             . '/_getSize/'
                                             . $item,
                                             method => 'GET');
      $somme=$somme+$jsoncontent3;
     }
   }

     $self->{output}->output_add(severity  => 'OK',
                                 short_msg => 'Archives size :'.' '.$somme.'B');

     $self->{output}->perfdata_add(label    => 'server_archives_size',
                                   value    => $somme,
                                   unit     => 'B');

     $self->{output}->display();
     $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check archives size of your Bluemind server.

=over 6 

=item B<--hostname>

IP Addr/FQDN of the Bluemind host.

=item B<--port>

Port used by Bluemind API. (Default: 443)

=item B<--proto>

Specify http or https protocol. (Default: https)

=item B<--domainUid>

Specify your Bluemind domain name.

=item B<--username>

Specify username for API authentification.

=item B<--password>

Specify password for API authentification.

=back

=cut


