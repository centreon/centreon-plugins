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

package notification::email::mode::messages::services;

use strict;
use warnings;
use LWP::UserAgent;

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
    },
);

sub new {
    use Data::Dumper;
    print Dumper(@_);
    my ($class, %options) = @_;
    
    my $self  = {};
    bless $self, $class;
    
    #print Dumper(%options);
    # print Dumper($options);
    $self->service_message();
    

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};

}

sub service_message {
    my ($self, $options) = @_;
        
    my $host_id = $self->{option_results}->{host_id};
    my $service_id = $self->{option_results}->{service_id};

    my $author_html = '';
    my $author_alt = '';
    my $comment_html = '';
    my $comment_alt = '';
    if(defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne ''){
        if($self->{option_results}->{type} =~ /^downtime.*$/i){
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
    if(defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne ''){
        if($self->{option_results}->{type} =~ /^downtime.*$/i){
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


print $self->{option_results}->{centreon_url} . "\n";

    my $url = $self->{option_results}->{centreon_url} . '/centreon/include/views/graphs/generateGraphs/generateImage.php?akey=' . $self->{option_results}->{centreon_token} . '&username=' . $self->{option_results}->{centreon_user} . '&hostname=' . $self->{option_results}->{host_name} . '&service='. $self->{option_results}->{service_description};
    my $ua = LWP::UserAgent->new(timeout => $self->{option_results}->{timeout});
    my $response = $ua->get($url);
    my $img = undef;
    
    if($response->status_line !~ /200/){
        $img = '<h2 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:20px; padding-left:5%;">Graph not load</h2>';
    } else {
        $self->{payload_attachment}->{png} = $response->decoded_content;
        $img = '<img style="display:block; width:98%; height:auto;margin:0 10px 0 10px;" src="data:image/png;base64,'. encode_base64($response->decoded_content) . '">';
    }

    

    my $details = {
          id => $service_id,
          resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id/services/$service_id",
          tab => "details"
        };

    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);

    my $line_break;

    $self->{option_results}->{service_longoutput} =~ s/\n/<br \/>/g;
    if(defined($self->{option_results}->{service_longoutput}) && $self->{option_results}->{service_longoutput} ne '') {
        $line_break = '<br>';
    }

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

    if(defined($author_alt) && $author_alt ne ''){
            $self->{payload_attachment}->{alt_message} .= "\n    " . $author_alt . "\n";
        }
        if(defined($comment_alt) && $comment_alt ne ''){
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

    <!--[if !mso]><!-->
    <link href="https://fonts.googleapis.com/css?family=Red+Hat+Display
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
                    if(defined($author_html) && $author_html ne ''){
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
                    if(defined($comment_html) && $comment_html ne ''){
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
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td></tr></tbody>
                    <tbody>
                    <tr>
                        <td width="98%" style="vertical-align:middle;font-size:14px;width:98%;margin:0 10px 0 10px;">
                            <h4 style="font-family: CoconPro-BoldCond, Open Sans, Verdana, sans-serif; margin:0; font-size:15px; color:#b0b0b0; padding-left:3%;text-decoration:underline;">Service Graph:</h4>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            '. $img . '
                        </td>
                    </tr>
                    </tbody>
                    <tbody><tr><td style="font-size:9px;vertical-align:top;">&nbsp;</td>
                    </tr></tbody>
                <tbody><tr><td style="font-size:16px;vertical-align:top;">&nbsp;</td>
                </tr></tbody></table>
                
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:separate;mso-table-lspace:0pt;mso-table-rspace:0pt;width:100%;">
                <tbody>
                    <tr>';
                    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
                        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{service_state})}->{background} . '; height:10px">';
                    } else{
                        $self->{payload_attachment}->{html_message} .= '<td style="background-color:' . $color_service{lc($self->{option_results}->{type})}->{background} . '; height:10px">';
                    }
                  $self->{payload_attachment}->{html_message} .= '</tr>
                    <tr>
                    <td style="background-color:#255891;">';
                    if(defined($self->{option_results}->{centreon_url}) && $self->{option_results}->{centreon_url} ne ''){
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

    return $self->{payload_attachment}
}