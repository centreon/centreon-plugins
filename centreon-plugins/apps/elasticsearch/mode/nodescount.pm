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

package apps::elasticsearch::mode::nodescount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', default => 9200 },
            "proto:s"           => { name => 'proto' },
            "urlpath:s"         => { name => 'url_path', default => '/_cluster/stats' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            "timeout:s"         => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $jsoncontent = $self->{http}->request();

    my $json = JSON->new;
    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $exit = $self->{perfdata}->threshold_check(value => $webcontent->{nodes}->{count}->{total}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Number of nodes for cluster %s : %d",
                                                      $webcontent->{cluster_name}, $webcontent->{nodes}->{count}->{total}));
    $self->{output}->perfdata_add(label => "node",
                                  value => $webcontent->{nodes}->{count}->{total},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodemasteronly",
                                  value => $webcontent->{nodes}->{count}->{master_only},
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodedataonly",
                                  value => $webcontent->{nodes}->{count}->{data_only},
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodemasterdata",
                                  value => $webcontent->{nodes}->{count}->{master_data},
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodeclient",
                                  value => $webcontent->{nodes}->{count}->{client},
                                  min => 0,
                                 );
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Elasticsearch number of nodes

=over 8

=item B<--hostname>

IP Addr/FQDN of the Elasticsearch host

=item B<--port>

Port used by Elasticsearch API (Default: '9200')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get Elasticsearch information (Default: '_cluster/stats')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
