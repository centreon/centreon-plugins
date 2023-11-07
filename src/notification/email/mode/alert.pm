#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package notification::email::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use MIME::Base64;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use JSON::XS;
use URI::Escape;
use centreon::plugins::http;

my %color_host = (
    up => { 
        background => '#88B922',
        text => '#FFFFFF' 
    },
    down => { 
        background => '#FF4A4A', 
        text => '#FFFFFF' 
    },
    unreachable => { 
        background => '#E0E0E0', 
        text => '#666666' 
    },
    acknowledgement => { 
        background => '#F5F1E9', 
        text => '#666666'
    },
    downtimestart => { 
        background => '#F0E9F8', 
        text => '#666666' 
    },
    downtimeend => { 
        background => '#F0E9F8', 
        text => '#666666'
    },
    downtimecanceled => { 
        background => '#F0E9F8', 
        text => '#666666'
    }
);

my %color_service = (
    ok => {
        background => '#88B922',
        text => '#FFFFFF'
    },
    warning => {
        background => '#FD9B27',
        text => '#FFFFFF'
    },
    critical => {
        background => '#FF4A4A',
        text => '#FFFFFF'
    },
    unknown => {
        background => '#E0E0E0',
        text => '#FFFFFF'
    },
    acknowledgement => {
        background => '#F5F1E9',
        text => '#666666'
    },
    downtimestart => {
        background => '#F0E9F8',
        text => '#666666'
    },
    downtimeend => {
        background => '#F0E9F8',
        text => '#666666'
    },
    downtimecanceled => {
        background => '#F0E9F8',
        text => '#666666'
    }
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'smtp-address:s'         => { name => 'smtp_address' },
        'smtp-port:s'            => { name => 'smtp_port', default => '25' },
        'smtp-user:s'            => { name => 'smtp_user', default => undef },
        'smtp-password:s'        => { name => 'smtp_password' },
        'smtp-nossl'             => { name => 'no_ssl' },
        'smtp-debug'             => { name => 'smtp_debug' },
        'to-address:s'           => { name => 'to_address' },
        'from-address:s'         => { name => 'from_address' },
        'host-id:s'              => { name => 'host_id' },
        'host-address:s'         => { name => 'host_address'},
        'host-name:s'            => { name => 'host_name' },
        'host-alias:s'           => { name => 'host_alias'},
        'host-state:s'           => { name => 'host_state' },
        'host-output:s'          => { name => 'host_output' },
        'host-attempts:s'        => { name => 'host_attempts'},
        'max-host-attempts:s'    => { name => 'max_host_attempts'},
        'host-duration:s'        => { name => 'host_duration' },
        'service-id:s'           => { name => 'service_id' },
        'service-description:s'  => { name => 'service_description' },
        'service-state:s'        => { name => 'service_state' },
        'service-output:s'       => { name => 'service_output' },
        'service-longoutput:s'   => { name => 'service_longoutput' },
        'service-attempts:s'     => { name => 'service_attempts'},
        'max-service-attempts:s' => { name => 'max_service_attempts'},
        'service-duration:s'     => { name => 'service_duration' },
        'centreon-url:s'         => { name => 'centreon_url' },
        'centreon-user:s'        => { name => 'centreon_user' },
        'centreon-token:s'       => { name => 'centreon_token' },
        'date:s'                 => { name => 'date' },
        'notif-author:s'         => { name => 'notif_author'},
        'notif-comment:s'        => { name => 'notif_comment' },
        'type:s'                 => { name => 'type' },
        'timeout:s'              => { name => 'timeout', default => 10 }
    });

    $self->{payload_attachment} = { 'subject' => undef, 'alt_message' => undef, 'html_message' => undef , 'png' => undef }; 

    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{to_address}) || $self->{option_results}->{to_address} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --to-address option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --host-name option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{smtp_address}) || $self->{option_results}->{smtp_address} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --smtp-address option.");
        $self->{output}->option_exit();
    }

    $self->{smtp_ssl} = defined($self->{option_results}->{no_ssl}) ? 0 : 'starttls';
    $self->{smtp_debug} = defined($self->{option_results}->{smtp_debug}) ? 1 : 0;
    $self->{smtp_user} = defined($self->{option_results}->{smtp_user}) && $self->{option_results}->{smtp_user} ne '' 
        ? $self->{option_results}->{smtp_user} : '';
    $self->{smtp_password} = defined($self->{option_results}->{smtp_password}) && $self->{option_results}->{smtp_password} ne '' 
        ? $self->{option_results}->{smtp_password} : '';

    $self->{http}->set_options(%{$self->{option_results}});
}

