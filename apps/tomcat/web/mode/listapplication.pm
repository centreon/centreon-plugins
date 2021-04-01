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

package apps::tomcat::web::mode::listapplication;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'     => { name => 'hostname' },
        'port:s'         => { name => 'port', default => '8080' },
        'proto:s'        => { name => 'proto' },
        'credentials'    => { name => 'credentials' },
        'basic'          => { name => 'basic' },
        'username:s'     => { name => 'username' },
        'password:s'     => { name => 'password' },
        'timeout:s'      => { name => 'timeout' },
        'urlpath:s'      => { name => 'url_path', default => '/manager/text/list' },
        'filter-name:s'  => { name => 'filter_name', },
        'filter-state:s' => { name => 'filter_state', },
        'filter-path:s'  => { name => 'filter_path', },
    });

    $self->{result} = {};
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();

    while ($webcontent =~ /^(.*?):(.*?):(.*?):(.*)/mg) {
        my ($context, $state, $sessions, $contextpath) = ($1, $2, $3, $4);
               
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $context !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $state !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter state");
            next;
        }
        if (defined($self->{option_results}->{filter_path}) && $self->{option_results}->{filter_path} ne '' &&
            $contextpath !~ /$self->{option_results}->{filter_path}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter path");
            next;
        }

        $self->{result}->{$context} = {state => $state, sessions => $sessions, contextpath => $contextpath};
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [state = " . $self->{result}->{$name}->{state} . ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Contexts:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(
            name => $name,
            state => $self->{result}->{$name}->{state}
        );
    }
}

1;

__END__

=head1 MODE

List Tomcat Application Server Contexts

=over 8

=item B<--hostname>

IP Address or FQDN of the Tomcat Application Server

=item B<--port>

Port used by Tomcat

=item B<--proto>

Protocol used http or https

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--url-path>

Path to the Tomcat Manager List (Default: Tomcat 7 '/manager/text/list')
Tomcat 6: '/manager/list'
Tomcat 7: '/manager/text/list'

=item B<--filter-name>

Filter Context name (regexp can be used).

=item B<--filter-state>

Filter state (regexp can be used).
Can be for example: 'running' or 'stopped'.

=item B<--filter-path>

Filter Context Path (regexp can be used).
Can be for example: '/STORAGE/context/test1'.

=back

=cut
