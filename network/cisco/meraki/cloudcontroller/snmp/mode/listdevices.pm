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

package network::cisco::meraki::cloudcontroller::snmp::mode::listdevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_status = (
    0 => 'offline',
    1 => 'online',
);
my $mapping = {
    devName         => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.2' },
    devStatus       => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.3', map => \%map_status },
    devProductCode  => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.9' },
    devNetworkName  => { oid => '.1.3.6.1.4.1.29671.1.1.4.1.11' },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"   => { name => 'filter_name' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $mapping->{devName}->{oid} },
        { oid => $mapping->{devStatus}->{oid} },
        { oid => $mapping->{devProductCode}->{oid} },
        { oid => $mapping->{devNetworkName}->{oid} }
    ], return_type => 1, nothing_quit => 1);

    $self->{devices} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{devName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{devName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $result->{devName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{devices}->{$instance} = {
            name => $result->{devName},
            status => $result->{devStatus},
            network => $result->{devNetworkName},
            product => $result->{devProductCode},
        };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{devices}}) {
        $self->{output}->output_add(long_msg => "[name = '" . $self->{devices}->{$instance}->{name} . "']" .
            " [status = '" . $self->{devices}->{$instance}->{status} . "']" .
            " [network = '" . $self->{devices}->{$instance}->{network} . "']" .
            " [product = '" . $self->{devices}->{$instance}->{product} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List devices:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'network', 'product']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{devices}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{devices}->{$instance}->{name},
            status => $self->{devices}->{$instance}->{status},
            network => $self->{devices}->{$instance}->{network},
            product => $self->{devices}->{$instance}->{product},
        );
    }
}

1;

__END__

=head1 MODE

List devices.

=over 8

=item B<--filter-name>

Filter by device name (can be a regexp).

=back

=cut
