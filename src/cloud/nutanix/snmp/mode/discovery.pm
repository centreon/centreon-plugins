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

package cloud::nutanix::snmp::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use NetAddr::IP;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'discovery-type:s' => { name => 'discovery_type' },
        'prettify'       => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    citContainerName => { oid => '.1.3.6.1.4.1.41263.8.1.3' },
    hypervisorName   => { oid => '.1.3.6.1.4.1.41263.9.1.3' },
    vmName           => { oid => '.1.3.6.1.4.1.41263.10.1.3' },
    vmPowerState     => { oid => '.1.3.6.1.4.1.41263.10.1.5' }
};

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my @disco_data;
    my $disco_stats;
    
    $disco_stats->{start_time} = time();

    if (defined($self->{option_results}->{discovery_type}) && $self->{option_results}->{discovery_type} ne '') {
        if ($self->{option_results}->{discovery_type} eq 'container') {
            my $snmp_result = $self->{snmp}->get_table(oid => $mapping->{citContainerName}->{oid}, nothing_quit => 1);

            foreach my $oid (keys %{$snmp_result}) {
                $snmp_result->{$oid} = centreon::plugins::misc::trim($snmp_result->{$oid});

                my %host;
                $host{nutanix_hostname} = $self->{option_results}->{host};
                $host{container_name} = $snmp_result->{$oid};
                $host{snmp_version} = $self->{option_results}->{snmp_version};
                $host{snmp_community} = $self->{option_results}->{snmp_community};
                $host{snmp_port} = $self->{option_results}->{snmp_port};
                push @disco_data, \%host;
            }
        }

        if ($self->{option_results}->{discovery_type} eq 'hypervisor') {
            my $snmp_result = $self->{snmp}->get_table(oid => $mapping->{hypervisorName}->{oid}, nothing_quit => 1);

            foreach my $oid (keys %{$snmp_result}) {
                $snmp_result->{$oid} = centreon::plugins::misc::trim($snmp_result->{$oid});

                my %host;
                $host{nutanix_hostname} = $self->{option_results}->{host};
                $host{hypervisor_name} = $snmp_result->{$oid};
                $host{snmp_version} = $self->{option_results}->{snmp_version};
                $host{snmp_community} = $self->{option_results}->{snmp_community};
                $host{snmp_port} = $self->{option_results}->{snmp_port};
                push @disco_data, \%host;
            }
        }

        if ($self->{option_results}->{discovery_type} eq 'vm') {
            my $snmp_result = $self->{snmp}->get_multiple_table(
            oids => [
                { oid => $mapping->{vmName}->{oid} },
                { oid => $mapping->{vmPowerState}->{oid} },
            ],
            return_type => 1,
            nothing_quit => 1
            );

            foreach my $oid (keys %{$snmp_result}) {
                next if ($oid !~ /^$mapping->{vmPowerState}->{oid}\.(.*)$/);

                my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
                $result->{vmName} = centreon::plugins::misc::trim($result->{vmName});
                $result->{vmPowerState} = centreon::plugins::misc::trim($result->{vmPowerState});

                my %host;
                $host{nutanix_hostname} = $self->{option_results}->{host};
                $host{vm_name} = $result->{vmName};
                $host{vm_power_state} = $result->{vmPowerState};
                $host{snmp_version} = $self->{option_results}->{snmp_version};
                $host{snmp_community} = $self->{option_results}->{snmp_community};
                $host{snmp_port} = $self->{option_results}->{snmp_port};
                push @disco_data, \%host;
            }
        }
    }
    
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}
    
1;

__END__

=head1 MODE

Nutanix resources discovery.

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--discovery-type>

Resource types to discover.
Can be: 'container', 'hypervisor', 'vm'.

=back

=cut