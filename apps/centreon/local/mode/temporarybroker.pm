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
# Authors : Simon BOMM <sbomm@centreon.com>
#
####################################################################################

package apps::centreon::local::mode::temporarybroker;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use XML::LibXML;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                 "rrd-config-file:s"    => { name => 'rrd_config_file', default => 'central-rrd.xml' },
                                 "sql-config-file:s"    => { name => 'sql_config_file', default => 'central-broker.xml' },
                                 "config-path:s"          => { name => 'config_path', default => '/etc/centreon-broker/' },
                                 "broker-temporary-dir:s" => { name => 'broker_temporary_dir', default => '/var/lib/centreon-broker/' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if ($self->{option_results}->{config_path} !~ /\/$/) {
        $self->{output}->add_option_msg(short_msg => "Please set the last / the path to your config-path option");
        $self->{output}->option_exit();
    }
    if (! -e $self->{option_results}->{broker_temporary_dir}) {
        $self->{output}->add_option_msg(short_msg => "Directory specified with --broker-temporary-dir does not exist !");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $parser = XML::LibXML->new();
    my $count = 0;
    my $filename;
    my $filesize;
    my @configFiles;
    my @temporaryFiles;

    push @configFiles, $self->{option_results}->{config_path}.$self->{option_results}->{rrd_config_file}, $self->{option_results}->{config_path}.$self->{option_results}->{sql_config_file};
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'No temporary files, centreon-broker outputs performances are OK');
   
    foreach my $file (@configFiles) {
        my $config = $parser->parse_file($file);
        foreach my $data ($config->findnodes('/centreonBroker/temporary/path')) {
            
            $filename = $data->to_literal;
            $filename =~ s/^.*\/(.*)$/$1/;
            if (-f $data->to_literal) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("%s ", $filename)
                                           );
                push @temporaryFiles, $filename;
                print "TAB @temporaryFiles\n";
            }
        }    
   } 
   
   opendir(my $dh, $self->{option_results}->{broker_temporary_dir}) or die "Petit chaton mort\n";
   
   while (my $file = readdir($dh)) {               

       foreach my $filename (@temporaryFiles) {
           
           next if $file =~ m/^\./ or $file =~ m/stats/;

           if ($file eq $filename) {            
               
               my $countRet = 1;
               $filesize = -s $self->{option_results}->{broker_temporary_dir}.$filename;
               $filesize = $filesize / 1024;
               $self->{output}->output_add(long_msg => sprintf("%s exists (size: %i MB)", $file, $filesize));
               my $filePart = $self->{option_results}->{broker_temporary_dir}.$filename.".".$countRet;
               
               if (-f $filePart) {
                   $filesize = -s $filePart;
                   $filesize = $filesize / 1024;
                   $self->{output}->output_add(long_msg => sprintf("%s exists (size: %i MB)", $filename.".".$countRet, $filesize));
                  
                   while(-f $filePart) {
                       $countRet++;
                       $filePart = $self->{option_results}->{broker_temporary_dir}.$filePart.$countRet;
                       
                       if (-f $filePart) {
                           $self->{output}->output_add(long_msg => sprintf("%s exists (size: %i MB)", $filename.".".$countRet, $filesize));
                       }

                   }
    
               }
                           
           }
       
       }
    
    } 


    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check if one of centreon-broker output is slow and temporary files are presents. CRITICAL STATE ONLY

=over 8

=item B<--rrd-config-file>

Specify the name of your master rrd config-file (default: central-rrd.xml)

=item B<--sql-config-file>

Specify the name of your master sql config file (default: central-broker.xml)

=item B<--config-path>

Specify the path to your broker config files (defaut: /etc/centreon-broker/)

=item B<--broker-retention-dir>

Specify the path to your broker retention directory (defaut: /var/lib/centreon-broker/)

=back

=cut
