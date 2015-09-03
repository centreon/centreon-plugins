################################################################################
# Copyright 2005-2013 MERETHIS
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

package cloud::aws::plugin;

use strict;
use warnings;
#use base qw(centreon::plugins::script_custom);
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'instancestate'    => 'cloud::aws::mode::instancestatus',
                         'list'    => 'cloud::aws::mode::list',
                         'cloudwatch'    => 'cloud::aws::mode::cloudwatch',
                         );

    #$self->{custom_modes}{awscli} = 'cloud::aws::custom::awscli';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Amazon AWS cloud.

=over 8

For this plugin to work, you have to install and configure:
awscli (http://docs.aws.amazon.com/cli/latest/userguide/installing.html#install-bundle-other-os).
perl-DateTime
perl-Module-Load
perl-YAML
perl-File-Slurp.noarch
perl-Pod-Coverage
openssl-devel

CPAN:
Data::Printer
HTTP::Tiny
PerlIO::utf8_strict
Paws
=back

=cut
