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

package cloud::docker::mode::listnodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "port:s"    => { name => 'port' },
            "exclude:s" => { name => 'exclude' },
        });

    $self->{node_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} nodes."));
        return 1;
    }
return 0;
}

sub listnode_request {
    my ($self, %options) = @_;

    my $urlpath = "/nodes";
    my $port = $self->{option_results}->{port};

    my $nodeapi = $options{custom};
	my $webcontent = $nodeapi->api_request(urlpath => $urlpath,
	                                        port => $port);

    foreach my $val (@$webcontent) {
        next if ($self->check_exclude(status => $val->{Status}->{State}));
        my $nodeid = $val->{ID};
        $self->{node_infos}->{$nodeid}->{hostname} = $val->{Description}->{Hostname};
        $self->{node_infos}->{$nodeid}->{role} = $val->{Spec}->{Role};
        $self->{node_infos}->{$nodeid}->{availability} = $val->{Spec}->{Availability};
        $self->{node_infos}->{$nodeid}->{state} = $val->{Status}->{State};
        if ($val->{Spec}->{Role} eq 'manager') {
            $self->{node_infos}->{$nodeid}->{reachability} = $val->{ManagerStatus}->{Reachability};
        } else {
            $self->{node_infos}->{$nodeid}->{reachability} = '';
        }

    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['id', 'hostname', 'role', 'state', 'availability', 'reachability'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->listnode_request(%options);

    foreach my $nodeid (keys %{$self->{node_infos}}) {
        $self->{output}->add_disco_entry(id => $nodeid,
                                        hostname => $self->{node_infos}->{$nodeid}->{hostname},
                                        role => $self->{node_infos}->{$nodeid}->{role},
                                        state => $self->{node_infos}->{$nodeid}->{state},
                                        availability => $self->{node_infos}->{$nodeid}->{availability},
                                        reachability => $self->{node_infos}->{$nodeid}->{reachability},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->listnode_request(%options);

    foreach my $nodeid (keys %{$self->{node_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [hostname = %s , role = %s, state = %s, availability = %s, reachability = %s]",
                                                        $nodeid,
                                                        $self->{node_infos}->{$nodeid}->{hostname},
                                                        $self->{node_infos}->{$nodeid}->{role},
                                                        $self->{node_infos}->{$nodeid}->{state},
                                                        $self->{node_infos}->{$nodeid}->{availability},
                                                        $self->{node_infos}->{$nodeid}->{reachability}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Swarm nodes:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List Docker Swarm nodes

=head2 DOCKER OPTIONS

=item B<--port>

Port used by Docker

=head2 MODE OPTIONS

=item B<--exlude>

Exclude specific node's state (comma seperated list) (Example: --exclude=disconnected)

=back

=cut
