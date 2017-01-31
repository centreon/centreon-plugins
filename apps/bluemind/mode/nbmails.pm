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

package apps::bluemind::mode::nbmails;

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
                                  "port:s"                  => { name => 'port', default => 9200 },
                                  "proto:s"                 => { name => 'proto', default => 'http' },
                                  "username:s"              => { name => 'username' },
                                  "password:s"              => { name => 'password' },
                                  "domainUid:s"             => { name => 'domainUid' },
                                  "warning:s"               => { name => 'warning'},
                                  "critical:s"              => { name => 'critical'},
                                });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;
}


sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname}))
    {
        $self->{output}->add_option_msg(short_msg => "You need to set --hostname option");
        $self->{output}->option_exit();
    }

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

    if ((!defined($self->{option_results}->{warning}) || !defined($self->{option_results}->{critical})))
    {
        $self->{output}->add_option_msg(short_msg => "Please set --warning= and --critical= option");
        $self->{output}->option_exit();
    }



    $self->{http}->set_options(%{$self->{option_results}});

}



sub run {
    my ($self, %options) = @_;

    my $url_path='/mailspool/msg/';

    my $jsoncontent = $self->{http}->request(full_url => $self->{option_results}->{proto}
                                            . '://'
                                            . $self->{option_results}->{hostname}
                                            . ':'
                                            . $self->{option_results}->{port}
                                            . $url_path
                                            . '_count',
                                            method => 'GET');

   my $json = JSON->new;

   my $webcontent = $json->decode($jsoncontent);

   my $mails=$webcontent->{'count'};


   my $severity='OK';

   if ($mails>=$self->{option_results}->{critical})
   {

      $severity='Critical';

   }
    else
     {

       if ($mails>=$self->{option_results}->{warning})

        {

         if ($severity ne 'Critical')

          {

                $severity='Warning';

          }

        }

     }



    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    my $password='"'.$self->{option_results}->{password}.'"';

    my $url_path2='/api/auth/login?login='.$self->{option_results}->{username};

    my $jsoncontent2 = $self->{http}->request(full_url => 'https'
                                            . '://'
                                            . $self->{option_results}->{hostname}
                                            . $url_path2,
                                            method => 'POST',
                                            query_form_post =>$password);


    my $json2 = JSON->new;

    my $authKey = $json2->decode($jsoncontent2);


    $self->{http}->add_header(key => 'X-BM-ApiKey', value => $authKey->{'authKey'});


    my $jsoncontent3 = $self->{http}->request(full_url => 'https'
                                               . '://'
                                               . $self->{option_results}->{hostname}
                                               . '/api/mailboxes/'
                                               . $self->{option_results}->{domainUid}
                                               . '/_list',
                                               method => 'GET');


    my $json3 = JSON->new;

    my $list = $json3->decode($jsoncontent3);


    my $email;


    my $jsoncontent4;
    my $json4;

    my $key;

    my $jsoncontent5;
    my $json5;

    my $unread;
    my $unreads_mails=0;

    foreach my $item(@$list)
    {

     if (defined $item->{'value'}{'emails'}[0])
     {

       $email=$item->{'value'}{'emails'}[0]{'address'};


       $self->{http}->add_header(key => 'X-BM-ApiKey', value => $authKey->{'authKey'}); #AuthKey admin pour requete POST suivante


       $jsoncontent4 = $self->{http}->request(full_url => 'https'
                                              . '://'
                                              . $self->{option_results}->{hostname}
                                              . '/api/auth/_su?login='
                                              . $email
                                              , method => 'POST');


       $json4 = JSON->new;

       $key=$json4->decode($jsoncontent4);

       $self->{http}->add_header(key => 'X-BM-ApiKey', value => $key->{'authKey'}); #AuthKey email utilisateur

       $jsoncontent5 = $self->{http}->request(full_url => 'https'
                                                . '://'
                                                . $self->{option_results}->{hostname}
                                                . '/api/mailboxes/'
                                                . $self->{option_results}->{domainUid}
                                                . '/_unread',
                                                 method => 'GET');


       $json5 = JSON->new;

       $unread = $jsoncontent5;

       $unreads_mails = $unread+$unreads_mails;

    }
   }

   my $reads_mails= $mails-$unreads_mails;


   $self->{output}->output_add(severity  => $severity,
                               short_msg => $mails.' '.'e-mails messages on server');



   $self->{output}->perfdata_add(label    => 'total_emails',
                                 value    => $mails);

   $self->{output}->perfdata_add(label    => 'reads_emails',
                                 value    => $reads_mails);


   $self->{output}->perfdata_add(label    => 'unreads_emails',
                                 value    => $unreads_mails);


   $self->{output}->display();
   $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check total number of emails and read/unreads emails on your Bluemind server.

=over 6

=item B<--hostname>

IP Addr/FQDN of the Bluemind host.

=item B<--port>

Port used by Elasticsearch. (Default: 9200)

=item B<--proto>

Specify http or https protocol. (Default: http)

=item B<--domainUid>

Specify your Bluemind domain name.

=item B<--username>

Specify ADMIN username for API authentification.

=item B<--password>

Specify ADMIN password for API authentification.

=item B<--warning>

Threshold warning. (Number of mails permitted on your server)

=item B<--critical>

Threshold critical. (Maximum number of mails on your server)

=back

=cut

