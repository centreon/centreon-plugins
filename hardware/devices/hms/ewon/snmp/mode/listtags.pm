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

package hardware::devices::hms::ewon::snmp::mode::listtags;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-tag-name:s' => { name => 'filter_tag_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    name  => { oid => '.1.3.6.1.4.1.8284.2.1.3.1.11.1.3' }, # tagCfgName
    value => { oid => '.1.3.6.1.4.1.8284.2.1.3.1.11.1.4' }  # tagValue
};
my $oid_tagEntry = '.1.3.6.1.4.1.8284.2.1.3.1.11.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tagEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{value}->{oid},
        nothing_quit => 1
    );

    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_tag_name}) && $self->{option_results}->{filter_tag_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_tag_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $result->{name} = $self->{output}->decode($result->{name});
        $results->{$instance} = $result;
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach my $index (sort keys %$results) { 
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s][index: %s][value: %s]',
                $results->{$index}->{name},
                $index,
                $results->{$index}->{value}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List tags:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['index', 'name', 'value']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $index (sort keys %$results) {
        $self->{output}->add_disco_entry(
            index => $index,
            %{$results->{$index}}            
        );
    }
}

1;

__END__

=head1 MODE

List tags.

=over 8

=item B<--filter-tag-name>

Filter tags by name (can be a regexp).

=back

=cut
    