sub host_message {
    my ($self, %options) = @_;
    
    my $host_id = $self->{option_results}->{host_id};

    my $details = {
        id => $host_id,
        resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id",
        tab => "details"
    };

    my $author_html = '';
    my $author_alt = '';
    my $comment_html = '';
    my $comment_alt = '';
    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Scheduled Downtime by:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif ($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Acknowledged Author:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Acknowledged Author: ' . $self->{option_results}->{notif_author};
        } elsif ($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Flapping Author:</h4>
                    <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Flapping Author: ' . $self->{option_results}->{notif_author};
        }
    }

    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        if ($self->{option_results}->{type} =~ /^downtime.*$/i){
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Scheduled Downtime Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif ($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Acknowledged Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif ($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Flapping Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Flapping Comment: ' . $self->{option_results}->{notif_comment};
        }
    }

    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);

    $self->{payload_attachment}->{subject} = '*** ' . $self->{option_results}->{type} . ' : Host: ' . $self->{option_results}->{host_name} . ' ' . $self->{option_results}->{host_state} . ' ***';
    $self->{payload_attachment}->{alt_message} = '
        ***** Centreon *****

        Notification Type: ' . $self->{option_results}->{type} . '
        Hostname: ' . $self->{option_results}->{host_name} . '
        Hostalias: ' . $self->{option_results}->{host_alias} . '
        State: ' . $self->{option_results}->{host_state} . '
        Address: ' . $self->{option_results}->{host_address} . '
        Date/Time: ' . $self->{option_results}->{date};

    if(defined($author_alt) && $author_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "\n        " . $author_alt . "\n";
    }
    if(defined($comment_alt) && $comment_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "        " . $comment_alt . "\n";
    }
    $self->{payload_attachment}->{alt_message} .= '

        Info:
        ' .$self->{option_results}->{host_output};

    $self->{payload_attachment}->{html_message} = '
    <!DOCTYPE html>
    <html lang="en">
    <head>
	    <meta charset="utf-8">
	    <title>' . $self->{option_results}->{host_name} . '</title>
	    <meta name="description" content="Centreon Email Notification Alert">
	    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="x-apple-disable-message-reformatting">

        <style type="text/css">
	    html,body {
		    margin: 0 auto !important;
		    padding: 0 !important;
		    height: 100% !important;
		    width: 100% !important;
		    background-color: #F2F2F2;
	    }
	
	    * {
		    -ms-text-size-adjust: 100%;
		    -webkit-text-size-adjust: 100%;
	    }
	
	    div[style*="margin: 16px 0"] {
    		margin:0 !important;
	    }
	
	    table,td {
		    mso-table-lspace: 0pt !important;
		    mso-table-rspace: 0pt !important;
	    }
	
	    table {
		    border-spacing: 0 !important;
		    border-collapse: collapse !important;
		    table-layout: fixed !important;
		    margin: 0 auto !important;
	    }
	
	    table table table {
		    table-layout: auto;
	    }
	
	    img {
    		-ms-interpolation-mode:bicubic;
    	}
	
    	*[x-apple-data-detectors],/* iOS */
    	    .x-gmail-data-detectors,/* Gmail */
    	    .x-gmail-data-detectors *,
    	.aBn {
		    border-bottom: 0 !important;
		    cursor: default !important;
		    color: inherit !important;
		    text-decoration: none !important;
		    font-size: inherit !important;
		    font-family: inherit !important;
		    font-weight: inherit !important;
		    line-height: inherit !important;
	    }
	
	    .a6S {
		    display: none !important;
		    opacity: 0.01 !important;
	    }
	
	    img.g-img + div {
    		display:none !important;
    	}
	
    	.button-link {
	    	text-decoration: none !important;
	    }
	
	    @media only screen and (min-device-width: 375px) and (max-device-width: 413px) { /* iPhone 6 and 6+ */
    		.email-container {
			    min-width: 375px !important;
		    }
	    }
	
	    .button-td,.button-a {
    		transition: all 100ms ease-in;
    	}
	
	    .button-td:hover,.button-a:hover {
    		background: #555555 !important;
		    border-color: #555555 !important;
	    }
	
	    @media screen and (max-width: 600px) {
    		.email-container p {
			    font-size: 17px !important;
			    line-height: 22px !important;
		    }
	    }
    </style>

    <!--[if gte mso 9]>
    <xml>
	    <o:OfficeDocumentSettings>
		    <o:AllowPNG/>
		    <o:PixelsPerInch>96</o:PixelsPerInch>
	    </o:OfficeDocumentSettings>
    </xml>
    <![endif]-->

    <!--[if mso]>
    <style type="text/css">
    	* {
		    font-family: sans-serif !important;
	    }
    </style>
    <![endif]-->
    </head>
    <body width="100%" bgcolor="#f6f6f6" style="margin: 0;line-height:1.4;padding:0;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;">
        <center style="width: 100%; background: #f6f6f6; text-align: left;">

                <div style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;font-family: sans-serif;">
                        [' .$self->{option_results}->{type} . '] Host: ' . $self->{option_results}->{host_alias} . ' (' . $self->{option_results}->{host_name} . ') is ' . $self->{option_results}->{host_state} . '. ***************************************************************************************************************************************
                </div>

                <div style="max-width: 600px; padding: 10px 0; margin: auto;" class="email-container">
                        <!--[if mso]>
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center">
                        <tr>
                        <td>
                        <![endif]-->

                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="95%" style="max-width: 600px;">
                                <tr>
                                        <td bgcolor="#ffffff" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
            <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" align="center" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                <tbody>
                  <tr>
                    <td style="background-color:#255891;">
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#ffffff; text-align:center;">Centreon Notification</h2>
                    </td>
                  </tr>
                  <tr>';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_host{lc($self->{option_results}->{host_state})}->{background} . ';">
                                                        <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; padding:0; margin:10px; color:' . $color_host{lc($self->{option_results}->{host_state})}->{text} . '; text-align:center;">';
    } else{
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_host{lc($self->{option_results}->{type})}->{background} . ';">
                                                        <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; padding:0; margin:10px; color:' . $color_host{lc($self->{option_results}->{host_state})}->{text} . '; text-align:center;">';
    }

    $self->{payload_attachment}->{html_message} .= $self->{option_results}->{type} . '</h1>
                    </td>
                  </tr>
                </tbody>
            </table>
            <table border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;border-left-style: solid;border-right-style: solid;border-color: #d3d3d3;border-width: 1px;">
              <td style="font-size:16px;vertical-align:top;">&nbsp;</td>
                <tbody>
                  <tr>
                    <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                      <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:right; padding-right:5%;">' . $self->{option_results}->{host_attempts} . '/' . $self->{option_results}->{max_host_attempts} . '</h5>
                      <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; text-align:center; text-decoration:underline;">Host:</h4>
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:26px; text-align:center;">' . $self->{option_results}->{host_name} . '</h2>
                      <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:center;">is</h5>
                      <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:30px; color:' . $color_host{lc($self->{option_results}->{host_state})}->{background} . ';text-align:center;">' . $self->{option_results}->{host_state} . '</h1>
                      <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:center;">for: ' . $self->{option_results}->{host_duration} . '</h5>
                    </td>
                  </tr>
                </tbody>
                <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                <tbody>
                  <tr>
                    <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                      <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%; text-decoration:underline;">Host Alias:</h4>
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{host_alias} . '</h2>
                    </td>
                  </tr>
                </tbody>
                <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                <tbody>
                  <tr>
                    <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                      <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Host Address:</h4>
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{host_address} . '</h2>
                    </td>
                  </tr>
                </tbody>
                <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                <tbody>
                  <tr>
                    <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                      <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Date:</h4>
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{date} . '</h2>
                    </td>
                  </tr>
                </tbody>
                <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                <tbody>
                  <tr>
                    <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                      <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Status Information:</h4>
                      <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{host_output} . '</h2>
                    </td>
                  </tr>
                </tbody>';
    if (defined($author_html) && $author_html ne '') {
        $self->{payload_attachment}->{html_message} .= '
                    <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    <tbody>
                        <tr>
                            <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">'.
                                $author_html. '
                            </td>
                        </tr>
                    </tbody>';
    }

    if (defined($comment_html) && $comment_html ne '') {
        $self->{payload_attachment}->{html_message} .= '
                    <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    <tbody>
                        <tr>
                            <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">'.
                                $comment_html. '
                            </td>
                        </tr>
                    </tbody>';
    }

    $self->{payload_attachment}->{html_message} .= '
              <td style="font-size:16px;vertical-align:top;">&nbsp;</td>
            </table>
            <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
              <tbody>
                <tr>';
    if ($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_host{lc($self->{option_results}->{host_state})}->{background} . '; height:10px"></td>';
    } else {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_host{lc($self->{option_results}->{type})}->{background} . '; height:10px"></td>';
    }
    $self->{payload_attachment}->{html_message} .= '
                </tr>
                <tr>
                  <td style="background-color:#255891;">';
    if (defined($self->{option_results}->{centreon_url}) && $self->{option_results}->{centreon_url} ne ''){
        $self->{payload_attachment}->{html_message} .='
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#ffffff; text-align:center;"><a href="'. $self->{option_results}->{centreon_url} .'/centreon/monitoring/resources?details=' . $encoded_data . '" style="color:#ffffff;" target="_blank">Go to Centreon</a></h2>';
    }

    $self->{payload_attachment}->{html_message} .='
                  </td>
                </tr>
              </tbody>
            </table>
                </td>
                    </tr>
                </tbody>
                </table>
                                            </td>
                                    </tr>
                            </table>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="100%" style="max-width: 680px;">
            <tr>
            <td style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; vertical-align:middle; color: #999999; text-align: center; padding: 40px 10px;width: 100%;" class="x-gmail-data-detectors">
                <br>
            </td>
            </tr>
        </table>
                            <!--[if mso]>
                            </td>
                            </tr>
                            </table>
                            <![endif]-->
                    </div>

        </center>
    </body>
    </html>
    ';
}

