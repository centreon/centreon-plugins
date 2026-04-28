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

package os::linux::local::mode::storage;
use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
sub custom_usage_perfdata {
    my ($self, %options) = @_;
    # Perfdata pour le pourcentage utilisé
    $self->{output}->perfdata_add(
        nlabel    => 'storage.space.usage.percentage',
        unit      => '%',
        instances => $self->{result_values}->{display},
        value     => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-usage-prct'),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-usage-prct'),
        min       => 0,
        max       => 100
    );
    # Perfdata pour les bytes libres
    $self->{output}->perfdata_add(
        nlabel    => 'storage.space.free.bytes',
        unit      => 'B',
        instances => $self->{result_values}->{display},
        value     => $self->{result_values}->{free},
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-free-byte'),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-free-byte'),
        min       => 0,
        max       => $self->{result_values}->{total}
    );
}
sub custom_usage_threshold {
    my ($self, %options) = @_;
    # Seuil % utilisé
    my $exit_usage_prct = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{prct_used},
        threshold => [
            { label => 'critical-usage-prct', exit_litteral => 'critical' },
            { label => 'warning-usage-prct',  exit_litteral => 'warning' }
        ]
    );
    # Seuil bytes libres
    my $exit_free_byte = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{free},
        threshold => [
            { label => 'critical-free-byte', exit_litteral => 'critical' },
            { label => 'warning-free-byte',  exit_litteral => 'warning' }
        ]
    );
    # Logique fonctionnelle :
    # 1. Si au moins un des deux est OK -> global OK
    # 2. Sinon si au moins un est CRITICAL -> global CRITICAL
    # 3. Sinon (les deux WARNING) -> global WARNING
    my $exit_status;
    if ($exit_usage_prct eq 'ok' || $exit_free_byte eq 'ok') {
        $exit_status = 'ok';
    } elsif ($exit_usage_prct eq 'critical' || $exit_free_byte eq 'critical') {
        $exit_status = 'critical';
    } else {
        # Les deux sont 'warning'
        $exit_status = 'warning';
    }
    return $exit_status;
}
sub custom_usage_output {
    my ($self, %options) = @_;
    my ($total_size_value, $total_size_unit) =
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) =
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) =
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf(
        'Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . ' ' . $total_size_unit,
        $total_used_value . ' ' . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . ' ' . $total_free_unit, $self->{result_values}->{prct_free}
    );
    # IMPORTANT :
    # - On NE refait PAS de threshold_check ici
    # - On NE filtre PAS par statut
    # - On laisse templates::counter gérer short/long :
    #   - short_output : uniquement si statut != ok (via custom_usage_threshold)
    #   - long_output : tous les disques (display_ok par défaut)
    #
    # Donc on retourne TOUJOURS le message pour ce disque.
    return $msg;
}
sub custom_usage_calc {
    my ($self, %options) = @_;
    if ($options{new_datas}->{ $self->{instance} . '_total' } == 0) {
        $self->{error_msg} = 'total size is 0';
        return -2;
    }
    $self->{result_values}->{display}   = $options{new_datas}->{ $self->{instance} . '_display' };
    $self->{result_values}->{total}     = $options{new_datas}->{ $self->{instance} . '_total' };
    $self->{result_values}->{used}      = $options{new_datas}->{ $self->{instance} . '_used' };
    $self->{result_values}->{free}      = $options{new_datas}->{ $self->{instance} . '_free' };
    $self->{result_values}->{prct_used} =
        $self->{result_values}->{used} * 100 /
        ($self->{result_values}->{used} + $self->{result_values}->{free});
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    return 0;
}
sub prefix_disks_output {
    my ($self, %options) = @_;
    return "Storage '" . $options{instance_value}->{display} . "' ";
}
sub set_counters {
    my ($self, %options) = @_;
    $self->{maps_counters_type} = [
        {
            name             => 'disks',
            type             => 1,
            cb_prefix_output => 'prefix_disks_output',
            message_multiple => 'All storages are ok'
        }
    ];
    $self->{maps_counters}->{disks} = [
        {
            label  => 'usage-prct',
            nlabel => 'storage.space.usage.percentage',
            set    => {
                key_values => [
                    { name => 'display' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'total' }
                ],
                closure_custom_calc            => $self->can('custom_usage_calc'),
                closure_custom_output          => $self->can('custom_usage_output'),
                closure_custom_perfdata        => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];
}
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(
        package            => __PACKAGE__,
        %options,
        force_new_perfdata => 1
    );
    bless $self, $class;
    $options{options}->add_options(
        arguments => {
            'filter-type:s'        => { name => 'filter_type' },
            'filter-fs:s'          => { name => 'filter_fs' },
            'exclude-fs:s'         => { name => 'exclude_fs' },
            'filter-mountpoint:s'  => { name => 'filter_mountpoint' },
            'exclude-mountpoint:s' => { name => 'exclude_mountpoint' },
            'warning-usage-prct:s' => { name => 'warning_usage_prct' },
            'critical-usage-prct:s'=> { name => 'critical_usage_prct' },
            'warning-free-byte:s'  => { name => 'warning_free_byte' },
            'critical-free-byte:s' => { name => 'critical_free_byte' }
        }
    );
    return $self;
}
sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    # Validation des seuils pourcentage utilisé
    if (defined($self->{option_results}->{warning_usage_prct})
        && $self->{option_results}->{warning_usage_prct} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'warning-usage-prct',
            value => $self->{option_results}->{warning_usage_prct}
        );
    }
    if (defined($self->{option_results}->{critical_usage_prct})
        && $self->{option_results}->{critical_usage_prct} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'critical-usage-prct',
            value => $self->{option_results}->{critical_usage_prct}
        );
    }
    # Validation des seuils bytes libres
    if (defined($self->{option_results}->{warning_free_byte})
        && $self->{option_results}->{warning_free_byte} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'warning-free-byte',
            value => $self->{option_results}->{warning_free_byte}
        );
    }
    if (defined($self->{option_results}->{critical_free_byte})
        && $self->{option_results}->{critical_free_byte} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'critical-free-byte',
            value => $self->{option_results}->{critical_free_byte}
        );
    }
}
sub manage_selection {
    my ($self, %options) = @_;
    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command         => 'df',
        command_options => '-P -k -T 2>&1',
        no_quit         => 1
    );
    $self->{disks} = {};
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next
            if ($line !~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.*)/);
        my ($fs, $type, $used, $available, $percent, $mount) =
            ($1, $2, $4, $5, $6, $7);
        next
            if (defined $self->{option_results}->{filter_fs}
                && $self->{option_results}->{filter_fs} ne ''
                && $fs !~ /$self->{option_results}->{filter_fs}/);
        next
            if (defined $self->{option_results}->{exclude_fs}
                && $self->{option_results}->{exclude_fs} ne ''
                && $fs =~ /$self->{option_results}->{exclude_fs}/);
        next
            if (defined $self->{option_results}->{filter_type}
                && $self->{option_results}->{filter_type} ne ''
                && $type !~ /$self->{option_results}->{filter_type}/);
        next
            if (defined $self->{option_results}->{filter_mountpoint}
                && $self->{option_results}->{filter_mountpoint} ne ''
                && $mount !~ /$self->{option_results}->{filter_mountpoint}/);
        next
            if (defined $self->{option_results}->{exclude_mountpoint}
                && $self->{option_results}->{exclude_mountpoint} ne ''
                && $mount =~ /$self->{option_results}->{exclude_mountpoint}/);
        $self->{disks}->{$mount} = {
            display => $mount,
            fs      => $fs,
            type    => $type,
            used    => $used * 1024,
            free    => $available * 1024,
            total   => ($used + $available) * 1024
        };
    }
    if (scalar(keys %{ $self->{disks} }) <= 0) {
        if ($exit_code != 0) {
            $self->{output}->output_add(
                long_msg => 'command output:' . $stdout
            );
        }
        $self->{output}->add_option_msg(
            short_msg => 'No storage found (filters or command issue)'
        );
        $self->{output}->option_exit();
    }
}
1;
__END__
=head1 MODE
Check Linux storage partitions usage with multiple threshold types
(used percentage AND free bytes combined).
=over 8
=item B<--filter-type>
Filter filesystem type (regexp can be used).
=item B<--filter-fs>
Filter filesystem (regexp can be used).
=item B<--exclude-fs>
Exclude filesystem (regexp can be used).
=item B<--filter-mountpoint>
Filter mountpoint (regexp can be used).
=item B<--exclude-mountpoint>
Exclude mountpoint (regexp can be used).
=item B<--warning-usage-prct>
Warning threshold for used space in percentage.
Example: C<--warning-usage-prct=80>
=item B<--critical-usage-prct>
Critical threshold for used space in percentage.
Example: C<--critical-usage-prct=90>
=item B<--warning-free-byte>
Warning threshold for free space in bytes.
Syntaxe Nagios/Centreon.
Pour déclencher une alerte lorsque l'espace libre est
B<en dessous> d'une valeur X, utiliser C<X:>.
Example: C<--warning-free-byte=21474836480:> (alert if free < 20 GiB)
=item B<--critical-free-byte>
Critical threshold for free space in bytes (même syntaxe).
Example: C<--critical-free-byte=10737418240:> (alert if free < 10 GiB)
=back
=head1 GLOBAL OPTIONS
=over 8
=item B<--verbose>
Display extended status information (long output).
(Le traitement du verbose est géré globalement par Centreon, pas dans ce mode.)
=back
=cut
