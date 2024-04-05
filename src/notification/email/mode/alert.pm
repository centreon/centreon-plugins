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
use HTML::Template;
use centreon::plugins::http;
use notification::email::templates::resources;


my %color = (
    up => { 
        background => '#88B922',
        text => '#FFFFFF' 
    },
    down => { 
        background => '#FF4A4A', 
        text => '#FFFFFF' 
    },
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
        'service-displayname:s'  => { name => 'service_displayname' },
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

    my $event_type = '';
    my $author = '';
    my $author_alt = '';
    my $comment = '';
    my $comment_alt = '';
    my $include_author = 0;
    my $include_comment = 0;

    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        $author = $self->{option_results}->{notif_author};
        $include_author = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $author_alt = 'Acknowledged by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $author_alt = 'Flapping by: ' . $self->{option_results}->{notif_author};
        }
    }
    
    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        $comment = $self->{option_results}->{notif_comment};
        $include_comment = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $comment_alt = 'Flapping Comment: ' . $self->{option_results}->{notif_comment};
        }
    }

    my $details = {
        id => $host_id,
        resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id",
        tab => "details"
    };

    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);
    my $dynamic_href = $self->{option_results}->{centreon_url} .'/centreon/monitoring/resources?details=' . $encoded_data;

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

    my $background_color= 'white';
    my $text_color = 'black';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $background_color = $color{lc($self->{option_results}->{host_state})}->{background};
        $text_color = $color{lc($self->{option_results}->{host_state})}->{text};
    } else {
        $background_color = $color{lc($self->{option_results}->{type})}->{background} ;
        $text_color = $color{lc($self->{option_results}->{type})}->{text};
    }
    
    my $dynamic_css = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_css
        );
    $dynamic_css->param(
        backgroundColor => $background_color,
        textColor => $text_color,
        stateColor => $color{lc($self->{option_results}->{host_state})}->{background}
    );
  
    
    my $html_part = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_host_template);
    $html_part->param(
        dynamicCss => $dynamic_css->output,
        type => $self->{option_results}->{type},
        attempts => $self->{option_results}->{host_attempts},
        maxAttempts => $self->{option_results}->{max_host_attempts},
        hostName => $self->{option_results}->{host_name},
        status => $self->{option_results}->{host_state},
        duration => $self->{option_results}->{host_duration},
        hostAlias => $self->{option_results}->{host_alias},
        hostAddress => $self->{option_results}->{host_address},
        date => $self->{option_results}->{date},
        dynamicHref => $dynamic_href,
        eventType => $event_type,
        author => $author,
        comment => $comment,
        output => $self->{option_results}->{host_output},
        includeAuthor => $include_author,
        includeComment => $include_comment
    );

    $self->{payload_attachment}->{html_message} = $html_part->output


}

