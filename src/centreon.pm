###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
#
# Developped by : Julien Mathis - Romain Le Merlus 
#                 Mathavarajan Sugumaran
#
###################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
#    For information : contact@merethis.com
####################################################################
#
# Plugin init
#
package	centreon;

use Exporter   ();
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

### RRDTOOL Module
use lib qw(@RRDTOOL_PERL_LIB@ ../lib/perl);
if (eval "require RRDs" ) {
	use RRDs;
} else {
	print "Unable to load RRDs perl module\n";
    exit $ERRORS{'UNKNOWN'};
}

# On défini une version pour les vérifications
#$VERSION = do { my @r = (q$Revision: XXX $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_parameters create_rrd update_rrd fetch_rrd &is_valid_serviceid);
our @EXPORT = @EXPORT_OK;

my $params_file = "centreon.conf";
my @ds = ("a","b","c","d","e","f","g","h","i","j","k","l");

###############################################################################
#  Get all parameters from the ini file
###############################################################################
sub get_parameters	{
	$params_file = "@NAGIOS_PLUGINS@/$params_file";
	unless (-e $params_file)	{
		print "Unknown - In centreon.pm :: $params_file :: $!\n";
        exit $ERRORS{'UNKNOWN'};
    }
    my %centreon;
    tie %centreon, 'Config::IniFiles', ( -file => $params_file );
    return %centreon;
}


###############################################################################
#  Create RRD file
###############################################################################
sub create_rrd($$$$$$$)
{
	my @rrd_arg;
	my ($rrd, $nb_ds ,$start, $step, $min, $max, $type) = @_;
	$nb_ds = 1 unless($nb_ds);
	$start = time unless($start);
	$step = 300 unless($step);
	$min = "U" unless($min);
	$max = "U" unless($max);
	$type = "GAUGE" unless($type);

	my $ERROR = RRDs::error;

	@rrd_arg=($rrd,
			  "--start",
			  $start-1,
			  "--step",
			  $step);

	for ($i = 0; $i < $nb_ds; $i++) {
        push(@rrd_arg,"DS:".$ds[$i].":$type:".($step * 2).":".$min.":".$max);
     }
	push(@rrd_arg,"RRA:AVERAGE:0.5:1:8640",
             	  "RRA:MIN:0.5:12:8640",
             	  "RRA:MAX:0.5:12:8640");
	RRDs::create (@rrd_arg);
        $ERROR = RRDs::error;
        if ($ERROR) {
            print "unable to create '$rrd' : $ERROR\n" ;
            exit 3;
        }
}

###############################################################################
#  Update RRD file
###############################################################################
sub update_rrd($$@)
{
	my @rrd_arg;
	my ($rrd, $start,@values) = @_;
	$start = time unless($start);

	my $ERROR = RRDs::error;
	for (@values) {
		s/,/\./ ;
		$str_value .= ":" . $_;
		}
	RRDs::update ($rrd, "$start$str_value");
    $ERROR = RRDs::error;
    if ($ERROR) {
    	print "unable to update '$rrd' : $ERROR\n" ;
        exit 3;
     }
}

###############################################################################
#  Fetch RRD file
###############################################################################
sub fetch_rrd($$){
	my ($line, $val, @valeurs, $update_time, $step, $ds_names, $data, $i) ;
	my ($rrd, $CF, @values) = @_;
	$start = time unless($start);

	my $ERROR = RRDs::error;

	($update_time,$step,$ds_names,$data) = RRDs::fetch($rrd, "--resolution=300","--start=now-5min","--end=now",$CF);


    $ERROR = RRDs::error;
    if ($ERROR) {
    	print "unable to update '$rrd' : $ERROR\n" ;
        exit 3;
    }
    foreach $line (@$data) {
    	foreach $val (@$line) {
	    	if ( defined $val ) { $valeur[$i]=$val; } else { $valeur[$i]="undef"; }
	        $i++;
     	}
    }
    return @valeur;
}

###############################################################################
#  Is a valid ServiceId
###############################################################################

sub is_valid_serviceid {
	my $ServiceId = shift;
	if ($ServiceId && $ServiceId =~ m/^([0-9_]+)$/) {
		return $ServiceId;
	} else {
		print "Unknown -S Service ID expected... or it doesn't exist, try another id - number\n";
		exit $ERRORS{'UNKNOWN'};
	}
}

1;

__END__

=head1 NAME

centreon - shared module for Oreon plugins

=head1 SYNOPSIS

  use centreon;
  centreon::get_parameters()
  centreon::create_rrd( )
  centreon::update_rrd( )

=head1 DESCRIPTION

=head2 Functions

B<centreon::create_rrd> create a rrd database.

  create_rrd($rrd, $nb_ds ,$start, $step, $min, $max, $type );

	  $rrd : RRD filename
	  $nb_ds : Number of Data Sources to create
	  $start : Start time of RRD
	  $step : RRD step
	  $min : Minimum value in RRD
	  $max : Maximum value in RRD
	  $type : GAUGE or COUNTER

  update_rrd($rrd, $start,@values);

  	  $rrd : RRD filename to update
	  $start :
	  @values : update RRD with list values

=head1 AUTHOR

Mathieu Chateau E<lt>mathieu.chateau@lsafrance.comE<gt>
Christophe Coraboeuf E<lt>ccoraboeuf@oreon-project.orgE<gt>

=cut




