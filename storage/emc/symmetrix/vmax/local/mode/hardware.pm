#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package storage::emc::symmetrix::vmax::local::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(sparedisk)$';
    
    $self->{cb_hook1} = 'read_files';
    $self->{cb_hook4} = 'send_email';
    
    $self->{thresholds} = {
        default => [
            ['Recoverable Error', 'OK'], # Fabric
            ['Online', 'OK'],
            ['Up', 'OK'],
            ['OK', 'OK'],
            ['.*', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::emc::symmetrix::vmax::local::mode::components';
    $self->{components_module} = ['module', 'temperature', 'director', 'cabling', 'power', 'fabric', 'voltage', 'sparedisk'];
}

sub find_files {
    my ($self, %options) = @_;

    if (!opendir(DIR, $self->{option_results}->{health_directory})) {
        $self->{output}->add_option_msg(short_msg => "Cannot open directory: $!");
        $self->{output}->option_exit();
    }
    
    my $save_value = 0;
    while (my $file = readdir(DIR)) {
        next if (! -d $self->{option_results}->{health_directory} . '/' . $file || 
            $file !~ /$self->{option_results}->{health_directory_pattern}/);
        if (hex($1) > $save_value) {
            $self->{option_results}->{file_health} = $self->{option_results}->{health_directory} . '/' . $file . '/' . $self->{option_results}->{file_health_name};
            $self->{option_results}->{file_health_env} = $self->{option_results}->{health_directory} . '/' . $file . '/' . $self->{option_results}->{file_health_env_name};
            $save_value = hex($1);
        }
    }

    closedir(DIR);
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{statefile_cache}->check_options(%options);
   
   if (!defined($self->{option_results}->{file_health_name}) || !defined($self->{option_results}->{file_health_env_name})) {
        $self->{output}->add_option_msg(short_msg => "Please set option --file-health-name and --file-health-env-name.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{health_directory}) || ! -d $self->{option_results}->{health_directory}) {
        $self->{output}->add_option_msg(short_msg => "Please set right option for --health-directory.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{health_directory_pattern})) {
        $self->{output}->add_option_msg(short_msg => "Please set option for --health-directory-pattern.");
        $self->{output}->option_exit();
    }
    
    $self->find_files();
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'health-directory:s'         => { name => 'health_directory' },
        'health-directory-pattern:s' => { name => 'health_directory_pattern' },
        'file-health-name:s'         => { name => 'file_health_name', default => 'HealthCheck.log' },
        'file-health-env-name:s'     => { name => 'file_health_env_name', default => 'sympl_env_health.log' },
        # Email
        'email-warning:s'       => { name => 'email_warning' },
        'email-critical:s'      => { name => 'email_critical' },
        'email-smtp-host:s'     => { name => 'email_smtp_host' },
        'email-smtp-username:s' => { name => 'email_smtp_username' },
        'email-smtp-password:s' => { name => 'email_smtp_password' },
        'email-smtp-from:s'     => { name => 'email_smtp_from' },
        'email-smtp-options:s@' => { name => 'email_smtp_options' },
        'email-memory'          => { name => 'email_memory' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{components_exec_load} = 0;
    return $self;
}

sub read_files {
    my ($self, %options) = @_;
    
    foreach (('file_health', 'file_health_env')) {
        $self->{'content_' . $_} = do {
            local $/ = undef;
            if (!open my $fh, "<", $self->{option_results}->{$_}) {
                $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{$_} : $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
        # We remove color syntax
        $self->{'content_' . $_} =~ s/\x{1b}\[.*?m|\r//msg;
    }
    
    #Health Check Results Log:
    #Service Processor Date: 06/15/2016 09:26:41
    #Symmetrix Date from director 07c: 06/15/2016 09:33:45
    #The time difference between Service Processor and Symmetrix is : 00:07:03.672
    #System SN: 000292602920
    #System Model: VMAX20K
    #mCode Level: 5876.288
    my ($serial) = ('unknown');
    $serial = $1 if ($self->{content_file_health} =~ /System SN:\s*(\S+)/msi);

    $self->{output}->output_add(long_msg => sprintf('serial number: %s', $serial));
}

#
# maybe we should add it in core (with cleaner code ;)
#

sub send_email {
    my ($self, %options) = @_;
    
    #######
    # Check SMTP options
    return if (!((defined($self->{option_results}->{email_warning}) && $self->{option_results}->{email_warning} ne '')
        || (defined($self->{option_results}->{email_critical}) && $self->{option_results}->{email_critical} ne '')));
    
    if (!defined($self->{option_results}->{email_smtp_host})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --email-smtp-host option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{email_smtp_from})) {
        $self->{output}->add_option_msg(short_msg => "Please set --email-smtp-from option");
        $self->{output}->option_exit();
    }
    
    my %smtp_options = ('-auth' => 'none');
    if (defined($self->{option_results}->{email_smtp_username}) && $self->{option_results}->{email_smtp_username} ne '') {
        $smtp_options{-login} = $self->{option_results}->{email_smtp_username};
        delete $smtp_options{-auth};
    }
    if (defined($self->{option_results}->{email_smtp_username}) && defined($self->{option_results}->{email_smtp_password})) {
        $smtp_options{-pass} = $self->{option_results}->{email_smtp_password};
    }    
    
    #######
    # Get current data
    my $stdout;
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        $self->{output}->display(force_long_output => 1);
    }
    
    $stdout =~ /^(.*?)(\||\n)/msi;
    my $subject = $1;
    my $status = lc($self->{output}->get_litteral_status());
    
    foreach my $option (@{$self->{option_results}->{email_smtp_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        my ($label, $value) = ($1, $2);
        if ($label =~ /subject/i) {
            $value =~ s/%\{status\}/$status/g;
            $value =~ s/%\{short_msg\}/$subject/g;
            $label = lc($label);
        }
        $smtp_options{-$label} = $value;
    }
    
    my $send_email = 0;
    $send_email = 1 if ($status ne 'ok');
    #######
    # Check memory file
    if (defined($self->{option_results}->{email_memory})) {
        $self->{new_datas} = { status => $status, output => $subject };
        $self->{statefile_cache}->read(statefile => "cache_emc_symmetrix_vmax_email");
        my $prev_status = $self->{statefile_cache}->get(name => 'status');
        my $prev_output = $self->{statefile_cache}->get(name => 'output');
        # non-ok output is the same
        $send_email = 0 if ($status ne 'ok' && defined($prev_output) && $prev_output eq $subject);
        # recovery email
        $send_email = 1 if ($status eq 'ok' && defined($prev_status) && $prev_status ne 'ok');
        $self->{statefile_cache}->write(data => $self->{new_datas});
    }
    
    my $smtp_to = '';
    $smtp_to = $self->{option_results}->{email_warning} if ($status eq 'warning' && defined($self->{option_results}->{email_warning} && $self->{option_results}->{email_warning}) ne '');
    $smtp_to = $self->{option_results}->{email_critical} if ($status eq 'critical' && defined($self->{option_results}->{email_critical} && $self->{option_results}->{email_critical}) ne '');
    if ($send_email == 1 && $status eq 'ok') {
        my $append = '';
        foreach (('email_warning', 'email_critical')) {
            if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '') {
                $smtp_to .= $append . $self->{option_results}->{$_};
                $append .= ',';
            }
        }
    }
    
    if ($send_email == 0) {
        $self->{output}->add_option_msg(severity => 'OK', short_msg => "No email to send");
        return ;
    }
    
    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Email::Send::SMTP::Gmail',
        error_msg => "Cannot load module 'Email::Send::SMTP::Gmail'."
    );
    my ($mail, $error) = Email::Send::SMTP::Gmail->new(
        -smtp => $self->{option_results}->{email_smtp_host},
        %smtp_options
    );
    if ($mail == -1) {
        $self->{output}->add_option_msg(short_msg => "session error: " . $error);
        $self->{output}->option_exit();
    }
    my $result = $mail->send(
        -to => $smtp_to,
        -from => $self->{option_results}->{email_smtp_from},
        -subject => defined($smtp_options{-subject}) ? $smtp_options{-subject} : $subject,
        -body => $stdout,
        -attachments => $self->{option_results}->{file_health} . "," . $self->{option_results}->{file_health_env}
    );
    $mail->bye();
    if ($result == -1) {
        $self->{output}->add_option_msg(severity => 'UNKNOWN', short_msg => "problem to send the email");
    } else {
        $self->{output}->add_option_msg(severity => 'OK', short_msg => "email sent");
    }
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'module', 'temperature', 'director, 'cabling', 'power', 'voltage', 'sparedisk'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=module)
Can also exclude specific instance: --filter=temperature,ES-PWS-A ES-4

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='director,WARNING,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for disk (syntax: type,regexp,threshold)
Example: --warning='sparedisk,.*,5:'

=item B<--critical>

Set critical threshold for disk (syntax: type,regexp,threshold)
Example: --critical='sparedisk,.*,3:'

=item B<--health-directory>

Location of health files.

=item B<--health-directory-pattern>

Set pattern to match the most recent directory (getting the hexa value).

=item B<--file-health-name>

Name of the global storage file status (Default: HealthCheck.log).

=item B<--file-health-env-name>

Name of the environment storage file status (Default: sympl_env_health.log).

=back

=cut