sub service_message {
    my ($self, %options) = @_;
    
    my $host_id = $self->{option_results}->{host_id};
    my $service_id = $self->{option_results}->{service_id};

    my $author_html = '';
    my $author_alt = '';
    my $comment_html = '';
    my $comment_alt = '';
    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Scheduled Downtime by:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Acknowledged Author:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Acknowledged Author: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $author_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Flapping Author:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_author} . '</h2>';
            $author_alt = 'Flapping Author: ' . $self->{option_results}->{notif_author};
        }
    }

    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Scheduled Downtime Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Acknowledged Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $comment_html = '<h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Flapping Comment:</h4>
                            <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{notif_comment} . '</h2>';
            $comment_alt = 'Flapping Comment: ' . $self->{option_results}->{notif_comment};
        }
    }

    my $graph_html;
    if ($self->{option_results}->{centreon_user} && $self->{option_results}->{centreon_user} ne '' 
        && $self->{option_results}->{centreon_token}  && $self->{option_results}->{centreon_token} ne '') {
        my $content = $self->{http}->request(
            hostname => '',
            full_url => $self->{option_results}->{centreon_url} . '/centreon/include/views/graphs/generateGraphs/generateImage.php?akey=' . $self->{option_results}->{centreon_token} . '&username=' . $self->{option_results}->{centreon_user} . '&hostname=' . $self->{option_results}->{host_name} . '&service='. $self->{option_results}->{service_description},
            timeout => $self->{option_results}->{timeout},
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );
        
        if ($self->{http}->get_code() !~ /200/ || $content =~ /^OK/) {
            $graph_html = '<h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">No graph</h2>';
        } elsif ($content =~ /Access denied|Resource not found|Invalid token/) {
            $graph_html = '<h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">Cannot retrieve graph: ' . $content . '</h2>';
        } else {
            $self->{payload_attachment}->{graph_png} = $content;
            $graph_html = '<img src="cid:' . $self->{option_results}->{host_name} . '_' . $self->{option_results}->{service_description} . "\" style=\"display:block; width:98%; height:auto;margin:0 10px 0 10px;\">\n";
        }
    }

    my $details = {
        id => $service_id,
        resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id/services/$service_id",
        tab => 'details'
    };

    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);

    my $line_break = '<br />';

    $self->{option_results}->{service_longoutput} =~ s/\\n/<br \/>/g;

    $self->{payload_attachment}->{subject} = '*** ' . $self->{option_results}->{type} . ' : ' . $self->{option_results}->{service_description} . ' '. $self->{option_results}->{service_state} . ' on ' . $self->{option_results}->{host_name} . ' ***';
    $self->{payload_attachment}->{alt_message} = '
    ***** Centreon *****

    Notification Type: ' . $self->{option_results}->{type} . '
    Service: ' . $self->{option_results}->{service_description} . '
    Hostname: ' . $self->{option_results}->{host_name} . '
    Hostalias: ' . $self->{option_results}->{host_alias} . '
    State: ' . $self->{option_results}->{service_state} . '
    Address: ' . $self->{option_results}->{host_address} . '
    Date/Time: ' .$self->{option_results}->{date};

    if (defined($author_alt) && $author_alt ne '') {
        $self->{payload_attachment}->{alt_message} .= "\n    " . $author_alt . "\n";
    }
    if(defined($comment_alt) && $comment_alt ne '') {
        $self->{payload_attachment}->{alt_message} .= "    " . $comment_alt . "\n";
    }
    $self->{payload_attachment}->{alt_message} .= '

    Info:
    ' . $self->{option_results}->{service_output} . '
    ' . $self->{option_results}->{service_longoutput};

    $self->{payload_attachment}->{html_message} = '
    <!DOCTYPE html>
    <html lang="en">
    <head>
	    <meta charset="utf-8">
	    <title>' . $self->{option_results}->{host_name} . ' / ' . $self->{option_results}->{service_description} .'</title>
	    <meta name="description" content="Centreon Email Notification Alert">
	    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	    <meta http-equiv="X-UA-Compatible" content="IE=edge">
	    <meta name="x-apple-disable-message-reformatting">

        <style type="text/css">
	    html,body {
		    margin: 0 auto !important;
            padding: 0 !important;
            height: 100% !important;
            width: 100% !important;
		    background-color: #F2F2F2;
        }
        
        * {
            -ms-text-size-adjust: 100%;
            -webkit-text-size-adjust: 100%;
        }
        
        div[style*="margin: 16px 0"] {
            margin:0 !important;
        }
        
        table,td {
            mso-table-lspace: 0pt !important;
            mso-table-rspace: 0pt !important;
        }
        
        table {
            border-spacing: 0 !important;
            border-collapse: collapse !important;
            table-layout: fixed !important;
            margin: 0 auto !important;
        }
        
        table table table {
            table-layout: auto;
        }
        
        img {
            -ms-interpolation-mode:bicubic;
        }
        
        *[x-apple-data-detectors],/* iOS */
        .x-gmail-data-detectors,/* Gmail */
        .x-gmail-data-detectors *,
        .aBn {
            border-bottom: 0 !important;
            cursor: default !important;
            color: inherit !important;
            text-decoration: none !important;
            font-size: inherit !important;
            font-family: inherit !important;
            font-weight: inherit !important;
            line-height: inherit !important;
        }
        
        .a6S {
            display: none !important;
            opacity: 0.01 !important;
        }
        
        img.g-img + div {
            display:none !important;
        }
        
        .button-link {
            text-decoration: none !important;
        }
        
        @media only screen and (min-device-width: 375px) and (max-device-width: 413px) { /* iPhone 6 and 6+ */
            .email-container {
                min-width: 375px !important;
            }
        }
        
        .button-td,.button-a {
            transition: all 100ms ease-in;
        }
        
        .button-td:hover,.button-a:hover {
            background: #555555 !important;
            border-color: #555555 !important;
        }
        
        @media screen and (max-width: 700px) {
            .email-container p {
                font-size: 17px !important;
                line-height: 22px !important;
            }
        }
    </style>

    <!--[if gte mso 9]>
    <xml>
        <o:OfficeDocumentSettings>
            <o:AllowPNG/>
            <o:PixelsPerInch>96</o:PixelsPerInch>
        </o:OfficeDocumentSettings>
    </xml>
    <![endif]-->

    <!--[if mso]>
    <style type="text/css">
        * {
            font-family: sans-serif !important;
        }
    </style>
    <![endif]-->
    </head>
    <body width="100%" bgcolor="#f6f6f6" style="margin: 0;line-height:1.4;padding:0;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;">
            <center style="width: 100%; background: #f6f6f6; text-align: left;">

                    <div style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;font-family: sans-serif;">[' . $self->{option_results}->{type} . '] Service: ' . $self->{option_results}->{service_description} . ' on Host: ' . $self->{option_results}->{host_name} . ' (' . $self->{option_results}->{host_alias} . ') is '. $self->{option_results}->{service_state} . '. ***************************************************************************************************************************************
                    </div>
                    <div style="padding: 10px 0; margin: auto;" class="email-container">
                            <!--[if mso]>
                            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="700" align="center">
                            <tr>
                            <td>
                            <![endif]-->

                            <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="95%" style="max-width: 700px;">
                                    <tr>
                                            <td bgcolor="#ffffff" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" align="center" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
    <tbody><tr>
                        <td bgcolor="#ffffff" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" align="center" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                    <tbody>
                    <tr>
                        <td style="background-color:#255891;">
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#ffffff; text-align:center;">Centreon Notification</h2>
                        </td>
                    </tr>
                    <tr>';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} . ';">
            <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; padding:0; margin:10px; color:'. $color_service{lc($self->{option_results}->{service_state})}->{text} .'; text-align:center;">';
    } else {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{type})}->{background} . ';">
            <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; padding:0; margin:10px; color:'. $color_service{lc($self->{option_results}->{type})}->{text} .'; text-align:center;">';
    }
    $self->{payload_attachment}->{html_message} .= $self->{option_results}->{type} . '</h1>
                        </td>
                    </tr>
                    </tbody>
                </table>
                <table border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;border-left-style: solid;border-right-style: solid;border-color: #d3d3d3;border-width: 1px;">
                <tbody><tr><td style="font-size:16px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody><tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                        <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:right; padding-right:5%;">' . $self->{option_results}->{service_attempts} . '/' . $self->{option_results}->{max_service_attempts} . '</h5>
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; text-align:center; text-decoration:underline;">Host:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:26px; text-align:center;">' . $self->{option_results}->{host_name} . '</h2>
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; text-align:center; text-decoration:underline;">Service:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:26px; text-align:center;">' . $self->{option_results}->{service_description} . '</h2>
                        <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:center;">is</h5>
                        <h1 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:30px; color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} .';text-align:center;">' . $self->{option_results}->{service_state} . '</h1>
                        <h5 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#b0b0b0; text-align:center;">for: ' . $self->{option_results}->{service_duration} . '</h5>
                        </td>
                    </tr>
                    </tbody>
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody><tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%; text-decoration:underline;">Host Alias:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{host_alias} . '</h2>
                        </td>
                    </tr>
                    </tbody>
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody><tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Host Address:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{host_address} . '</h2>
                        </td>
                    </tr>
                    </tbody>
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody><tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Date:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">' . $self->{option_results}->{date} . '</h2>
                        </td>
                    </tr>
                    </tbody>
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody><tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                        <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Status Information:</h4>
                        <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;"> ' . $self->{option_results}->{service_output} . $line_break . $self->{option_results}->{service_longoutput} . '
                        </h2>
                        </td>
                    </tr>
                    </tbody>
    ';

    if (defined($author_html) && $author_html ne '') {
        $self->{payload_attachment}->{html_message} .= '
                    <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    <tbody>
                        <tr>
                            <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">'.
                                $author_html. '
                            </td>
                        </tr>
                    </tbody>';
    }

    if (defined($comment_html) && $comment_html ne '') {
        $self->{payload_attachment}->{html_message} .= '
                    <td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    <tbody>
                        <tr>
                            <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">'.
                                $comment_html. '
                            </td>
                        </tr>
                    </tbody>';
    }

    if (defined($graph_html) && $graph_html ne '') {
        $self->{payload_attachment}->{html_message} .= '
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td></tr></tbody>
                    <tbody>
                        <tr>
                            <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                                <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Service Graph:</h4>
                                '. $graph_html . '
                            </td>
                        </tr>
                    </tbody>';
    }
                    
    $self->{payload_attachment}->{html_message} .= '
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody>
                <tbody><tr><td style="font-size:16px;vertical-align:top;">&nbsp;</td>
                </tr></tbody></table>
                
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                <tbody>
                    <tr>';
    if ($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} . '; height:10px">';
    } else {
        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{type})}->{background} . '; height:10px">';
    }
    $self->{payload_attachment}->{html_message} .= '</tr>
                    <tr>
                    <td style="background-color:#255891;">';
    if (defined($self->{option_results}->{centreon_url}) && $self->{option_results}->{centreon_url} ne '') {
        $self->{payload_attachment}->{html_message} .='
                    <h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; color:#ffffff; text-align:center;"><a href="'. $self->{option_results}->{centreon_url} .'/centreon/monitoring/resources?details=' . $encoded_data . '" style="color:#ffffff;" target="_blank">Go to Centreon</a></h2>';
    }
    $self->{payload_attachment}->{html_message} .= '
                </td>
                </tr>
                </tbody>
                </table>
                        </td>
                    </tr>
                </tbody>
                </table>
                                            </td>
                                    </tr>
                            </table>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="100%" style="max-width: 680px;">
            <tr>
            <td style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; vertical-align:middle; color: #999999; text-align: center; padding: 40px 10px;width: 100%;" class="x-gmail-data-detectors">
                <br>
            </td>
            </tr>
        </table>
                            <!--[if mso]>
                            </td>
                            </tr>
                            </table>
                            <![endif]-->
                    </div>

        </center>
    </body>
    </html>
    ';
}

