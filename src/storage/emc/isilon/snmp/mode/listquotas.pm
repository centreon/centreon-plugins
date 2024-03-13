#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package storage::emc::isilon::snmp::mode::listquotas;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
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

    $self->manage_selection(%options);

    foreach (keys %{$self->{quotas}}) {        
        $self->{output}->output_add(long_msg => "'" . $self->{quotas}->{$_} . "' [id = $_]");
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List storage:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_quotaType = '.1.3.6.1.4.1.12124.1.12.1.1.2';
    my $oid_quotaPath = '.1.3.6.1.4.1.12124.1.12.1.1.5';
    my $oid_quotaHardThreshold = '.1.3.6.1.4.1.12124.1.12.1.1.7';
    
    my $result = $options{snmp}->get_multiple_table(
        oids => [ { oid => $oid_quotaType }, { oid => $oid_quotaPath }, { oid => $oid_quotaHardThreshold } ],
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$result->{$oid_quotaType}}) {
        $oid =~ /^$oid_quotaType\.(.*)$/;
        my $instance = $1;
        next if ($result->{$oid_quotaType}->{$oid_quotaType . '.' . $instance} ne "4"); # directory
        next if ($result->{$oid_quotaHardThreshold}->{$oid_quotaHardThreshold . '.' . $instance} <= 0); # no hard threshold
        my $name = $result->{$oid_quotaPath}->{$oid_quotaPath . '.' . $instance};

        $self->{quotas}->{$_} = $name;
    }

    if (scalar(keys %{$self->{quotas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No quotas found');
        $self->{output}->option_exit();
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'id']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(%options);
    
    foreach (keys %{$self->{quotas}}) {  
        $self->{output}->add_disco_entry(
            name => $self->{quotas}->{$_},
            id => $_
        );
    }
}

1;

__END__

=head1 MODE

List quotas. 

=over 8

=item B<--filter-name>

Filter quotas based on name (can be a regexp).

=back

=cut
