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

package apps::github::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use JSON;

my $thresholds = {
    status => [
        ['good', 'OK'],
        ['minor', 'WARNING'],
        ['major', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname', default => 'status.github.com' },
            "port:s"            => { name => 'port', default => '443'},
            "proto:s"           => { name => 'proto', default => 'https' },
            "urlpath:s"         => { name => 'url_path', default => '/api/last-message.json' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "timeout:s"         => { name => 'timeout', default => '3' },
            "threshold-overload:s@"   => { name => 'threshold_overload' },
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

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('status', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    return $status;
}

sub run {
    my ($self, %options) = @_;

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

    my $exit = $self->get_severity(section => 'status', value => $webcontent->{status});

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%s", $webcontent->{body}));

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check GitHub's status

=over 8

=item B<--hostname>

IP Addr/FQDN of the GitHub's status website (Default: status.github.com)

=item B<--port>

Port used by GitHub's status website (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get GitHub's status information (Default: '/api/last-message.json')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username

=item B<--password>

Specify password

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(good)$)'

=back

=cut
