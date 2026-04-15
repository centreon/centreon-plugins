#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::plugins::lockfile;

use strict;
use warnings;
use Fcntl qw(:DEFAULT);

my $default_dir = '/var/lib/centreon/centplugins';
if ($^O eq 'MSWin32') {
    $default_dir = 'C:/Windows/Temp';
}

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'lockfile-dir:s'      => { name => 'lockfile_dir', default => $default_dir },
        'lockfile:s'          => { name => 'lockfile', default => 'centplugins.lock' },
        'retry:s'             => { name => 'retry', default => 10 },
        'retry-interval:s'    => { name => 'retry_interval', default => 14 },
        'lock-expiration-timeout:s' => { name => 'lock_expiration_timeout', default => 0 },
        'unlock-stale:s'      => { name => 'unlock_stale', default => 1 },
    }) if $options{options};

    $self->{output} = $options{output};

    $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};

    $self->{output}->exit_options(short_msg => "Missing lock filename !")
         unless $self->{option_results}->{lockfile};

    $self->{output}->exit_options(short_msg => "Missing lockfile_dir !")
         unless $self->{option_results}->{lockfile_dir};
}


sub try_lock {
    my ($self, %options) = @_;

    if ($self->{filename}) {
        $self->{output}->output_add(long_msg => "Lock file already alive: ".$self->{filename}, debug => 1)
            if $self->{output};
        return 0;
    }

    $self->{filename} = $self->{option_results}->{lockfile_dir} . '/' . $self->{option_results}->{lockfile};

    my $fh;
    if (-e $self->{filename} && ($self->{option_results}->{lock_expiration_timeout} > 0 || $self->{option_results}->{'unlock_stale'})) {
        if (open($fh, '<', $self->{filename})) {
            my ($pid, $timestamp) = <$fh>;
            close($fh);
            chomp $pid if $pid;
            chomp $timestamp if $timestamp;

            if ($self->{option_results}->{lock_expiration_timeout} && $timestamp && $timestamp =~ /^\d+$/) {
                if (time() - $timestamp > $self->{option_results}->{lock_expiration_timeout}) {
                    $self->{output}->output_add(long_msg => "Lock file expired: ".$self->{filename}, debug => 1)
                        if $self->{output};
                    unlink($self->{filename});
                }
            }
            if ($self->{option_results}->{'unlock_stale'} && $pid && $pid =~ /^\d\d+$/) {
                unless (kill(0, $pid)) {
                    $self->{output}->output_add(long_msg => "Lock file process is not alive ($pid): ".$self->{filename}, debug => 1)
                        if $self->{output};
                    unlink($self->{filename});
                }
            }
        }
    }

    unless (sysopen($fh, $self->{filename}, O_WRONLY | O_CREAT | O_EXCL)) {
        $self->{output}->output_add(long_msg => "Cannot create lock file '".$self->{filename}."' : $!", debug => 1)
            if $self->{output};
        undef $self->{filename};
        return 0;
    }
    print $fh "$$\n".time()."\n";
    close($fh);

    $self->{output}->output_add(long_msg => "Create lock file: ".$self->{filename}, debug => 1)
        if $self->{output};

    return 1;
}

sub lock_file {
    my ($self, %options) = @_;

    my $try = 0;
    my $lock = 0;

    while (1) {
        $lock = $self->try_lock();
        last if $lock;

        if ($self->{option_results}->{retry} > 0 && $try >= $self->{option_results}->{retry}) {
            $self->{output}->output_add(long_msg => "Cannot create lock file after $try tries", debug => 1)
                if $self->{output};
            return 0;
        }

        sleep($self->{option_results}->{retry_interval});
        $try++;
    }

    return 1;
}

sub is_locked {
    my ($self, %options) = @_;

    return $self->{filename} ? 1 : 0;
}

sub unlock {
    my ($self, %options) = @_;

    if ($self->{filename} && -e $self->{filename}) {
       
        unless (unlink($self->{filename})) {
            $self->{output}->output_add(long_msg => "Cannot delete lock file ".$self->{filename}.": $!", debug => 1)
                if $self->{output};
            return 0;
        }
        $self->{output}->output_add(long_msg => "Delete lock file ".$self->{filename}, debug => 1)
            if $self->{output};
    }

    undef $self->{filename};

    return 1;
}

sub DESTROY {
    my ($self) = @_;

    $self->unlock();
}

1;

__END__

=head1 NAME

centreon::plugins::lockfile - A module for managing lock files

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides methods to create, check, and remove lock files. It is useful for preventing multiple instances of a script from running simultaneously.

=head1 METHODS

=head2 new

    my $obj = centreon::plugins::lockfile->new(%options);

Creates a new instance of the C<lockfile> object.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<lockfile-dir> - The directory where the lock file will be created (default: C</var/lib/centreon/centplugins> or C<C:/Windows/Temp> on Windows).

=item * C<lockfile> - The name of the lock file (default: C<centplugins.lock>).

=item * C<retry> - The number of times to retry acquiring the lock (default: 10).

=item * C<retry-interval> - The interval in seconds between retry attempts (default: 14).

=item * C<lock-expiration-timeout> - The time in seconds after which a lock file is considered expired (default: 0, meaning no expiration).

=item * C<unlock-stale> - Whether to automatically unlock stale lock files (default: 1, meaning enabled). A stale lock file is one that has a PID that is not currently running.

=back

=back

=head2 try_lock

    $obj->try_lock();

Try to acquire a lock by creating a lock file. If the lock file already exists, it checks for expiration and stale processes before attempting to create a new lock file.

=over 4

=item * C<%options> - A hash of options.

=back

=head2 lock_file
    
    $obj->lock_file();

Acquire a lock by repeatedly trying to create a lock file until it succeeds or reaches the maximum number of retries.

=over 4

=item * C<%options> - A hash of options.

=back

=head2 is_locked

    $obj->is_locked();

Returns true if a lock file is currently active, false otherwise.

=over 4

=item * C<%options> - A hash of options.

=back

=head2 unlock

    $obj->unlock();

Removes the lock file if it exists.

=over 4

=item * C<%options> - A hash of options.

=back

=cut
