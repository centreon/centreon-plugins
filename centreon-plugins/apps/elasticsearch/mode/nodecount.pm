###############################################################################
# Copyright 2005-2015 CENTREON
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation ; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.
#
# Linking this program statically or dynamically with other modules is making a
# combined work based on this program. Thus, the terms and conditions of the GNU
# General Public License cover the whole combination.
#
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

package apps::elasticsearch::mode::nodecount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', default => '9200'},
            "proto:s"           => { name => 'proto', default => 'http' },
            "urlpath:s"         => { name => 'url_path', default => '/' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            "timeout:s"         => { name => 'timeout', default => '3' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."_cluster/stats/";

    my $jsoncontent = centreon::plugins::httplib::connect($self, connection_exit => 'critical');

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
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodedataonly",
                                  value => $webcontent->{nodes}->{count}->{data_only},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodemasterdata",
                                  value => $webcontent->{nodes}->{count}->{master_data},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                 );
    $self->{output}->perfdata_add(label => "nodeclient,
                                  value => $webcontent->{nodes}->{count}->{client},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
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

Set path to get Elasticsearch information (Default: '/')

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

Threshold for HTTP timeout (Default: 3)

=back

=cut
