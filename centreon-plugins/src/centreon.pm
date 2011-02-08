################################################################################
# Copyright 2004-2011 MERETHIS
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
# 
# SVN : $URL$
# SVN : $Id$
#
####################################################################################
#
# Plugin init
#
package	centreon;

use Exporter();
use FindBin qw($Bin);
use lib "$FindBin::Bin";
use lib "@NAGIOS_PLUGINS@";

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use utils qw($TIMEOUT %ERRORS &print_revision &support);

if (eval "require Config::IniFiles" ) {
	use Config::IniFiles;
} else {
	print "Unable to load Config::IniFiles\n";
    exit $ERRORS{'UNKNOWN'};
}

# On d�fini une version pour les v�rifications
#$VERSION = do { my @r = (q$Revision: XXX $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_parameters);
our @EXPORT = @EXPORT_OK;

my $params_file = "@NAGIOS_PLUGINS@/centreon.conf";
my @ds = ("a","b","c","d","e","f","g","h","i","j","k","l");

###############################################################################
#  Get all parameters from the ini file
###############################################################################
sub get_parameters	{
	unless (-e $params_file)	{
		print "Unknown - In centreon.pm :: $params_file :: $!\n";
        exit $ERRORS{'UNKNOWN'};
    }
    my %centreon;
    tie %centreon, 'Config::IniFiles', ( -file => $params_file );
    return %centreon;
}

1;

__END__

=head1 NAME

centreon - shared module for Centreon plugins

=head1 SYNOPSIS

  use centreon;
  centreon::get_parameters()

=head1 DESCRIPTION

=head2 Functions


=head1 AUTHOR

Mathieu Chateau E<lt>mathieu.chateau@lsafrance.comE<gt>
Christophe Coraboeuf E<lt>ccoraboeuf@oreon-project.orgE<gt>

=cut




