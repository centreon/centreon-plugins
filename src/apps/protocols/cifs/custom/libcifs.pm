#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::protocols::cifs::custom::libcifs;

use strict;
use warnings;
use Filesys::SmbClient;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>  {
            'hostname:s'      => { name => 'hostname' },
            'timeout:s'       => { name => 'timeout' },
            'port:s'          => { name => 'port' },
            'workgroup:s'     => { name => 'workgroup' },
            'cifs-username:s' => { name => 'cifs_username' },
            'cifs-password:s' => { name => 'cifs_password' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CIFS OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 139;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /^\d+$/? $self->{option_results}->{timeout} : 30;
    $self->{cifs_username} = (defined($self->{option_results}->{cifs_username})) ? $self->{option_results}->{cifs_username} : '';
    $self->{cifs_password} = (defined($self->{option_results}->{cifs_password})) ? $self->{option_results}->{cifs_password} : '';
    $self->{workgroup} = (defined($self->{option_results}->{workgroup})) ? $self->{option_results}->{workgroup} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set option --hostname.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub init_cifs {
    my ($self, %options) = @_;

    if (!defined($self->{cifs})) {
        $self->{cifs} = new Filesys::SmbClient(
            username  => $self->{cifs_username},
            password  => $self->{cifs_password},
            workgroup => $self->{workgroup},
            debug => $self->{output}->is_debug() ? 10 : 0
        );
    }
}

sub list_directory {
    my ($self, %options) = @_;

    $self->init_cifs();

    my $fd = $self->{cifs}->opendir('smb://' . $self->{hostname} . (defined($options{directory}) ? $options{directory} : ''));
    if (!defined($fd)) {
        return (1, $!);
    }

    my $files = [];
    while (my $file = $self->{cifs}->readdir_struct($fd)) {
        push @$files, $file;
    }
    $self->{cifs}->close($fd);

    return (0, '', $files);
}

sub read_file {
    my ($self, %options) = @_;

    $self->init_cifs();

    my $fd = $self->{cifs}->open('smb://' . $self->{hostname} . $options{file}, 0600);
    if (!defined($fd)) {
        return (1, "Can't read file: $!");
    }

    my $data = '';
    while (1) {
        my $buffer = $self->{cifs}->read($fd);
        last if (!defined($buffer) || $buffer eq '');

        $data .= $buffer;
    }

    $self->{cifs}->close($fd);
    return  (0, '', $data);
}

sub write_file {
    my ($self, %options) = @_;

    $self->init_cifs();

    my $fd = $self->{cifs}->open('>smb://' . $self->{hostname} . $options{file}, 0600);
    if (!defined($fd)) {
        return (1, "Can't create file: $!");
    }

    my $data = defined($options{content}) ? $options{content} : '';
    if (!$self->{cifs}->write($fd, $data)) {
        return (1, $!);
    }

    $self->{cifs}->close($fd);

    return  (0, '');
}

sub delete_file {
    my ($self, %options) = @_;

    $self->init_cifs();

    if ($self->{cifs}->unlink('smb://' . $self->{hostname} . $options{file}) == 0) {
        return (1, "Can't unlink file: $!");
    }

    return  (0, '');
}

sub stat_file {
    my ($self, %options) = @_;

    $self->init_cifs();

    my @stat = $self->{cifs}->stat('smb://' . $self->{hostname} . $options{file});
    if ($#stat == 0) {
        return { code => 1, message => "Stat error: $!" };
    }

    return { code => 0, mtime => $stat[11], size => $stat[7] };
}

1;

__END__

=head1 NAME

CIFS connector library

=head1 SYNOPSIS

my cifs connector

=head1 CIFS OPTIONS

=over 8

=item B<--hostname>

Set server hostname (required).

=item B<--port>

Set port.

=item B<--timeout>  

Timeout in seconds for connection (defaults: 30)

=item B<--workgroup>

Set workgroup.

=item B<--cifs-username>

Set username.

=item B<--cifs-password>

Set password.

=back

=head1 DESCRIPTION

B<custom>.

=cut
