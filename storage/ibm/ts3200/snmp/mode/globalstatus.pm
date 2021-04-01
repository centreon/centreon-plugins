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

package storage::ibm::ts3200::snmp::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['other', 'WARNING'], 
    2 => ['unknown', 'WARNING'], 
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'WARNING'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"     => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_threshold_overload {
    my ($self, %options) = @_;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /(.*?)=(.*)/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($filter, $threshold) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$filter} = $threshold;
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->check_threshold_overload();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = ${$states{$options{value}}}[1];
    
    foreach (keys %{$self->{overload_th}}) {
        if (${$states{$options{value}}}[0] =~ /$_/) {
            $status = $self->{overload_th}->{$_};
        }
    }
    return $status;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $oid_ibm3200StatusGlobalStatus = '.1.3.6.1.4.1.2.6.211.2.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_ibm3200StatusGlobalStatus], nothing_quit => 1);
    
    $self->{output}->output_add(severity => $self->get_severity(value => $result->{$oid_ibm3200StatusGlobalStatus}),
                                short_msg => sprintf("Overall global status is '%s'.", 
                                                ${$states{$result->{$oid_ibm3200StatusGlobalStatus}}}[0]));
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall status of the appliance.

=over 8

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='(unknown|non critical)=critical'

=back

=cut
    
