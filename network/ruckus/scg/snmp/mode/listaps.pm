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

package network::ruckus::scg::snmp::mode::listaps;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"    => { name => 'filter_name' },
                                });
    $self->{ap} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    ruckusSCGAPGroup        => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.2' },
    ruckusSCGAPZone         => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.3' },
    ruckusSCGAPDomain       => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.4' },
    ruckusSCGAPName         => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.5' },
    ruckusSCGAPModel        => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.8' },
    ruckusSCGAPConnStatus   => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.16' },
    ruckusSCGAPLocation     => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.19' },
    ruckusSCGAPDescription  => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.22' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping->{ruckusSCGAPGroup}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPZone}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPDomain}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPName}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPModel}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPConnStatus}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPLocation}->{oid} },
                                                                   { oid => $mapping->{ruckusSCGAPDescription}->{oid} },
                                                                 ],
                                                         return_type => 1, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ruckusSCGAPName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ruckusSCGAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ruckusSCGAPName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ap}->{$instance} = { 
            name => $result->{ruckusSCGAPName},
            group => $result->{ruckusSCGAPGroup},
            zone => $result->{ruckusSCGAPZone},
            domain => $result->{ruckusSCGAPDomain},
            model => $result->{ruckusSCGAPModel},
            status => $result->{ruckusSCGAPConnStatus},
            location => $result->{ruckusSCGAPLocation},
            description => $result->{ruckusSCGAPDescription}
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ap}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{ap}->{$instance}->{name} .
            "] [group = " . $self->{ap}->{$instance}->{group} .
            "] [zone = " . $self->{ap}->{$instance}->{zone} .
            "] [domain = " . $self->{ap}->{$instance}->{domain} .
            "] [model = " . $self->{ap}->{$instance}->{model} .
            "] [status = " . $self->{ap}->{$instance}->{status} .
            "] [location = " . $self->{ap}->{$instance}->{location} .
            "] [description = " . $self->{ap}->{$instance}->{description} . "]"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List APs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'group', 'zone', 'domain', 'model', 'status', 'location', 'description']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ap}}) {
        $self->{output}->add_disco_entry(
            name => $self->{ap}->{$instance}->{name},
            group => $self->{ap}->{$instance}->{group},
            zone => $self->{ap}->{$instance}->{zone},
            domain => $self->{ap}->{$instance}->{domain},
            model => $self->{ap}->{$instance}->{model},
            status => $self->{ap}->{$instance}->{status},
            location => $self->{ap}->{$instance}->{location},
            description => $self->{ap}->{$instance}->{description});
    }
}

1;

__END__

=head1 MODE

List APs.

=over 8

=item B<--filter-name>

Filter by AP name (can be a regexp).

=back

=cut
    
