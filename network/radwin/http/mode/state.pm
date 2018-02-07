################################################################################
# Copyright 2017 Yann Pilpré - YPSI SAS
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
# Authors : Yann Pilpré <yann.pilpre@ypsi.fr>
#
####################################################################################

# Chemin vers le mode
package network::radwin::http::mode::state;

# Bibliothèque nécessaire pour le mode
use base qw(centreon::plugins::mode);

# Bibliothèques nécessaires
use strict;
use warnings;

# Bibliothèque nécessaire pour certaines fonctions
use POSIX;
use MIME::Base64;
# Bibliothèque nécessaire pour utiliser un fichier de cache
use centreon::plugins::http;
use Switch;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
 "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto' },
            "urlpath:s"         => { name => 'url_path', default => "/mobile/monitorData.asp" },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "proxyurl:s"        => { name => 'proxyurl' },

                                });
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;
}

sub check_options {
 my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{http}->set_options(%{$self->{option_results}});



}

sub run {
        my ($self, %options) = @_;
my $Autorization = 'Basic ' .encode_base64($self->{option_results}->{username}.':'.$self->{option_results}->{password});
$self->{http}->add_header(key => 'Authorization', value => $Autorization);
#print Dumper($self->{http});
my $webcontent = $self->{http}->request(method => 'POST',post_param => ['dummy=0']);
my @code = split(/\|/,$webcontent);

switch($code[20]){
    case 'Active' {$self->{output}->output_add(severity  => 'OK',short_msg => $code[20]) }
    case 'Inactive' {$self->{output}->output_add(severity  => 'WARNING',short_msg => $code[20]) }
    case 'Spectrum Analysis' {$self->{output}->output_add(severity  => 'UNKNOWN',short_msg => $code[20]) }
    else {$self->{output}->output_add(severity  => 'CRITICAL',short_msg => $code[20]);}
}

                        $self->{output}->display();
  }
1;
