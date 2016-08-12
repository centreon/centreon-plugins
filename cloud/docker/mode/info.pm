#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::docker::mode::info;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
        {
            "port:s" => { name => 'port' }
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

   	my $urlpath = "/info";
	my $port = $self->{option_results}->{port};
	my $containerapi = $options{custom};

    my $webcontent = $containerapi->api_request(urlpath => $urlpath,
                                                port => $port);

	$self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Docker is running"));

    $self->{output}->perfdata_add(label => "containers",
                                  value => $webcontent->{Containers},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "events_listener",
                                  value => $webcontent->{NEventsListener},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "file_descriptor",
                                  value => $webcontent->{NFd},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "go_routines",
                                  value => $webcontent->{NGoroutines},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "images",
                                  value => $webcontent->{Images},
                                  min => 0,
                                 );


    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Docker information

=head2 DOCKER OPTIONS

=item B<--port>

Port used by Docker

=back

=cut