sub service_message {
    my ($self, %options) = @_;
    
    my $host_id = $self->{option_results}->{host_id};
    my $service_id = $self->{option_results}->{service_id};

    my $event_type = '';
    my $author = '';
    my $author_alt = '';
    my $comment = '';
    my $comment_alt = '';
    my $include_author = 0;
    my $include_comment = 0;

    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        $author = $self->{option_results}->{notif_author};
        $include_author = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $author_alt = 'Acknowledged by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $author_alt = 'Flapping by: ' . $self->{option_results}->{notif_author};
        }
    }
    
    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        $comment = $self->{option_results}->{notif_comment};
        $include_comment = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
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
            $graph_html = '<p>No graph found</p>';
        } elsif ($content =~ /Access denied|Resource not found|Invalid token/) {
            $graph_html = '<p>Cannot retrieve graph: ' . $content . '</p>';
        } else {
            $self->{payload_attachment}->{graph_png} = $content;
            $graph_html = '<img src="cid:' . $self->{option_results}->{host_name} . '_' . $self->{option_results}->{service_description} . "\"  alt=\"Service Graph\" style=\"width:100%; height:auto;\">\n";
        }
    }

    my $details = {
        id => $service_id,
        resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id/services/$service_id",
        tab => 'details'
    };

    my $line_break = '<br />';
    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);
    my $dynamic_href = $self->{option_results}->{centreon_url} .'/centreon/monitoring/resources?details=' . $encoded_data;

   
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

    $self->{option_results}->{service_longoutput} =~ s/\n/<br \/>/g;
    my $output = $self->{option_results}->{service_output} . $line_break . $self->{option_results}->{service_longoutput};

    my $background_color= 'white';
    my $text_color = 'black';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $background_color = $color{lc($self->{option_results}->{service_state})}->{background};
        $text_color = $color{lc($self->{option_results}->{service_state})}->{text};
    } else {
        $background_color = $color{lc($self->{option_results}->{type})}->{background} ;
        $text_color = $color{lc($self->{option_results}->{type})}->{text};
    }
    
    my $dynamic_css = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_css
        );
    $dynamic_css->param(
        backgroundColor => $background_color,
        textColor => $text_color,
        stateColor => $color{lc($self->{option_results}->{service_state})}->{background}
    );

    my $html_part = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_service_template);
    $html_part->param(
        dynamicCss => $dynamic_css->output,
        type => $self->{option_results}->{type},
        attempts => $self->{option_results}->{service_attempts},
        maxAttempts => $self->{option_results}->{max_service_attempts},
        hostName => $self->{option_results}->{host_name},
        serviceDescription => $self->{option_results}->{service_description},
        status => $self->{option_results}->{service_state},
        duration => $self->{option_results}->{service_duration},
        hostAlias => $self->{option_results}->{host_alias},
        hostAddress => $self->{option_results}->{host_address},
        date => $self->{option_results}->{date},
        dynamicHref => $dynamic_href,
        eventType => $event_type,
        author => $author,
        comment => $comment,
        output => $output,
        graphHtml => $graph_html,
        includeAuthor => $include_author,
        includeComment => $include_comment
    );

    $self->{payload_attachment}->{html_message} = $html_part->output

        
}

sub bam_message {
    my ($self, %options) = @_;

    my $event_type = '';
    my $author = '';
    my $author_alt = '';
    my $comment = '';
    my $comment_alt = '';
    my $include_author = 0;
    my $include_comment = 0;

    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        $author = $self->{option_results}->{notif_author};
        $include_author = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $author_alt = 'Acknowledged by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $author_alt = 'Flapping by: ' . $self->{option_results}->{notif_author};
        }
    }
    
    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        $comment = $self->{option_results}->{notif_comment};
        $include_comment = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $comment_alt = 'Flapping Comment: ' . $self->{option_results}->{notif_comment};
        }
    }

    $self->{option_results}->{service_description} =~ /ba_(\d+)/;
    my $ba_id = $1;
   
    my $dynamic_href = $self->{option_results}->{centreon_url} .'/centreon/main.php?p=20701&o=d&ba_id=' . $ba_id;

    $self->{payload_attachment}->{subject} = '*** ' . $self->{option_results}->{type} . ' BAM: ' . $self->{option_results}->{service_displayname} . ' ' . $self->{option_results}->{service_state} . ' ***';
    $self->{payload_attachment}->{alt_message} = '
        ***** Centreon BAM *****

        Notification Type: ' . $self->{option_results}->{type} . '
        Service: ' . $self->{option_results}->{service_displayname} . '
        State: ' . $self->{option_results}->{service_state} . '
        Date/Time: ' . $self->{option_results}->{date};

    if(defined($author_alt) && $author_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "\n        " . $author_alt . "\n";
    }
    if(defined($comment_alt) && $comment_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "        " . $comment_alt . "\n";
    }
    $self->{payload_attachment}->{alt_message} .= '

        Info:
        ' .$self->{option_results}->{service_output};

    my $background_color= 'white';
    my $text_color = 'black';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $background_color = $color{lc($self->{option_results}->{service_state})}->{background};
        $text_color = $color{lc($self->{option_results}->{service_state})}->{text};
    } else {
        $background_color = $color{lc($self->{option_results}->{type})}->{background} ;
        $text_color = $color{lc($self->{option_results}->{type})}->{text};
    }
    
    my $dynamic_css = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_css
        );
    $dynamic_css->param(
        backgroundColor => $background_color,
        textColor => $text_color,
        stateColor => $color{lc($self->{option_results}->{service_state})}->{background}
    );
  
    
    my $html_part = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_bam_template);
    $html_part->param(
        dynamicCss => $dynamic_css->output,
        type => $self->{option_results}->{type},
        serviceDescription => $self->{option_results}->{service_displayname},
        status => $self->{option_results}->{service_state},
        duration => $self->{option_results}->{service_duration},
        date => $self->{option_results}->{date},
        dynamicHref => $dynamic_href,
        eventType => $event_type,
        author => $author,
        comment => $comment,
        output => $self->{option_results}->{service_output},
        includeAuthor => $include_author,
        includeComment => $include_comment
    );

    $self->{payload_attachment}->{html_message} = $html_part->output

}

