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

package storage::netapp::ontap::snmp::mode::fan;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_envFailedFanCount = '.1.3.6.1.4.1.789.1.2.4.2';
    my $oid_envFailedFanMessage = '.1.3.6.1.4.1.789.1.2.4.3';
    my $oid_nodeName = '.1.3.6.1.4.1.789.1.25.2.1.1';
    my $oid_nodeEnvFailedFanCount = '.1.3.6.1.4.1.789.1.25.2.1.19';
    my $oid_nodeEnvFailedFanMessage = '.1.3.6.1.4.1.789.1.25.2.1.20';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_envFailedFanCount }, 
                                                            { oid => $oid_envFailedFanMessage },
                                                            { oid => $oid_nodeName },
                                                            { oid => $oid_nodeEnvFailedFanCount },
                                                            { oid => $oid_nodeEnvFailedFanMessage }
                                                            ], nothing_quit => 1);
    
    if (defined($results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Fans are ok.');
        if ($results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'} != 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("'%d' fans are failed [message: %s].", 
                                                        $results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'},
                                                        $results->{$oid_envFailedFanMessage}->{$oid_envFailedFanMessage . '.0'}));
        }
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Fans are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$oid_nodeEnvFailedFanCount}})) {
            $oid =~ /^$oid_nodeEnvFailedFanCount\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_nodeName}->{$oid_nodeName . '.' . $instance};
            my $count = $results->{$oid_nodeEnvFailedFanCount}->{$oid};
            my $message = $results->{$oid_nodeEnvFailedFanMessage}->{$oid_nodeEnvFailedFanMessage . '.' . $instance};
            $self->{output}->output_add(long_msg => sprintf("'%d' fans are failed on node '%s' [message: %s]", 
                                                            $count, $name, defined($message) ? $message : '-'));
            if ($count != 0) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("'%d' fans are failed on node '%s' [message: %s]", 
                                                        $count, $name, defined($message) ? $message : '-'));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check if fans are failed (not operating within the recommended RPM range).

=over 8

=back

=cut
    
