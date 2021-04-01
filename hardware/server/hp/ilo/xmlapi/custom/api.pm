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

package hardware::server::hp::ilo::xmlapi::custom::api;

use strict;
use warnings;
use IO::Socket::SSL;
use XML::Simple;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {                      
            'hostname:s' => { name => 'hostname' },
            'timeout:s'  => { name => 'timeout', default => 30 },
            'port:s'     => { name => 'port', default => 443 },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'force-ilo3' => { name => 'force_ilo3' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'XML API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{username}) || $self->{option_results}->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Need to set password option.");
        $self->{output}->option_exit();
    }
 
    $self->{ssl_opts} = '';
    if (!defined($self->{option_results}->{ssl_opt})) {
        $self->{option_results}->{ssl_opt} = ['SSL_verify_mode => SSL_VERIFY_NONE'];
        $self->{ssl_opts} = 'SSL_verify_mode => SSL_VERIFY_NONE';
    } else {
        foreach (@{$self->{option_results}->{ssl_opt}}) {
            $self->{ssl_opts} .= "$_, ";
        }
    }
    if (!defined($self->{option_results}->{curl_opt})) {
        $self->{option_results}->{curl_opt} = ['CURLOPT_SSL_VERIFYPEER => 0', 'CURLOPT_SSL_VERIFYHOST => 0'];
    }

    $self->{http}->set_options(%{$self->{option_results}});
    return 0;
}

sub find_ilo_version {
    my ($self, %options) = @_;
    
    ($self->{ilo2}, $self->{ilo3}) = (0, 0);
    my $client = new IO::Socket::SSL->new(PeerAddr => $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port}, 
                                          eval $self->{ssl_opts}, Timeout => $self->{option_results}->{timeout});
    if (!$client) {
        $self->{output}->add_option_msg(short_msg => "Failed to establish SSL connection: $!, ssl_error=$SSL_ERROR");
        $self->{output}->option_exit();
    }
    
    print $client 'POST /ribcl HTTP/1.1' . "\r\n";
    print $client "HOST: me" . "\r\n";                      # Mandatory for http 1.1
    print $client "User-Agent: locfg-Perl-script/3.0\r\n";
    print $client "Content-length: 30" . "\r\n";            # Mandatory for http 1.1
    print $client 'Connection: Close' . "\r\n";             # Required
    print $client "\r\n";                                   # End of http header
    print $client "<RIBCL VERSION=\"2.0\"></RIBCL>\r\n";    # Used by Content-length
    my $ln = <$client>;
    if ($ln =~ m/HTTP.1.1 200 OK/) {
        $self->{ilo3} = 1;
    } else {
        $self->{ilo2} = 1;
    }
    close $client;
}

sub get_ilo2_data {
    my ($self, %options) = @_;

    my $client = new IO::Socket::SSL->new(PeerAddr => $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port}, 
                                          eval $self->{ssl_opts}, Timeout => $self->{option_results}->{timeout});
    if (!$client) {
        $self->{output}->add_option_msg(short_msg => "Failed to establish SSL connection: $!, ssl_error=$SSL_ERROR");
        $self->{output}->option_exit();
    }
    print $client '<?xml version="1.0"?>' . "\r\n";
    print $client '<RIBCL VERSION="2.21">' . "\r\n";
    print $client '<LOGIN USER_LOGIN="' . $self->{option_results}->{username} . '" PASSWORD="' . $self->{option_results}->{password} . '">' . "\r\n";
    print $client '<SERVER_INFO MODE="read">' . "\r\n";
    print $client '<GET_EMBEDDED_HEALTH />' . "\r\n";
    print $client '</SERVER_INFO>' . "\r\n";
    print $client '</LOGIN>' . "\r\n";
    print $client '</RIBCL>' . "\r\n";

    while (my $line = <$client>) {
        $self->{content} .= $line;
    }
    close $client;
}

