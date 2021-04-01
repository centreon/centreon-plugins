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

package apps::bind9::web::custom::api;

use strict;
use warnings;
use centreon::plugins::misc;
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
            'port:s'     => { name => 'port' },
            'proto:s'    => { name => 'proto' },
            'url-path:s' => { name => 'url_path' },
            'timeout:s'  => { name => 'timeout' },
            'unknown-status:s'  => { name => 'unknown_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-status:s'  => { name => 'warning_status' },
            'critical-status:s' => { name => 'critical_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8080;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/';
    $self->{unknown_status} = (defined($self->{option_results}->{unknown_status})) ? $self->{option_results}->{unknown_status} : undef;
    $self->{warning_status} = (defined($self->{option_results}->{warning_status})) ? $self->{option_results}->{warning_status} : undef;
    $self->{critical_status} = (defined($self->{option_results}->{critical_status})) ? $self->{option_results}->{critical_status} : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_uniq_id {
     my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{port};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{unknown_status} = $self->{unknown_status};
    $self->{option_results}->{warning_status} = $self->{warning_status};
    $self->{option_results}->{critical_status} = $self->{critical_status};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub load_response {
    my ($self, %options) = @_;
    
    if ($self->{response_type} eq 'xml') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'XML::XPath',
            error_msg => "Cannot load module 'XML::XPath'."
        );
        eval {
            $self->{xpath_response} = XML::XPath->new(xml => $options{response});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot load XML response");
            $self->{output}->option_exit();
        }
    }
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    my $response = $self->{http}->request();
    
    my ($content_type) = $self->{http}->get_header(name => 'Content-Type');
    if (!defined($content_type) || $content_type !~ /(xml|json)/i) {
        $self->{output}->add_option_msg(short_msg => "content-type not set");
        $self->{output}->option_exit();
    }

    $self->{response_type} = $1;
    if ($self->{response_type} eq 'json') {
        $self->{output}->add_option_msg(short_msg => "json format unsupported");
        $self->{output}->option_exit();
    }
    
    $self->load_response(response => $response);
    my $method = $self->can("get_api_version_$self->{response_type}");
    if (!defined($method)) {
        $self->{output}->add_option_msg(short_msg => "method 'get_api_version_$self->{response_type}' unsupported");
        $self->{output}->option_exit();
    }
    $self->$method();
    if (!defined($self->{api_version}) || $self->{api_version} !~ /^(\d+)/) {
        $self->{output}->add_option_msg(short_msg => "cannot get api version");
        $self->{output}->option_exit();
    }
    
    $self->{api_version} = $1;
}

sub get_api_version_xml {
    my ($self, %options) = @_;
    
    eval {
        my $nodesets = $self->{xpath_response}->find('//statistics/@version');
        my $node = $nodesets->get_node(1);
        $self->{api_version} = $node->getNodeValue();
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot lookup: $@");
        $self->{output}->option_exit();
    }    
}

sub load_memory_xml_v3 {
    my ($self, %options) = @_;
    
    my $memory = {};
    
    my $nodesets = $self->{xpath_response}->find('//memory/summary');
    my $node_memory = $nodesets->get_node(1);
    foreach my $node ($node_memory->getChildNodes()) {
        my $name = $node->getLocalName();
        next if (!defined($name));
        if ($name eq 'TotalUse') {
            $memory->{total_use} = $node->string_value;
        }
        if ($name eq 'InUse') {
            $memory->{in_use} = $node->string_value;
        }
    }
    
    return $memory;
}

sub load_memory_xml_v2 {
    my ($self, %options) = @_;
    
    return $self->load_memory_xml_v3();
}

sub load_zones_xml_v3 {
    my ($self, %options) = @_;

    my $zones = {};
    my $nodesets = $self->{xpath_response}->find('//views//zones/zone');
    foreach my $node ($nodesets->get_nodelist()) {
        my $name = $node->getAttribute('name');
        next if (!defined($name));
        $zones->{$name} = { counters => { rcode => {}, qtype => {} } };
        foreach my $counters_node ($node->getChildNodes()) {
            next if ($counters_node->getLocalName() ne 'counters');
            my $type = $counters_node->getAttribute('type');
            foreach my $counter_node ($counters_node->getChildNodes()) {
                my $counter_name = $counter_node->getAttribute('name');
                $zones->{$name}->{counters}->{$type}->{$counter_name} = $counter_node->string_value;
            }
        }
    }
    
    return $zones;
}

sub load_zones_xml_v2 {
    my ($self, %options) = @_;
    
    my $zones = {};
    my $nodesets = $self->{xpath_response}->find('//views//zones/zone');
    foreach my $node ($nodesets->get_nodelist()) {
        my $name;
        my $counters = {};
        foreach my $subnode ($node->getChildNodes()) {
            my $tag_name = $subnode->getLocalName();
            $name = $subnode->string_value
                if ($tag_name eq 'name');
            if ($tag_name eq 'counters') {
                foreach my $counter_node ($subnode->getChildNodes()) {
                    $tag_name = $counter_node->getLocalName();
                    next if (!defined($tag_name));
                    $counters->{$tag_name} = $counter_node->string_value;
                }
            }
        }
        
        if (defined($name)) {
            $zones->{$name}->{counters}->{rcode} = $counters;
        }
    }

    return $zones;
}

sub load_server_xml_v3 {
    my ($self, %options) = @_;
    
    my $server = { counters => { } };
    my $nodesets = $self->{xpath_response}->find('//server//counters');
    foreach my $node ($nodesets->get_nodelist()) {
        my $type = $node->getAttribute('type');
        next if (!defined($type));
        foreach my $counter_node ($node->getChildNodes()) {
            my $counter_name = $counter_node->getAttribute('name');
            $server->{counters}->{$type} = {}
                if (!defined($server->{counters}->{$type}));
            $server->{counters}->{$type}->{$counter_name} = $counter_node->string_value;
        }
    }
    
    return $server;
}

sub load_server_xml_v2 {
    my ($self, %options) = @_;
    
    my $server = { counters => { opcode => {}, nsstat => {}, qtype => {} } };
    
    my $nodesets = $self->{xpath_response}->find('//server//opcode');
    foreach my $node ($nodesets->get_nodelist()) {
        my ($name, $value);
        foreach my $counter_node ($node->getChildNodes()) {
            my $tag_name = $counter_node->getLocalName();
            next if (!defined($tag_name));
            
            $name = $counter_node->string_value if ($tag_name eq 'name');
            $value = $counter_node->string_value if ($tag_name eq 'counter');
        }
        
        if (defined($name) && defined($value)) {
            $server->{counters}->{opcode}->{$name} = $value;
        }
    }
    
    $nodesets = $self->{xpath_response}->find('//server//rdtype');
    foreach my $node ($nodesets->get_nodelist()) {
        my ($name, $value);
        foreach my $counter_node ($node->getChildNodes()) {
            my $tag_name = $counter_node->getLocalName();
            next if (!defined($tag_name));
            
            $name = $counter_node->string_value if ($tag_name eq 'name');
            $value = $counter_node->string_value if ($tag_name eq 'counter');
        }
        
        if (defined($name) && defined($value)) {
            $server->{counters}->{qtype}->{$name} = $value;
        }
    }
    
    $nodesets = $self->{xpath_response}->find('//server//nsstat');
    foreach my $node ($nodesets->get_nodelist()) {
        my ($name, $value);
        foreach my $counter_node ($node->getChildNodes()) {
            my $tag_name = $counter_node->getLocalName();
            next if (!defined($tag_name));
            
            $name = $counter_node->string_value if ($tag_name eq 'name');
            $value = $counter_node->string_value if ($tag_name eq 'counter');
        }
        
        if (defined($name) && defined($value)) {
            $server->{counters}->{nsstat}->{$name} = $value;
        }
    }
    
    return $server;
}

sub get_memory {
    my ($self, %options) = @_;

    $self->request();
    my $method = $self->can("load_memory_$self->{response_type}_v$self->{api_version}");
    if (!defined($method)) {
        $self->{output}->add_option_msg(short_msg => "method 'load_memory_$self->{response_type}_v$self->{api_version}' unsupported");
        $self->{output}->option_exit();
    }
    
    my $memory = $self->$method();
    if (!defined($memory->{in_use})) {
        $self->{output}->add_option_msg(short_msg => "cannot find memory information");
        $self->{output}->option_exit();
    }

    return $memory;
}

sub get_zones {
    my ($self, %options) = @_;

    $self->request();
    my $method = $self->can("load_zones_$self->{response_type}_v$self->{api_version}");
    if (!defined($method)) {
        $self->{output}->add_option_msg(short_msg => "method 'load_zones_$self->{response_type}_v$self->{api_version}' unsupported");
        $self->{output}->option_exit();
    }
    
    my $zones = $self->$method();
    if (scalar(keys %{$zones}) == 0) {
        $self->{output}->add_option_msg(short_msg => "cannot find zones information");
        $self->{output}->option_exit();
    }

    return $zones;
}

sub get_server {
    my ($self, %options) = @_;

    $self->request();
    my $method = $self->can("load_server_$self->{response_type}_v$self->{api_version}");
    if (!defined($method)) {
        $self->{output}->add_option_msg(short_msg => "method 'load_server_$self->{response_type}_v$self->{api_version}' unsupported");
        $self->{output}->option_exit();
    }
    
    my $server = $self->$method();
    if (scalar(keys %{$server->{counters}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "cannot find server information");
        $self->{output}->option_exit();
    }

    return $server;
}

1;

__END__

=head1 NAME

Statistics Channels API

=head1 SYNOPSIS

Statistics Channels API custom mode

=head1 API OPTIONS

=over 8

=item B<--hostname>

Statistics Channels hostname.

=item B<--port>

Port used (Default: 8080)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--url-path>

Statistics Channel API Path (Default: '/').

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
