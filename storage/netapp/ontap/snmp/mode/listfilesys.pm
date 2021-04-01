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

package storage::netapp::ontap::snmp::mode::listfilesys;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'   => { name => 'filter_name' },
        'filter-type:s'   => { name => 'filter_type' },
        'skip-total-zero' => { name => 'skip_total_zero' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_types = (
    1 => 'traditionalVolume',
    2 => 'flexibleVolume',
    3 => 'aggregate',
    4 => 'stripedAggregate',
    5 => 'stripedVolume'
);

my $mapping = {
    dfFileSys       => { oid => '.1.3.6.1.4.1.789.1.5.4.1.2' },
    dfKBytesTotal   => { oid => '.1.3.6.1.4.1.789.1.5.4.1.3' },
    dfType          => { oid => '.1.3.6.1.4.1.789.1.5.4.1.23', map => \%map_types },
    df64TotalKBytes => { oid => '.1.3.6.1.4.1.789.1.5.4.1.29' },
    dfVserver       => { oid => '.1.3.6.1.4.1.789.1.5.4.1.34' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $mapping->{dfFileSys}->{oid} },
            { oid => $mapping->{dfKBytesTotal}->{oid} },
            { oid => $mapping->{dfType}->{oid} },
            { oid => $mapping->{df64TotalKBytes}->{oid} },
            { oid => $mapping->{dfVserver}->{oid} },
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{fs} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{dfFileSys}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{dfFileSys} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{dfFileSys} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{dfType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{dfFileSys} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{fs}->{$instance} = {
            name => $result->{dfFileSys},
            total => defined($result->{df64TotalKBytes}) ? $result->{df64TotalKBytes} * 1024 : $result->{dfKBytesTotal} * 1024,
            type => $result->{dfType},
            vserver => $result->{dfVserver}
        };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{fs}}) {
        next if (defined($self->{option_results}->{skip_total_zero}) && $self->{fs}->{$instance}->{total} == 0);
        
        $self->{output}->output_add(long_msg => '[instance = ' . $instance . '] ' . 
            "[name = '" . $self->{fs}->{$instance}->{name} . "'] " .
            "[type = '" . $self->{fs}->{$instance}->{type} . "'] " .
            "[vserver = '" . $self->{fs}->{$instance}->{vserver} . "'] " .
            "[total = '" . $self->{fs}->{$instance}->{total} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List filesys:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'total', 'type', 'vserver']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{fs}}) {
        next if (defined($self->{option_results}->{skip_total_zero}) && $self->{fs}->{$instance}->{total} == 0);

        $self->{output}->add_disco_entry(%{$self->{fs}->{$instance}});
    }
}

1;

__END__

=head1 MODE

List filesystems (volumes and aggregates also).

=over 8

=item B<--filter-name>

Filter the filesystem name.

=item B<--filter-type>

Filter filesystem type (a regexp. Example: 'flexibleVolume|aggregate').

=item B<--skip-total-zero>

Don't display filesys with total equals 0.

=back

=cut
    
