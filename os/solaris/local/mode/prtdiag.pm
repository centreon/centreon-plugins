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

# Main code: Comes from Sebastien Phelep (seb@le-seb.org)

package os::solaris::local::mode::prtdiag;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use File::Basename;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'prtdiag' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/platform/`/sbin/uname -i`/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-v 2>&1' },
                                  "config-file:s"     => { name => 'config_file' },
                                });
    $self->{conf} = {};
    $self->{syst} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (defined($self->{option_results}->{config_file})) {
        $self->{config_file} = $self->{option_results}->{config_file};
    } else {
        $self->{config_file} = dirname(__FILE__) . '/../conf/prtdiag.conf';
    }
}

sub prtdiag {
    my ($self, %options) = @_;
    
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    
    my @diag = split (/\n/, $stdout);
    
    # Look for system type
    unless( defined($self->{syst}) ) {
        FSYS:
        foreach my $section ( keys(%{$self->{conf}}) ) {
            foreach my $param ( keys(%{ $self->{conf}->{$section} }) ) {
                next unless( $param eq "system.match" );
                if( grep(/$self->{conf}->{$section}->{'system.match'}/, @diag) ) {
                    $self->{syst} = $section;
                    last FSYS;
                }
            }
        }
    }

    # Check for unidentified system type
    unless( defined($self->{syst}) ) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Unable to identify system type !");
        return ;
    }
    $self->{output}->output_add(long_msg => "Using system type : $self->{syst}");
               
    # Further config checks
    unless( defined($self->{conf}->{$self->{syst}}->{'system.checks'}) ) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Initialization failed - Missing 'system.checks' entry for section '$self->{syst}' in file '$self->{config_file}' !");
        return ;
    }
    my @checks = split(/\s*,\s*/,$self->{conf}->{$self->{syst}}->{'system.checks'});
    if( scalar(@checks) == 0 ) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "No check defined in 'system.checks' entry for section '$self->{syst}' in file '$self->{config_file}' !");
        return ;
    }
    foreach my $check ( @checks ) {
        foreach my $param ( "description", "begin_match", "end_match", "data_match", "data_labels", "ok_condition", "output_string" ) {
            my $param_name = "checks.$check.$param";
            unless( defined($self->{conf}->{$self->{syst}}->{$param_name}) ) {
                $self->{output}->output_add(severity => 'UNKNOWN', 
                                            short_msg => "Initialization error - Missing '$param_name' entry for section '$self->{syst}' in file '$self->{config_file}' !");
                return ;
            }
        }
    }

    # Check'em all
    my @failed = ();
    my @passed = ();
    foreach my $check ( @checks ) {
        # Get associated data
        my $description = $self->{conf}->{$self->{syst}}->{"checks.$check.description"};
        my @labels = split(/\s*,\s*/,$self->{conf}->{$self->{syst}}->{"checks.$check.data_labels"});
        my $fetch_mode = $self->{conf}->{$self->{syst}}->{"checks.$check.fetch_mode"};
        my $begin = 0;
        my $dcount = 0;
        my $lcount = 0;
        my %data = ();
        
        $self->{output}->output_add(long_msg => "Checking $description:");

        # Parse prtdiag output
        DIAG: foreach( @diag ) {
            unless( $begin ) {
                # Looking for begin pattern
                next DIAG unless( m/$self->{conf}->{$self->{syst}}->{"checks.$check.begin_match"}/ );
                s/$self->{conf}->{$self->{syst}}->{"checks.$check.begin_match"}//;
                $begin = 1;
            } else {
                # Stop parsing if matched end pattern
                last DIAG if( m/$self->{conf}->{$self->{syst}}->{"checks.$check.end_match"}/ );
            }
            
            # Skip unwanted data
            if( defined($self->{conf}->{$self->{syst}}->{"checks.$check.skip_match"}) ) {
                next DIAG if( m/$self->{conf}->{$self->{syst}}->{"checks.$check.skip_match"}/ );
            }
            
            # Reinit read values
            my @values = ();
            
            # === Fetching data in linear mode === #
            if( defined($fetch_mode) and ($fetch_mode eq "linear") ) {
                # Use specified regexp separator, or define a default one
                my $regexp_separator = $self->{conf}->{$self->{syst}}->{"checks.$check.data_match_regsep"} || '\s*,\s';

                # Extract regular expresssions to be used for data collection
                my @dmatch = split(/\s*,\s*/,$self->{conf}->{$self->{syst}}->{"checks.$check.data_match"});
                
                # Take care of counters
                if( $lcount >= scalar(@labels) ) {
                    $lcount = 0;
                    $dcount = $dcount + scalar(@labels) + 1;
                }
                
                # Get all matching values
                @values = m/$dmatch[$lcount]/g;
                
                # Update our hash
                for( my $i=0; $i < scalar(@values); $i++ ) {
                    $data{($dcount+$i)}->{$labels[$lcount]} = centreon::plugins::misc::trim($values[$i]);
                }
                $lcount++;
                
                # Next one
                next DIAG;
            }
            # === Fetching data otherwise (aka tabular mode) === #
            else {
                # Next one if this does not match
                next DIAG unless( @values = m/$self->{conf}->{$self->{syst}}->{"checks.$check.data_match"}/g );
                
                # Update our hash
                for( my $i=0; $i < scalar(@values); $i++ ) {
                    # Take care of counters
                    if( $lcount >= scalar(@labels) ) {
                        $lcount = 0;
                        $dcount++;
                    }
                    
                    $data{$dcount}->{$labels[$lcount]} = centreon::plugins::misc::trim($values[$i]);
                    $lcount++;
                }
            }
        }
        
        # Check collected data
        my $errors = 0;
        my $tests = 0;
        foreach my $dataset ( keys(%data) ) {
            my $test_result = "";
            my $ok_condition = $self->{conf}->{$self->{syst}}->{"checks.$check.ok_condition"};
            my $output_string = $self->{conf}->{$self->{syst}}->{"checks.$check.output_string"};

            # Substitute labels in condition and output string
            foreach my $label ( keys( %{ $data{$dataset} } ) ) {
                $ok_condition =~ s/%$label%/$data{$dataset}->{$label}/g;
                $output_string =~ s/%$label%/$data{$dataset}->{$label}/g;
            }
            
            # Test condition
            if( eval($ok_condition) ) {
                # Test passed
                $test_result = "INF - $output_string";
                push(@passed,$output_string);
            } else {
                # Test failed
                $test_result = "ERR - $output_string";
                push(@failed,$output_string);
                $errors++;
                
            }
            $tests++;
            $self->{output}->output_add(long_msg => " $test_result");
        }
        $self->{output}->output_add(long_msg => "Checked $tests component".( $tests le 1 ? "" : "s").", found ".( $errors == 0 ? "no error" : "$errors errors." ));
    }
    
    my $checked = scalar(@passed) + scalar(@failed);
    if( scalar(@failed) > 0 ) {
        $self->{output}->output_add(severity => 'CRITICAL', 
                                    short_msg => "Checked $checked component" . ( $checked le 1 ? "" : "s") . ", found " . scalar(@failed) . " errors : " . join(', ',@failed));
        $self->{output}->output_add(long_msg => join("\n",@passed));
    } elsif( $checked == 0 ) {
        $self->{output}->output_add(severity => 'WARNING', 
                                    short_msg => "Found nothing to check !");
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Successfully checked $checked component" . ( $checked le 1 ? "" : "s"));
        $self->{output}->output_add(long_msg => join("\n", @passed));
    }
}

