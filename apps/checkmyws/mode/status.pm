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

package apps::checkmyws::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use centreon::plugins::statefile;

use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname', default => 'api.checkmy.ws'},
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto', default => "https" },
            "urlpath:s"         => { name => 'url_path', default => "/api/status" },
            "proxyurl:s"        => { name => 'proxyurl' },
            "uid:s"             => { name => 'uid' },
            "timeout:s"         => { name => 'timeout', default => '3' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

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
    if ((!defined($self->{option_results}->{uid}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set uid option");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->{statefile_value}->read(statefile => 'checkmyws_' . $self->{option_results}->{uid}  . '_' . centreon::plugins::httplib::get_port($self) . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->write(data => $new_datas);

    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."/".$self->{option_results}->{uid};

    my $jsoncontent = centreon::plugins::httplib::connect($self);

    my $json = JSON->new;

    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $state = $webcontent->{state};
    my $output = $webcontent->{state_code_str};

    if ($state == -3) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Disable");
    } elsif ($state == -2) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Not scheduled");
    } elsif ($state == -1) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Pending...");
    } elsif ($state == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $output);
    } elsif ($state == 1) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => $output);
    } elsif ($state == 2) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => $output);
    } elsif ($state >= 3) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => $output);
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check website status

=over 8

=item B<--hostname>

Checkmyws api host (Default: 'api.checkmy.ws')

=item B<--port>

Port used by checkmyws

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get checkmyws information (Default: 'api/status')

=item B<--proxyurl>

Proxy URL if any

=item B<--uid>

ID for checkmyws API

=item B<--timeout>

Threshold for HTTP timeout (Default: '3')

=back

=cut
