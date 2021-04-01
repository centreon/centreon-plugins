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

package database::informix::snmp::mode::listinstances;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-instance:s" => { name => 'filter_instance' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_applName);
    $self->{instance} = {};
    foreach my $oid (keys %{$snmp_result}) {
        my $name = $snmp_result->{$oid};
        if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
            $name !~ /$self->{option_results}->{filter_instance}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{instance}->{$name} = { instance => $name }; 
    }
    
    if (scalar(keys %{$self->{instance}}) == 0) {
        $self->{instance}->{default} = { instance => 'default' };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{instance}}) { 
        $self->{output}->output_add(long_msg => '[instance = ' . $self->{instance}->{$instance}->{instance} . ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List instances:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['instance']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{instance}}) {             
        $self->{output}->add_disco_entry(instance => $self->{instance}->{$instance}->{instance});
    }
}

1;

__END__

=head1 MODE

List informix instances.

=over 8

=item B<--filter-instance>

Filter by instance name (can be a regexp).

=back

=cut
    
