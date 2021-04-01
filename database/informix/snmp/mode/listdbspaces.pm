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

package database::informix::snmp::mode::listdbspaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-instance:s" => { name => 'filter_instance' },
        "filter-dbspace:s"  => { name => 'filter_dbspace' },
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
    my $oid_onDbspaceName = '.1.3.6.1.4.1.893.1.1.1.6.1.2';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_applName },
            { oid => $oid_onDbspaceName },
        ], nothing_quit => 1);
    
    $self->{dbspace} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_onDbspaceName}}) {
        $oid =~ /^$oid_onDbspaceName\.(.*?)\.(.*)/;
        my ($applIndex, $dbSpaceIndex) = ($1, $2);

        my $instance = 'default';
        $instance = $snmp_result->{$oid_applName}->{$oid_applName . '.' . $applIndex}
            if (defined($snmp_result->{$oid_applName}->{$oid_applName . '.' . $applIndex}));
        my $dbspace = $snmp_result->{$oid_onDbspaceName}->{$oid};
        if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
            $instance !~ /$self->{option_results}->{filter_instance}/) {
            $self->{output}->output_add(long_msg => "skipping instance '" . $instance . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_dbspace}) && $self->{option_results}->{filter_dbspace} ne '' &&
            $dbspace !~ /$self->{option_results}->{filter_dbspace}/) {
            $self->{output}->output_add(long_msg => "skipping dbspace '" . $dbspace . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{dbspace}->{$applIndex . '.' . $dbSpaceIndex} = { 
            instance => $instance,
            dbspace => $dbspace,
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{dbspace}}) { 
        $self->{output}->output_add(long_msg => '[instance = ' . $self->{dbspace}->{$instance}->{instance} . 
            "] [dbspace = '" . $self->{dbspace}->{$instance}->{dbspace} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List dbspaces:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['instance', 'dbspace']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{dbspace}}) {             
        $self->{output}->add_disco_entry(
            instance => $self->{dbspace}->{$instance}->{instance},
            dbspace => $self->{dbspace}->{$instance}->{dbspace},
        );
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
    
