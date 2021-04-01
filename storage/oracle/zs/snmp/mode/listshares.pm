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

package storage::oracle::zs::snmp::mode::listshares;

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
                                  "filter-project:s"    => { name => 'filter_project' },
                                });
    $self->{shares} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    sunAkShareName      => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.2' },
    sunAkShareProject   => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.4' },
};

my $oid_sunAkShareEntry = '.1.3.6.1.4.1.42.2.225.1.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_sunAkShareEntry, end => $mapping->{sunAkShareProject}->{oid},
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sunAkShareName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sunAkShareName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sunAkShareName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_project}) && $self->{option_results}->{filter_project} ne '' &&
            $result->{sunAkShareProject} !~ /$self->{option_results}->{filter_project}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sunAkShareName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{shares}->{$instance} = { name => $result->{sunAkShareName}, project => $result->{sunAkShareProject} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{shares}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{shares}->{$instance}->{name} . "] [project = '" . $self->{shares}->{$instance}->{project} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List shares:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'project']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{shares}}) {             
        $self->{output}->add_disco_entry(name => $self->{shares}->{$instance}->{name}, project => $self->{shares}->{$instance}->{project});
    }
}

1;

__END__

=head1 MODE

List shares.

=over 8

=item B<--filter-name>

Filter by share name (can be a regexp).

=item B<--filter-project>

Filter by project (can be a regexp).

=back

=cut
    