sub metaservice_message {
    my ($self, %options) = @_;

    my $host_id = $self->{option_results}->{host_id};
    my $service_id = $self->{option_results}->{service_id};

    my $event_type = '';
    my $author = '';
    my $author_alt = '';
    my $comment = '';
    my $comment_alt = '';
    my $include_author = 0;
    my $include_comment = 0;

    if (defined($self->{option_results}->{notif_author}) && $self->{option_results}->{notif_author} ne '') {
        $author = $self->{option_results}->{notif_author};
        $include_author = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $author_alt = 'Scheduled Downtime by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $author_alt = 'Acknowledged by: ' . $self->{option_results}->{notif_author};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $author_alt = 'Flapping by: ' . $self->{option_results}->{notif_author};
        }
    }
    
    if (defined($self->{option_results}->{notif_comment}) && $self->{option_results}->{notif_comment} ne '') {
        $comment = $self->{option_results}->{notif_comment};
        $include_comment = 1;
        if ($self->{option_results}->{type} =~ /^downtime.*$/i) {
            $event_type = 'Scheduled Downtime';
            $comment_alt = 'Scheduled Downtime Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^acknowledgement$/i) {
            $event_type = 'Acknowledged';
            $comment_alt = 'Acknowledged Comment: ' . $self->{option_results}->{notif_comment};
        } elsif($self->{option_results}->{type} =~ /^flaping.*$/i) {
            $event_type = 'Flapping';
            $comment_alt = 'Flapping Comment: ' . $self->{option_results}->{notif_comment};
        }
    }

    my $graph_html;
    if ($self->{option_results}->{centreon_user} && $self->{option_results}->{centreon_user} ne '' 
        && $self->{option_results}->{centreon_token}  && $self->{option_results}->{centreon_token} ne '') {
        my $content = $self->{http}->request(
            hostname => '',
            full_url => $self->{option_results}->{centreon_url} . '/centreon/include/views/graphs/generateGraphs/generateImage.php?akey=' . $self->{option_results}->{centreon_token} . '&username=' . $self->{option_results}->{centreon_user} . '&chartId=' . $host_id . '_'. $service_id,
            timeout => $self->{option_results}->{timeout},
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() !~ /200/ || $content =~ /^OK/) {
            $graph_html = '<p>No graph found</p>';
        } elsif ($content =~ /Access denied|Resource not found|Invalid token/) {
            $graph_html = '<p>Cannot retrieve graph: ' . $content . '</p>';
        } else {
            $self->{payload_attachment}->{graph_png} = $content;
            $graph_html = '<img src="cid:' . $self->{option_results}->{host_name} . '_' . $self->{option_results}->{service_description} . "\"  alt=\"Service Graph\" style=\"width:100%; height:auto;\">\n";
        }
    }

    my $details = {
        id => $service_id,
        resourcesDetailsEndpoint => "/centreon/api/latest/monitoring/resources/hosts/$host_id/services/$service_id",
        tab => 'details'
    };

    my $line_break = '<br />';
    my $json_data = encode_json($details);
    my $encoded_data = uri_escape($json_data);
    my $dynamic_href = $self->{option_results}->{centreon_url} .'/centreon/monitoring/resources?details=' . $encoded_data;

    $self->{payload_attachment}->{subject} = '*** ' . $self->{option_results}->{type} . ' Meta Service: ' . $self->{option_results}->{service_displayname} . ' ' . $self->{option_results}->{service_state} . ' ***';
    $self->{payload_attachment}->{alt_message} = '
        ***** Centreon *****

        Notification Type: ' . $self->{option_results}->{type} . '
        Meta Service: ' . $self->{option_results}->{service_displayname} . '
        State: ' . $self->{option_results}->{service_state} . '
        Date/Time: ' . $self->{option_results}->{date};

    if(defined($author_alt) && $author_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "\n        " . $author_alt . "\n";
    }
    if(defined($comment_alt) && $comment_alt ne ''){
        $self->{payload_attachment}->{alt_message} .= "        " . $comment_alt . "\n";
    }
    $self->{payload_attachment}->{alt_message} .= '

        Info:
        ' .$self->{option_results}->{service_output};

    my $background_color= 'white';
    my $text_color = 'black';
    if($self->{option_results}->{type} =~ /^problem|recovery$/i) {
        $background_color = $color{lc($self->{option_results}->{service_state})}->{background};
        $text_color = $color{lc($self->{option_results}->{service_state})}->{text};
    } else {
        $background_color = $color{lc($self->{option_results}->{type})}->{background} ;
        $text_color = $color{lc($self->{option_results}->{type})}->{text};
    }
    
    my $dynamic_css = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_css
        );
    $dynamic_css->param(
        backgroundColor => $background_color,
        textColor => $text_color,
        stateColor => $color{lc($self->{option_results}->{service_state})}->{background}
    );
  
    
    my $html_part = HTML::Template->new(
        scalarref => \$notification::email::templates::resources::get_metaservice_template);
    $html_part->param(
        dynamicCss => $dynamic_css->output,
        type => $self->{option_results}->{type},
        attempts => $self->{option_results}->{service_attempts},
        maxAttempts => $self->{option_results}->{max_service_attempts},
        serviceDescription => $self->{option_results}->{service_displayname},
        status => $self->{option_results}->{service_state},
        duration => $self->{option_results}->{service_duration},
        date => $self->{option_results}->{date},
        dynamicHref => $dynamic_href,
        eventType => $event_type,
        author => $author,
        comment => $comment,
        output => $self->{option_results}->{service_output},
        graphHtml => $graph_html,
        includeAuthor => $include_author,
        includeComment => $include_comment
    );

    $self->{payload_attachment}->{html_message} = $html_part->output

}