sub run {
    my ($self, %options) = @_;

    $self->load_prtdiag_config();
    $self->prtdiag();
    $self->{output}->display();
    $self->{output}->exit();
}

sub load_prtdiag_config {
    my ($self, %options) = @_;

    unless( open(CONFIG,"<$self->{config_file}") ) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Initialization error - unable to open file '" . $self->{config_file} . "' : $!");
        $self->{output}->display();
        $self->{output}->exit();
    }
    my $section = undef;
    while(<CONFIG>) {
        chomp();

        # Remove comments
        s/#.*//;
    
        # Ignore blank lines
        next if( m/^\s*$/ );
    
        if( m/^\s*\[\s*(.*?)\s*\]\s*$/ ) {
            $section = $1;
            next;
        } elsif( m/^\s*(.*?)\s*=\s*(.*?)\s*$/ ) {
            $self->{conf}->{$section}->{$1} = $2 if( defined($section) );
        }
    }
    close (CONFIG);
}

1;

__END__

=head1 MODE

Check Sun Hardware with 'prtdiag' command.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'prtdiag').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/platform/`/sbin/uname -i`/sbin').

=item B<--command-options>

Command options (Default: '-v 2>&1').

=item B<--config-file>

Config file with prtdiag output description (Default: Directory 'conf/prtdiag.conf' under absolute mode path).

=back

=cut
