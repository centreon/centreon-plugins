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

package snmp_standard::mode::listdiskio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'diskiodevice:s'          => { name => 'diskiodevice' },
        'name'                    => { name => 'use_name' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        index => { oid => '.1.3.6.1.4.1.2021.13.15.1.1.1' }, # diskioindex
        name => { oid => '.1.3.6.1.4.1.2021.13.15.1.1.2' } # diskiodevice
    };
    # parent oid for all the mapping usage
    my $oid_diskioEntry = '.1.3.6.1.4.1.2021.13.15.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_diskioEntry,
        start => $mapping->{index}->{oid}, # First oid of the mapping => here : 3
        end => $mapping->{name}->{oid} # Last oid of the mapping => here : 16
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{index}->{oid}\.(.*)$/);
        my $oid_path = $1;
        my $add = 1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);

        # Filter results by device index, name or regex
        if (length($self->{option_results}->{diskiodevice})) {
            my $filter = $self->{option_results}->{diskiodevice};
            if (length($self->{option_results}->{use_name})) {
                if (length($self->{option_results}->{use_regexp})) {
                    if (length($self->{option_results}->{use_regexpi})) {
                        if ($result->{name} !~ /$filter/i) {
                            $add = 0;
                        }
                    } elsif ($result->{name} !~ /$filter/) {
                        $add = 0;
                    }
                } elsif ($result->{name} ne $filter) {
                    $add = 0;
                }
            } elsif ($result->{index} != $filter) {
                $add = 0;
            }
        }
        if ($add) {
            my $name = $result->{name};
            if (length($self->{option_results}->{display_transform_src})) {
                $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
                eval "\$name =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
            }
            $results->{$oid_path} = {
                index => $result->{index},
                name  => $name
            };
        }
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[oid_path: %s] [index: %s] [name: %s]',
                $oid_path,
                $results->{$oid_path}->{index},
                $results->{$oid_path}->{name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List aps'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['index','name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            index => $results->{$oid_path}->{index},
            name => $results->{$oid_path}->{name}
        );
    }
}

1;

__END__

=head1 MODE

List disk IO device (UCD-DISKIO-MIB).
Need to enable "includeAllDisks 10%" on snmpd.conf.

=over 8

=item B<--diskiodevice>

Set the disk IO device (number expected) ex: 1, 2,... (empty means 'check all disks IO device').

=item B<--name>

Allows to use disk IO device name with option --diskiodevice instead of disk IO device oid index.

=item B<--regexp>

Allows to use regexp to filter diskiodevice (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=back

=cut