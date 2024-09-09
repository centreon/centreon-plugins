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

package storage::emc::DataDomain::snmp::mode::listfilesystems;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::emc::DataDomain::snmp::lib::functions;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $oid_fileSystemSpaceEntry = '.1.3.6.1.4.1.19746.1.3.2.1.1';
my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
my ($oid_fileSystemResourceName, $oid_fileSystemSpaceUsed, $oid_fileSystemSpaceAvail);

my @mapping = ('name', 'total', 'used');

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr ],
        nothing_quit => 1
    );
    if (!($self->{os_version} = storage::emc::DataDomain::snmp::lib::functions::get_version(value => $snmp_result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_fileSystemSpaceEntry,
        nothing_quit => 1
    );

    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.3';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.6';
    } else {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.2';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.4';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
    }

    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_fileSystemResourceName\.(\d+)$/);
        my $instance = $1;

        my $name = $snmp_result->{$oid_fileSystemResourceName . '.' . $instance}; 
        my $precomp = 0;
        my $postcomp = 0;

        $precomp = 1 if ($name =~ /:\s*pre-comp/);
        $postcomp = 1 if ($name =~ /:\s*post-comp/);
        $name =~ s/:\s*(pre-comp|post-comp).*//;

        my $used = int($snmp_result->{$oid_fileSystemSpaceUsed . '.' . $instance} * 1024 * 1024 * 1024);
        my $free = int($snmp_result->{$oid_fileSystemSpaceAvail . '.' . $instance} * 1024 * 1024 * 1024);
        my $total = $used + $free;

        next if ($total == 0 || $precomp == 1);

        $results->{$name} = {
            name => $name,
            used => $used,
            total => $total
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_ = " . $results->{$name}->{$_} . ']', @mapping))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List filesystems:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List filesystems.

=over 8

=back

=cut
