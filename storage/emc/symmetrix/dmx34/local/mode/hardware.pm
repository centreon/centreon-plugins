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

package storage::emc::symmetrix::dmx34::local::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(disk)$';
    
    $self->{cb_hook1} = 'read_files';
    $self->{cb_hook4} = 'send_email';
    
    $self->{thresholds} = {
        director => [
            ['DD state', 'CRITICAL'],
            ['Probe mode', 'CRITICAL'],
            ['not comunicating', 'CRITICAL'],
            ['unknown', 'CRITICAL'],
            ['offline', 'OK'],
            ['online', 'OK'],
            ['not configured', 'OK'],
        ],
        xcm => [
            ['emul', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        memory => [
            ['OPER/OK', 'OK'],
            ['\.\./.*', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        fru => [
            ['OK', 'OK'],
            ['.*', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::emc::symmetrix::dmx34::local::mode::components';
    $self->{components_module} = ['director', 'xcm', 'disk', 'memory', 'config', 'test', 'fru'];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{statefile_cache}->check_options(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'file-health:s'         => { name => 'file_health' },
        'file-health-env:s'     => { name => 'file_health_env' },
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

    if (!defined($self->{option_results}->{file_health}) || !defined($self->{option_results}->{file_health_env})) {
        $self->{output}->add_option_msg(short_msg => "Please set option --file-health and --file-health-env.");
        $self->{output}->option_exit();
    }
    
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
    
    # *****************************************************************
    #*            Health Check Run From Scheduler        Version 2.0 *
    #*                                                               *
    #* Serial: 000290103984            Run Time: 03/24/2016 12:27:07 *
    #* Run Type: FULL                  Code Level: 5773-184-130      *
    #*****************************************************************
 
    my ($serial, $site) = ('unknown', 'unknown');
    $serial = $1 if ($self->{content_file_health} =~ /Serial:\s*(\S+)/msi);

    $self->{output}->output_add(long_msg => sprintf('serial number: %s, site name: %s', $serial, $site));
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
        $self->{statefile_cache}->read(statefile => "cache_emc_symmetrix_dmx34_email");
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
        -attachments => $self->{option_results}->{file_health} . ',' . $self->{option_results}->{file_health_env}
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
Can be: 'director', 'xcm', 'disk', 'memory', 'config', 'fru', 'test'

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=director --filter=xcm)
Can also exclude specific instance: --filter=director,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='director,CRITICAL,^(?!(online)$)'

=item B<--warning>

Set warning threshold for disk (syntax: type,regexp,threshold)
Example: --warning='disk,.*,5:'

=item B<--critical>

Set critical threshold for disk (syntax: type,regexp,threshold)
Example: --critical='disk,.*,3:'

=item B<--file-health>

The location of the global storage file status (Should be something like: C:/xxxx/HealthCheck.log).

=item B<--file-health-env>

The location of the environment storage file status (Should be something like: C:/xxxx/HealthCheck_ENV.log).

=back

=cut
