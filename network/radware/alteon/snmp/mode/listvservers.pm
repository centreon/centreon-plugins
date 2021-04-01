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

package network::radware::alteon::snmp::mode::listvservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_state = (
    2 => 'enabled', 
    3 => 'disabled', 
);

my $mapping = {
    slbCurCfgVirtServerState    => { oid => '.1.3.6.1.4.1.1872.2.5.4.1.1.4.2.1.4', map => \%map_state },
    slbCurCfgVirtServerVname    => { oid => '.1.3.6.1.4.1.1872.2.5.4.1.1.4.2.1.10' }, 
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
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

    my $snmp_result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{slbCurCfgVirtServerState}->{oid} },
                                                            { oid => $mapping->{slbCurCfgVirtServerVname}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{vservers} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{slbCurCfgVirtServerVname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (!defined($result->{slbCurCfgVirtServerVname}) || $result->{slbCurCfgVirtServerVname} eq '') {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '$instance': cannot get a name. please set it.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{slbCurCfgVirtServerVname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{slbCurCfgVirtServerVname} . "'.", debug => 1);
            next;
        }
        
        $self->{vservers}->{$instance} = { name => $result->{slbCurCfgVirtServerVname}, state => $result->{slbCurCfgVirtServerState} };
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort keys %{$self->{vservers}}) {
        $self->{output}->output_add(long_msg => "'" . $self->{vservers}->{$instance}->{name} . "' [state = '" . $self->{vservers}->{$instance}->{state} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Virtual Servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort keys %{$self->{vservers}}) {        
        $self->{output}->add_disco_entry(name => $self->{vservers}->{$instance}->{name}, state => $self->{vservers}->{$instance}->{state});
    }
}

1;

__END__

=head1 MODE

List Virtual Servers.

=over 8

=item B<--filter-name>

Filter by virtual server name.

=back

=cut
    