sub set_payload {
    my ($self, %options) = @_;

    if ($self->{option_results}->{host_name} =~ /^_Module_BAM.*/) {
        $self->bam_message();
    } elsif ($self->{option_results}->{host_name} =~ /^_Module_Meta/ ) {
        $self->metaservice_message();
    } elsif ( defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '' ) {
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

centreon_plugins.pl --plugin=notification::email::plugin --mode=alert --to-address='$CONTACTEMAIL$' --host-address='$HOSTADDRESS$' --host-name='$HOSTNAME$' --host-alias='$HOSTALIAS$' --host-state='$HOSTSTATE$' --host-output='$HOSTOUTPUT$' --host-attempts='$HOSTATTEMPT$' --max-host-attempts='$MAXHOSTATTEMPTS$' --host-duration='$HOSTDURATION$' --date='$SHORTDATETIME$' --type='$NOTIFICATIONTYPE$' --service-description='$SERVICEDESC$' --service-displayname='$SERVICEDISPLAYNAME$' --service-state='$SERVICESTATE$' --service-output='$SERVICEOUTPUT$' --service-longoutput='$LONGSERVICEOUTPUT$' --service-attempts='$SERVICEATTEMPT$' --max-service-attempts='$MAXSERVICEATTEMPTS$' --service-duration='$SERVICEDURATION$' --host-id='$HOSTID$' --service-id='$SERVICEID$' --notif-author='$NOTIFICATIONAUTHOR$' --notif-comment='$NOTIFICATIONCOMMENT$' --smtp-nossl --centreon-url='https://your-centreon-server' --smtp-address=your-smtp-server --smtp-port=your-smtp-port --from-address='centreon-engine@centreon.com' --centreon-user='your-centreon-username' --centreon-token='your-centreon-autologin-key' --smtp-user='your-smtp-username' --smtp-password='your-smtp-password' 

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

Enable debugging of SMTP.

=item B<--to-address>

Email address of the recipient (required).

=item B<--from-address>

Email address of the sender (required).

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

=item B<--service-displayname>

Display BA name.

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
