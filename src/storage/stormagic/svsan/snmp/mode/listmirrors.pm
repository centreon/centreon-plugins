#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package storage::stormagic::svsan::snmp::mode::listmirrors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my @labels = ('mirror_name', 'mirror_iqn', 'mirror_eui_64', 'mirror_nsh', 'mirror_cache_present', 'mirror_mbc_present');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_boolean = {
    0 => 'false',
    1 => 'true'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        mirrorName         => { oid => '.1.3.6.1.4.1.38003.1.4.1.2' },# mirrorName,
        mirrorIQN          => { oid => '.1.3.6.1.4.1.38003.1.4.1.3' },# mirrorIQN,
        mirrorEUI64        => { oid => '.1.3.6.1.4.1.38003.1.4.1.4' },# mirrorEUI64,
        mirrorNSH          => { oid => '.1.3.6.1.4.1.38003.1.4.1.9' },# mirrorNSH,
        mirrorCachePresent => { oid => '.1.3.6.1.4.1.38003.1.4.1.10', map => $map_boolean },# mirrorCachePresent
        mirrorMBCPresent   => { oid => '.1.3.6.1.4.1.38003.1.4.1.15', map => $map_boolean },# mirrorMBCPresent
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids        => [
            { oid => $mapping->{mirrorName}->{oid} },
            { oid => $mapping->{mirrorIQN}->{oid} },
            { oid => $mapping->{mirrorEUI64}->{oid} },
            { oid => $mapping->{mirrorNSH}->{oid} },
            { oid => $mapping->{mirrorCachePresent}->{oid} },
            { oid => $mapping->{mirrorMBCPresent}->{oid} }
        ],
        return_type => 1, nothing_quit => 1
    );

    my $results = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{mirrorName}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $results->{$instance} = {
            mirror_name          => $result->{mirrorName},
            mirror_iqn           => $result->{mirrorIQN},
            mirror_eui_64        => $result->{mirrorEUI64},
            mirror_nsh           => $result->{mirrorNSH},
            mirror_cache_present => $result->{mirrorCachePresent},
            mirror_mbc_present   => $result->{mirrorMBCPresent}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $port (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$port}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List mirror'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
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

List mirrors.

=over 8

=back

=cut