sub get_ilo3_data {
    my ($self, %options) = @_;

    my $xml_script = "<RIBCL VERSION=\"2.21\">
   <LOGIN USER_LOGIN=\"$self->{option_results}->{username}\" PASSWORD=\"$self->{option_results}->{password}\">
      <SERVER_INFO MODE=\"read\">
         <GET_EMBEDDED_HEALTH />
      </SERVER_INFO>
   </LOGIN>
</RIBCL>
";

    $self->{http}->add_header(key => 'TE', value => 'chunked');
    $self->{http}->add_header(key => 'Connection', value => 'Close');
    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml');
    
    $self->{content} = $self->{http}->request(
        method => 'POST', proto => 'https', url_path => '/ribcl',
        query_form_post => $xml_script,
    );
}

sub check_ilo_error {
    my ($self, %options) = @_;
    
    # Looking for:
    #    <RESPONSE
    #        STATUS="0x005F"
    #         MESSAGE='Login credentials rejected.'
    #        />
    while ($self->{content} =~ /<response[^>]*?status="0x(.*?)"[^>]*?message='(.*?)'/msig) {
        my ($status_code, $message) = ($1, $2);
        if ($status_code !~ /^0+$/) {
            $self->{output}->add_option_msg(short_msg => "Cannot get data: $2");
            $self->{output}->option_exit();
        }
    }
}

sub change_shitty_xml {
    my ($self, %options) = @_;
    
    # Can be like that the root <RIBCL VERSION="2.22" /> ???!!
    $options{response} =~ s/<RIBCL VERSION="(.*?)"\s*\/>/<RIBCL VERSION="$1">/mg;
    # ILO2 can send:
    # <DRIVES>
    #  <Backplane firmware version="Unknown", enclosure addr="224"/>
    #   <Drive Bay: "1"; status: "Ok"; uid led: "Off">
    #   <Drive Bay: "2"; status: "Ok"; uid led: "Off">
    #   <Drive Bay: "3"; status: "Not Installed"; uid led: "Off">
    #   <Drive Bay: "4"; status: "Not Installed"; uid led: "Off">
    #  <Backplane firmware version="1.16own", enclosure addr="226"/>
    #   <Drive Bay: "5"; status: "Not Installed"; uid led: "Off">
    #   <Drive Bay: "6"; status: "Not Installed"; uid led: "Off">
    #   <Drive Bay: "7"; status: "Not Installed"; uid led: "Off">
    #   <Drive Bay: "8"; status: "Not Installed"; uid led: "Off">
    # </DRIVES>
    $options{response} =~ s/<Backplane firmware version="(.*?)", enclosure addr="(.*?)"/<BACKPLANE FIRMWARE_VERSION="$1" ENCLOSURE_ADDR="$2"/mg;
    $options{response} =~ s/<Drive Bay: "(.*?)"; status: "(.*?)"; uid led: "(.*?)">/<DRIVE_BAY NUM="$1" STATUS="$2" UID_LED="$3" \/>/mg;

    #Other shitty xml:
    #  <BACKPLANE>
    #    <ENCLOSURE_ADDR VALUE="224"/>
    #    <DRIVE_BAY VALUE = "1"/>
    #      <PRODUCT_ID VALUE = "EG0300FCVBF"/>
    #      <STATUS VALUE = "Ok"/>
    #      <UID_LED VALUE = "Off"/>
    #    <DRIVE_BAY VALUE = "2"/>
    #      <PRODUCT_ID VALUE = "EH0146FARUB"/>
    #      <STATUS VALUE = "Ok"/>
    #      <UID_LED VALUE = "Off"/>
    #    <DRIVE_BAY VALUE = "3"/>
    #      <PRODUCT_ID VALUE = "EH0146FBQDC"/>
    #      <STATUS VALUE = "Ok"/>
    #      <UID_LED VALUE = "Off"/>
    #    <DRIVE_BAY VALUE = "4"/>
    #      <PRODUCT_ID VALUE = "N/A"/>
    #      <STATUS VALUE = "Not Installed"/>
    #      <UID_LED VALUE = "Off"/>
    # </BACKPLANE>
    $options{response} =~ s/<DRIVE_BAY\s+VALUE\s*=\s*"(.*?)".*?<STATUS\s+VALUE\s*=\s*"(.*?)".*?<UID_LED\s+VALUE\s*=\s*"(.*?)".*?\/>/<DRIVE_BAY NUM="$1" STATUS="$2" UID_LED="$3" \/>/msg;

    # 3rd variant, known as the ArnoMLT variant
    # <BACKPLANE>
    #   <FIRMWARE VERSION="1.16"/>
    #   <ENCLOSURE ADDR="224"/>
    #   <DRIVE BAY="1"/>
    #     <PRODUCT ID="EG0300FCVBF"/>
    #     <DRIVE_STATUS VALUE="Ok"/>
    #     <UID LED="Off"/>
    #   <DRIVE BAY="2"/>
    #     <PRODUCT ID="EH0146FARUB"/>
    #     <DRIVE_STATUS VALUE="Ok"/>
    #     <UID LED="Off"/>
    #   <DRIVE BAY="3"/>
    #     <PRODUCT ID="EH0146FBQDC"/>
    #     <DRIVE_STATUS VALUE="Ok"/>
    #     <UID LED="Off"/>
    #   <DRIVE BAY="4"/>
    #     <PRODUCT ID="N/A"/>
    #     <DRIVE_STATUS VALUE="Not Installed"/>
    #     <UID LED="Off"/>
    # </BACKPLANE>
    $options{response} =~ s/<FIRMWARE\s+VERSION\s*=\s*"(.*?)".*?<ENCLOSURE\s+ADDR\s*=\s*"(.*?)".*?\/>/<BACKPLANE FIRMWARE_VERSION="$1" ENCLOSURE_ADDR="$2"/mg;
    $options{response} =~ s/<DRIVE\s+BAY\s*=\s*"(.*?)".*?<DRIVE_STATUS\s+VALUE\s*=\s*"(.*?)".*?<UID\s+LED\s*=\s*"(.*?)".*?\/>/<DRIVE_BAY NUM="$1" STATUS="$2" UID_LED="$3" \/>/msg;

    return $options{response};
}

