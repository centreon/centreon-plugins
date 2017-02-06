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

package apps::hddtemp::remote::mode::listdrives;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '7634' },
            "timeout:s"             => { name => 'timeout', default => '10' },
            "filter-name:s"         => { name => 'filter_name', },
            });

    $self->{result} = {};
    $self->{hostname} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my $oSocketConn = new IO::Socket::INET ( Proto      => 'tcp', 
                                             PeerAddr   => $self->{option_results}->{hostname},
                                             PeerPort   => $self->{option_results}->{port},
                                             Timeout    => $self->{option_results}->{timeout},
                                           );
    
    if (!defined($oSocketConn)) {
        $self->{output}->add_option_msg(short_msg => "Could not connect.");
        $self->{output}->option_exit();
    }

    #|/dev/sda|SD280813AS|35|C|#|/dev/sdb|ST2000CD005-1CH134|35|C|

    my $line;
    
    eval {
        local $SIG{ALRM} = sub { die "Timeout by signal ALARM\n"; };
        alarm(10);
        $line = <$oSocketConn>;
        alarm(0);
    };
    $oSocketConn->shutdown(2);
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot get informations.");
        $self->{output}->option_exit();
    }

    while ($line =~ /\|([^|]+)\|([^|]+)\|([^|]+)\|(C|F)\|/g) {
        my ($drive, $serial, $temperature, $unit) = ($1, $2, $3, $4);
               
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $drive !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping drive '" . $drive . "': no matching filter name");
            next;
        }

        $self->{result}->{$drive} = {serial => $serial, temperature => $temperature, unit => $unit};
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [temperature = " . $self->{result}->{$name}->{temperature} . $self->{result}->{$name}->{unit} . ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Drives:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'temperature']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         temperature => $self->{result}->{$name}->{temperature}
                                         );
    }
}

1;

__END__

=head1 MODE

List HDDTEMP Harddrives

=over 8

=item B<--hostname>

IP Address or FQDN of the Server

=item B<--port>

Port used by Hddtemp (Default: 7634)

=item B<--timeout>

Set Timeout for Socketconnect

=item B<--filter-name>

Filter Harddrive name (regexp can be used).

=back

=cut
