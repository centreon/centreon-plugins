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

package apps::elasticsearch::mode::cluster;

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
            "indice-uid:s"      => { name => 'indice_uid' },
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
    if (!defined($self->{option_results}->{indice_uid})) {
        $self->{output}->add_option_msg(short_msg => "Please set the indice-uid option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."_cluster/health/".$self->{option_results}->{indice_uid};

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

    my $exit;
    if ($webcontent->{status} eq 'green') {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("All shard are allocated"));
    } elsif ($webcontent->{status} eq 'yellow') {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => sprintf("Primary shards are allocated but replicas not"));
    } elsif ($webcontent->{status} eq 'red') {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Some or all primary shards aren't ready"));
    }

    $self->{output}->perfdata_add(label => 'primary_shard',
                                  value => sprintf("%d", $webcontent->{active_primary_shards}),
                                  min => 0,
    );
    $self->{output}->perfdata_add(label => 'shard',
                                  value => sprintf("%d", $webcontent->{active_shards}),
                                  min => 0,
    );
    $self->{output}->perfdata_add(label => 'unassigned_shard',
                                  value => sprintf("%d", $webcontent->{unassigned_shards}),
                                  min => 0,
    );

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Elasticsearch cluster health

=over 8

=item B<--hostname>

IP Addr/FQDN of the Bluemind host

=item B<--port>

Port used by InfluxDB API (Default: '8086')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get influxdb information (Default: '/db')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--indice-uid>

Specify Cluster indice

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

=cut