sub set_payload {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '') {
        $self->service_message();
    } else {
        $self->host_message();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->set_payload();

    my $html_part = Email::MIME->create(
        attributes => {
            content_type => 'text/html',
            charset      => 'UTF-8'
        },
        body => $self->{payload_attachment}->{html_message}
    );

    my $text_part = Email::MIME->create(
        attributes => {
            content_type => 'text/plain',
            charset      => 'UTF-8'
        },
        body => $self->{payload_attachment}->{alt_message}
    );

    my $email;

    if (defined($self->{payload_attachment}->{graph_png}) && $self->{payload_attachment}->{graph_png} ne '') {
        my $graph_png_cid = $self->{option_results}->{host_name} . '_' . $self->{option_results}->{service_description};
        
        $email = Email::MIME->create(
            header_str => [
                From    => $self->{option_results}->{from_address},
                To      => $self->{option_results}->{to_address},
                Subject => $self->{payload_attachment}->{subject}
            ],
            parts => [
                Email::MIME->create(
                    attributes => {
                        content_type => 'multipart/alternative',
                        charset     => 'UTF-8',
                    },
                    parts => [$text_part, $html_part],
                ),
                Email::MIME->create(
                    header_str => [
                        'Content-ID' => "<$graph_png_cid>"
                    ],
                    attributes => {
                        content_type => 'image/png',
                        disposition  => 'inline',
                        encoding     => 'base64',
                        name         => $self->{option_results}->{host_name} . ' - ' . $self->{option_results}->{service_description} . '.png'
                    },
                    body => $self->{payload_attachment}->{graph_png}
                )
            ]
        );
    } else {
        $email = Email::MIME->create(
            header_str => [
                From    => $self->{option_results}->{from_address},
                To      => $self->{option_results}->{to_address},
                Subject => $self->{payload_attachment}->{subject}
            ],
            attributes => {
                content_type => 'multipart/alternative',
                charset     => 'UTF-8',
            },
            parts => [$text_part, $html_part],
        );
    }

    my $smtp = Email::Sender::Transport::SMTP->new({
        host => $self->{option_results}->{smtp_address},
        port => $self->{option_results}->{smtp_port},
        sasl_username => $self->{smtp_user},
        sasl_password => $self->{smtp_password},
        ssl => $self->{smtp_ssl},
        debug => $self->{smtp_debug}
    });

    eval { sendmail($email, { transport => $smtp }); };
    if ($@) {
        $self->{output}->output_add(long_msg => 'SMTP Error: ' . $@);
    } else {
        $self->{output}->output_add(short_msg => 'Email sent');
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
}

1;

__END__

=head1 MODE

Send Email alerts.

Example for a host:

centreon_plugins.pl --plugin=notification::email::plugin --mode=alert --to-address='john.doe@example.com' --host-address='192.168.1.1' --host-name='webserver' --host-alias='Web Server' --host-state='DOWN' --host-output='CRITICAL - Socket timeout after 10 seconds' --host-attempts='3' --max-host-attempts='3' --host-duration='6d 18h 33m 51s' --date='2023-04-12 10:30:00' --type='PROBLEM' --service-description='' --service-state='' --service-output='' --service-longoutput='' --service-attempts='' --max-service-attempts='' --service-duration='' --host-id='123' --service-id='' --notif-author='' --notif-comment='' --smtp-nossl --centreon-url='https://your-centreon-server' --smtp-address='smtp.example.com' --smtp-port='587' --from-address='centreon-engine@centreon.com' --centreon-user='admin' --centreon-token='Toi5Ve7ie' --smtp-user='john.doe@example.com' --smtp-password='mysecret'

Example for a service:

centreon_plugins.pl --plugin=notification::email::plugin --mode=alert --to-address='user@example.com' --host-address='192.168.1.100' --host-name='server1' --host-alias='Web Server' --host-state='UP' --host-output='OK - 192.168.1.1 rta 59.377ms lost 0%' --host-attempts='1' --max-host-attempts='3' --host-duration='41d 10h 5m 18s' --date='2023-04-12 14:30:00' --type='PROBLEM' --service-description='HTTP' --service-state='CRITICAL' --service-output='Connection timed out' --service-longoutput='Check HTTP failed: Connection timed out' --service-attempts='3' --max-service-attempts='3' --service-duration='0d 0h 0m 18s' --host-id='100' --service-id='200' --notif-author='' --notif-comment='' --smtp-nossl --centreon-url='https://your-centreon-server' --smtp-address='smtp.example.com' --smtp-port='587' --from-address='centreon@example.com' --centreon-user='admin' --centreon-token='myauthtoken' --smtp-user='johndoe@example.com' --smtp-password='mypassword'

Example for Centreon configuration:

centreon_plugins.pl --plugin=notification::email::plugin --mode=alert --to-address='$CONTACTEMAIL$' --host-address='$HOSTADDRESS$' --host-name='$HOSTNAME$' --host-alias='$HOSTALIAS$' --host-state='$HOSTSTATE$' --host-output='$HOSTOUTPUT$' --host-attempts='$HOSTATTEMPT$' --max-host-attempts='$MAXHOSTATTEMPTS$' --host-duration='$HOSTDURATION$' --date='$SHORTDATETIME$' --type='$NOTIFICATIONTYPE$' --service-description='$SERVICEDESC$' --service-state='$SERVICESTATE$' --service-output='$SERVICEOUTPUT$' --service-longoutput='$LONGSERVICEOUTPUT$' --service-attempts=''$SERVICEATTEMPT$ --max-service-attempts='$MAXSERVICEATTEMPTS$' --service-duration='$SERVICEDURATION$' --host-id='$HOSTID$' --service-id='$SERVICEID$' --notif-author='$NOTIFICATIONAUTHOR$' --notif-comment='$NOTIFICATIONCOMMENT$' --smtp-nossl --centreon-url='https://your-centreon-server' --smtp-address=your-smtp-server --smtp-port=your-smtp-port --from-address='centreon-engine@centreon.com' --centreon-user='your-centreon-username' --centreon-token='your-centreon-autologin-key' --smtp-user='your-smtp-username' --smtp-password='your-smtp-password' 

=over 8

=item B<--smtp-address>

SMTP server address.

=item B<--smtp-port>

SMTP server port (default: 25).

=item B<--smtp-user>

SMTP server username.

=item B<--smtp-password>

SMTP server password.

=item B<--smtp-nossl>

Use this option to disable SSL.

=item B<--smtp-debug>

Enable smtp-debug mode.

=item B<--to-address>

Email address of the recipient (Required).

=item B<--from-address>

Email address of the sender (Required).

=item B<--host-id>

ID of the host.

=item B<--host-address>

IP Address of the host.

=item B<--host-name>

Name of the host.

=item B<--host-alias>

Alias of the host.

=item B<--host-state>

State of the host.

=item B<--host-output>

Output of the host.

=item B<--host-attempts>

Number of attempts made before HARD to check the host.

=item B<--max-host-attempts>

Number of attempts made before host HARD state.

=item B<--host-duration>

Duration of the host status.

=item B<--service-id>

ID of the service.

=item B<--service-description>

Description of the service.

=item B<--service-state>

State of the service.

=item B<--service-output>

Output of the service.

=item B<--service-longoutput>

Long output of the service.

=item B<--service-attempts>

Number of attempts made to check the service.

=item B<--max-service-attempts>

Number of attempts made before service HARD state.

=item B<--service-duration>

Duration of the service status.

=item B<--centreon-user>

Username for the Centreon web interface to retrieve
service's graph (leave empty to not retrieve and display graph).

=item B<--centreon-token>

Autologin token for the Centreon web interface (if --centreon-user is defined).

=item B<--date>

Date of the alert.

=item B<--notif-author>

Author of the notification.

=item B<--notif-comment>

Comment for the notification.

=item B<--centreon-url>

URL of the Centreon web interface. Use either HTTP or HTTPS protocol depending on your setup, for example:
--centreon-url='http://your-centreon-server'
--centreon-url='https://your-centreon-server'

=item B<--type>

Type of the alert.

=item B<--timeout>

Timeout for the request (default: 10 seconds).

=back

=back

=cut
