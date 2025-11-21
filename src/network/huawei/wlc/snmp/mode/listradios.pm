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

package network::huawei::wlc::snmp::mode::listradios;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"  => { name => 'filter_name' },
        "filter-group:s" => { name => 'filter_group' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_runstate = {
    1   => 'up',
    2   => 'down',
    255 => 'invalid'
};

sub manage_selection {
    my ($self, %options) = @_;

    # Collecting all the relevant information user may needs when using discovery function for AP in Huawei WLC controllers.
    # They had been select with https://support.huawei.com/enterprise/en/doc/EDOC1100306136/680fca71/huawei-wlan-ap-mib as support.
    my $mapping = {
        name           => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.3' },# hwWlanRadioInfoApName
        frequence_type => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.5' },# hwWlanRadioFreqType
        ap_group       => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.55' },# hwWlanRadioApGroup
        run_state      => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.6', map => $map_runstate },# hwWlanRadioRunState
        description    => { oid => '.1.3.6.1.4.1.2011.6.139.16.1.2.1.16' },# hwWlanRadioDescription
    };

    my $request = [ { oid => $mapping->{name}->{oid} } ];
    push @$request, { oid => $mapping->{group}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');

    push @$request, { oid => $mapping->{address}->{oid} }
        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '');

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $oid_path = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);

        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg => "skipping WLC '$oid_path': cannot get a name. please set it.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching name filter.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{ap_group} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ap_group} . "': no matching group filter.", debug => 1);
            next;
        }

        $self->{ap}->{ $result->{name} } = {
            instance   => $oid_path,
            display    => $result->{name},
            ap_global  => { display => $result->{name} },
            interfaces => {}
        };
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping)) ],
        instances       => [ map($_->{instance}, values %{$self->{ap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(mapping =>
            $mapping, results                             =>
            $snmp_result,
            instance                                      =>
                $self->{ap}->{$_}->{instance});

        $results->{$self->{ap}->{$_}->{instance}} = {
            name           => $result->{name},
            frequence_type => $result->{frequence_type},
            run_state      => $result->{run_state},
            description    => $result->{description},
            ap_group       => $result->{ap_group}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
                long_msg => sprintf(
                        '[oid_path: %s] [name: %s] [frequence_type: %s] [run_state: %s] [description: %s] [ap_group: %s]',
                        $oid_path,
                        $results->{$oid_path}->{name},
                        $results->{$oid_path}->{frequence_type},
                        $results->{$oid_path}->{run_state},
                        $results->{$oid_path}->{description},
                        $results->{$oid_path}->{ap_group}
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List aps'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements =>
        [ 'name', 'frequence_type', 'run_state', 'description', 'ap_group' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name           => $results->{$oid_path}->{name},
            frequence_type => $results->{$oid_path}->{frequence_type},
            run_state      => $results->{$oid_path}->{run_state},
            description    => $results->{$oid_path}->{description},
            ap_group       => $results->{$oid_path}->{ap_group}
        );
    }
}

1;

__END__

=head1 MODE

List radios.

=over 8

=item B<--filter-name>

Display AP radios matching the filter.

=item B<--filter-group>

Display AP radios matching the filter.

=back

=cut