sub get_ilo_response {
    my ($self, %options) = @_;
    
    # ilo result is so shitty. We get the good result from size...
    my ($length, $response) = (0, '');
    foreach (split /<\?xml.*?\?>/, $self->{content}) {
        if (length($_) > $length) {
            $response = $_;
            $length = length($_);
        }
    }
    
    $response = $self->change_shitty_xml(response => $response);
    my $xml_result;
    eval {
        $xml_result = XMLin($response, 
            ForceArray => ['FAN', 'TEMP', 'MODULE', 'SUPPLY', 'PROCESSOR', 'NIC', 
                           'SMART_STORAGE_BATTERY', 'CONTROLLER', 'DRIVE_ENCLOSURE', 
                           'LOGICAL_DRIVE', 'PHYSICAL_DRIVE', 'DRIVE_BAY', 'BACKPLANE']);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    return $xml_result;
}

sub get_ilo_data {
    my ($self, %options) = @_;
    
    $self->{content} = '';
    
    if (!defined($self->{option_results}->{force_ilo3})) {
        $self->find_ilo_version();
    } else {
        $self->{ilo3} = 1;
    }
    
    if ($self->{ilo3} == 1) {
        $self->get_ilo3_data();
    } else {
        $self->get_ilo2_data();
    }
        
    $self->{content} =~ s/\r//sg;
    $self->{output}->output_add(long_msg => $self->{content}, debug => 1);
    
    $self->check_ilo_error();
    return $self->get_ilo_response();
}

1;

__END__

=head1 NAME

ILO API

=head1 SYNOPSIS

ilo api

=head1 XML API OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--username>

ILO username.

=item B<--password>

ILO password.

=item B<--port>

ILO Port (Default: 443).

=item B<--timeout>

Set timeout (Default: 30).

=item B<--force-ilo3>

Don't try to find ILO version.

=back

=head1 DESCRIPTION

B<custom>.

=cut
