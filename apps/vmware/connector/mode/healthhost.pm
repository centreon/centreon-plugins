################################################################################
# Copyright 2005-2014 MERETHIS
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
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::vmware::connector::mode::healthhost;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::vmware::connector::lib::common;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);
use UUID;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "connector-hostname:s"    => { name => 'connector_hostname' },
                                  "connector-port:s"        => { name => 'connector_port', default => 5700 },
                                  "container:s"             => { name => 'container', default => 'default' },
                                  "esx-hostname:s"          => { name => 'esx_hostname' },
                                  "storage-status"          => { name => 'storage_status' },
                                });
    $self->{json_send} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{connector_hostname}) ||
        $self->{option_results}->{connector_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set option --connector-hostname.");
        $self->{output}->option_exit();
    }
}

sub build_request {
    my ($self, %options) = @_;
    
    $self->{json_send}->{identity} = 'client-' . unpack('H*', $options{uuid});
    $self->{json_send}->{command} = 'healthhost';
    $self->{json_send}->{container} = $self->{option_results}->{container};
    $self->{json_send}->{esx_hostname} = $self->{option_results}->{esx_hostname};
    $self->{json_send}->{storage_status} = defined($self->{option_results}->{storage_status}) ? 1 : 0;
}

sub run {
    my ($self, %options) = @_;

    my $uuid;
    my $context = zmq_init();
    my $requester = zmq_socket($context, ZMQ_DEALER);
    if (!defined($requester)) {
        $self->{output}->add_option_msg(short_msg => "Cannot create socket: $!");
        $self->{output}->option_exit();
    }
        
    UUID::generate($uuid);
    zmq_setsockopt($requester, ZMQ_IDENTITY, "client-" . $uuid);
    zmq_connect($requester, 'tcp://' . $self->{option_results}->{connector_hostname} . ':' . $self->{option_results}->{connector_port});
    
    $self->build_request(uuid => $uuid);
    
    zmq_sendmsg($requester, "REQCLIENT " . JSON->new->utf8->encode($self->{json_send}));
    my $response = zmq_recvmsg($requester);
    zmq_close($requester);
 
    apps::vmware::connector::lib::common::connector_response($self, response => $response);
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check health of ESX hosts.

=over 8

=item B<--connector-hostname>

Connector hostname (required).

=item B<--connector-port>

Connector port (default: 5700).

=item B<--container>

Container to use (it depends of the connector configuration).

=item B<--esx-hostname>

ESX hostname to check.

=item B<--storage-status>

Check storage(s) status.

=back

=cut
