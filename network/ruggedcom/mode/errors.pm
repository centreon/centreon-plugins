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

package network::ruggedcom::mode::errors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_rcDeviceError = '.1.3.6.1.4.1.15004.4.2.1';
my $oid_rcDeviceErrWatchdogReset = '.1.3.6.1.4.1.15004.4.2.1.2.0';

my $thresholds = {
    error => [
        ['true', 'CRITICAL'],
        ['false', 'OK'],
    ],
};

my %map_errors = (
    2 => 'WatchdogReset',
    3 => 'ConfigurationFailure',
    4 => 'CrashLogCreated',
    5 => 'StackOverflow',
    6 => 'HeapError',
    7 => 'DateAndTimeSetFailed',
    8 => 'NtpServerUnreachable',
    9 => 'BootPTftpTrFailed',
    10 => 'RadiusServerUnreachable',
    11 => 'TacacsServerUnreachable',
);

my %map_state = (
    1 => 'true',
    2 => 'false',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"         => { name => 'exclude' },
                                  "no-errors:s"       => { name => 'no_errors' },
                                });
  
    $self->{components} = {};
    $self->{no_errors} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_errors})) {
        if ($self->{option_results}->{no_errors} ne '') {
            $self->{no_errors} = $self->{option_results}->{no_errors};
        } else {
            $self->{no_errors} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->{results} = $self->{snmp}->get_table(oid => $oid_rcDeviceError, start => $oid_rcDeviceErrWatchdogReset);
    $self->check_errors();
    
    my $total_errors =  $self->{components}->{error}->{total};
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s device errors are ok.", 
                                                     $total_errors
                                                     )
                                );

    if (defined($self->{option_results}->{no_errors}) && $total_errors == 0) {
        $self->{output}->output_add(severity => $self->{no_errors},
                                    short_msg => 'No errors are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)#\Q$options{instance}\E#/) {
        $self->{components}->{$options{section}}->{skip}++;
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{instance} instance."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 

    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub check_errors {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking errors");
    $self->{components}->{error} = {name => 'errors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'error'));

    for (my $i = 1; $i <= 11; $i++) {
        next if (!defined($self->{results}->{$oid_rcDeviceError . '.' . $i . '.0'}));
        my $instance = $map_errors{$i};
        my $state = $self->{results}->{$oid_rcDeviceError . '.' . $i . '.0'};

        next if ($self->check_exclude(section => 'error', instance => $instance));
        
        $self->{components}->{error}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Error '%s' state is %s.",
                                    $instance, $map_state{$state}));
        my $exit = $self->get_severity(section => 'error', value => $map_state{$state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Error '%s' state is %s.", $instance, $map_state{$state}));
        }
    }
}

1;

__END__

=head1 MODE

Check errors (RUGGEDCOM-SYS-INFO-MIB).

=over 8

=item B<--exclude>

Exclude some instance (Example: --exclude='#WatchdogReset#CrashLogCreated#')

=item B<--no-errors>

Return an error if no errors are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
    
