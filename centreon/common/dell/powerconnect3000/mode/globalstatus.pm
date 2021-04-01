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

package centreon::common::dell::powerconnect3000::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
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

    my $oid_productStatusGlobalStatus = '.1.3.6.1.4.1.674.10895.3000.1.2.110.1';
    my $oid_productIdentificationDisplayName = '.1.3.6.1.4.1.674.10895.3000.1.2.100.1';
    my $oid_productIdentificationBuildNumber = '.1.3.6.1.4.1.674.10895.3000.1.2.100.5';
    my $oid_productIdentificationServiceTag = '.1.3.6.1.4.1.674.10895.3000.1.2.100.8.1.4';
	
	my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_productStatusGlobalStatus, start => $oid_productStatusGlobalStatus },
                                                            { oid => $oid_productIdentificationDisplayName, start => $oid_productIdentificationDisplayName },
                                                            { oid => $oid_productIdentificationBuildNumber, start => $oid_productIdentificationBuildNumber },
                                                            { oid => $oid_productIdentificationServiceTag, start => $oid_productIdentificationServiceTag },
                                                           ],
													nothing_quit => 1 );

	my $globalStatus = $result->{$oid_productStatusGlobalStatus}->{$oid_productStatusGlobalStatus . '.0'};
	my $displayName = $result->{$oid_productIdentificationDisplayName}->{$oid_productIdentificationDisplayName . '.0'};
	my $buildNumber = $result->{$oid_productIdentificationBuildNumber}->{$oid_productIdentificationBuildNumber . '.0'};

	my $serviceTag;
	foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_productIdentificationServiceTag}})) {
        next if ($key !~ /^$oid_productIdentificationServiceTag\.(\d+)$/);
		if (!defined($serviceTag)) {
			$serviceTag = $result->{$oid_productIdentificationServiceTag}->{$oid_productIdentificationServiceTag . '.' . $1};
		} else {
			$serviceTag .= ',' . $result->{$oid_productIdentificationServiceTag}->{$oid_productIdentificationServiceTag . '.' . $1};
		}
	}
    
    $self->{output}->output_add(severity =>  ${$states{$globalStatus}}[1],
                                short_msg => sprintf("Overall global status is '%s' [Product: %s] [Version: %s] [Service Tag: %s]", 
                                                ${$states{$globalStatus}}[0], $displayName, $buildNumber, $serviceTag));
                                                
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall status of Dell Powerconnect 3000.

=over 8

=back

=cut
    
