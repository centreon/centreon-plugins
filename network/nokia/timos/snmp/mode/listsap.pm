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

package network::nokia::timos::snmp::mode::listsap;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_admin_status = (1 => 'up', 2 => 'down');
my %map_oper_status = (1 => 'up', 2 => 'down', 3 => 'ingressQosMismatch',
    4 => 'egressQosMismatch', 5 => 'portMtuTooSmall', 6 => 'svcAdminDown',
    7 => 'iesIfAdminDown',
);
my $mapping = {
    sapDescription  => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.5' },
    sapAdminStatus  => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.6', map => \%map_admin_status },
    sapOperStatus   => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.7', map => \%map_oper_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $mapping->{sapDescription}->{oid} },
            { oid => $mapping->{sapAdminStatus}->{oid} },
            { oid => $mapping->{sapOperStatus}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);
    $self->{sap} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sapOperStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (!defined($result->{sapDescription}) || $result->{sapDescription} eq '') {
            $self->{output}->output_add(long_msg => "skipping sap '$instance': cannot get a description. please set it.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sapDescription} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sapDescription} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sap}->{$instance} = { description => $result->{sapDescription}, 
            admin_state => $result->{sapAdminStatus}, oper_state => $result->{sapOperStatus} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sap}}) { 
        $self->{output}->output_add(long_msg => '[description = ' . $self->{sap}->{$instance}->{description} . 
            "] [admin = '" . $self->{sap}->{$instance}->{admin_state} . 
            "'] [oper = '" . $self->{sap}->{$instance}->{oper_state} . '"]');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List SAPs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['description', 'admin', 'oper']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sap}}) {             
        $self->{output}->add_disco_entry(description => $self->{sap}->{$instance}->{description},
            admin => $self->{sap}->{$instance}->{admin_state},
            oper => $self->{sap}->{$instance}->{oper_state},
        );
    }
}

1;

__END__

=head1 MODE

List Service Access Points.

=over 8

=item B<--filter-name>

Filter by sap description (can be a regexp).

=back

=cut
    
