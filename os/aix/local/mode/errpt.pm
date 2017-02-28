#
# Copyright 2017 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package os::aix::local::mode::errpt;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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
                                  "command:s"         => { name => 'command', default => 'errpt' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '' },
                                  "error-type:s"      => { name => 'error_type' },
                                  "error-class:s"     => { name => 'error_class' },
                                  "error-id:s"        => { name => 'error_id' },
                                  "retention:s"       => { name => 'retention' },
                                  "timezone:s"        => { name => 'timezone' },
                                  "description"       => { name => 'description' },
                                  "filter-resource:s" => { name => 'filter_resource' },
                                  "filter-id:s"	      => { name => 'filter_id' },
                                  "exclude-id:s"      => { name => 'exclude_id' },	
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{exclude_id}) && defined($self->{option_results}->{error_id})) {
    	$self->{output}->add_option_msg(short_msg => "Please use --error-id OR --exclude-id, these options are mutually exclusives");
    	$self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my $extra_options = '';

    if (defined($self->{option_results}->{error_type})){
        $extra_options .= ' -T '.$self->{option_results}->{error_type};
    }
    if (defined($self->{option_results}->{error_class})){
        $extra_options .= ' -d '.$self->{option_results}->{error_class};
    }
    if (defined($self->{option_results}->{error_id}) && $self->{option_results}->{error_id} ne ''){
    	$extra_options.= ' -j '.$self->{option_results}->{error_id};
    }
    if (defined($self->{option_results}->{exclude_id}) && $self->{option_results}->{exclude_id} ne ''){
    	$extra_options.= ' -k '.$self->{option_results}->{exclude_id};
    }
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} ne ''){
        my $retention = time() - $self->{option_results}->{retention};
        if (defined($self->{option_results}->{timezone})){
            $ENV{TZ} = $self->{option_results}->{timezone};
        }
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($retention);
        $year = $year - 100;
        if (length($sec)==1){
            $sec = '0'.$sec;
        }
        if (length($min)==1){
            $min = '0'.$min;
        }
        if (length($hour)==1){
            $hour = '0'.$hour;
        }
        if (length($mday)==1){
            $mday = '0'.$mday;
        }
        $mon = $mon + 1;
        if (length($mon)==1){
            $mon = '0'.$mon;
        }
        $retention = $mon.$mday.$hour.$min.$year;
        $extra_options .= ' -s '.$retention;
    }
    
    $extra_options .= $self->{option_results}->{command_options};

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $extra_options);
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        
        my ($identifier, $timestamp, $resource_name, $description) = ($1, $2, $5, $6);
        $self->{result}->{$timestamp.'~'.$identifier.'~'.$resource_name} = {description => $description};
    }
}

sub run {
    my ($self, %options) = @_;
    my $extra_message = '';
    
    if (defined($self->{option_results}->{retention})) {
        $extra_message = ' since ' . $self->{option_results}->{retention} . ' seconds';
    }
    
    $self->manage_selection();
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("No error found%s.", $extra_message));
    
    my $total_error = 0;
    foreach my $errpt_error (sort(keys %{$self->{result}})) {
	    my @split_error = split ('~',$errpt_error);
	    my $timestamp = $split_error[0];
        my $identifier = $split_error[1];
        my $resource_name = $split_error[2];
        my $description = $self->{result}->{$errpt_error}->{description};
        
        next if (defined($self->{option_results}->{filter_resource}) && $self->{option_results}->{filter_resource} ne '' &&
                 $resource_name !~ /$self->{option_results}->{filter_resource}/);
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
                 $identifier !~ /$self->{option_results}->{filter_id}/);
        $total_error++;
        if (defined($self->{option_results}->{description})) {
            $self->{output}->output_add(long_msg => sprintf("Error '%s' Date: %s ResourceName: %s Description: %s", $identifier,
                                                $timestamp, $resource_name, $description));           
        } else {
            $self->{output}->output_add(long_msg => sprintf("Error '%s' Date: %s ResourceName: %s", $identifier,
                                                $timestamp, $resource_name));
        }
    }

    if ($total_error != 0) {
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => sprintf("%s error(s) found(s)%s", $total_error, $extra_message));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check errpt messages.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'errpt').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--error-type>

Filter error type separated by a coma (INFO, PEND, PERF, PERM, TEMP, UNKN).

=item B<--error-class>

Filter error class ('H' for hardware, 'S' for software, '0' for errlogger, 'U' for undetermined).

=item B<--error-id>

Filter specific error code (can be a comma separated list).

=item B<--retention>

Retention time of errors in seconds.

=item B<--verbose>

Print error description in long output. [ Error 'CODE' Date: Timestamp ResourceName: RsrcName Description: Desc ]

=item B<--filter-resource>

Filter resource (can use a regexp).

=item B<--filter-id>

Filter error code (can use a regexp).

=item B<--exclude-id>

Filter on specific error code (can be a comma separated list).

=back

=cut
