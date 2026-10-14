package os::linux::local::mode::memory;
use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    # Perfdata pour bytes utilisés
    $self->{output}->perfdata_add(
        nlabel => 'memory.usage.bytes',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-memory-usage'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-memory-usage'),
        min => 0,
        max => $self->{result_values}->{total}
    );

    # Perfdata pour bytes libres
    $self->{output}->perfdata_add(
        nlabel => 'memory.free.bytes',
        unit => 'B',
        value => $self->{result_values}->{free},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-memory-usage-free'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-memory-usage-free'),
        min => 0,
        max => $self->{result_values}->{total}
    );

    # Perfdata pour pourcentage utilisé
    $self->{output}->perfdata_add(
        nlabel => 'memory.usage.percentage',
        unit => '%',
        value => sprintf("%.2f", $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-memory-usage-prct'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-memory-usage-prct'),
        min => 0,
        max => 100
    );

    # Perfdata pour bytes available
    $self->{output}->perfdata_add(
        nlabel => 'memory.available.bytes',
        unit => 'B',
        value => $self->{result_values}->{available},
        min => 0,
        max => $self->{result_values}->{total}
    );

    # Perfdata buffer
    if (defined($self->{result_values}->{buffer})) {
        $self->{output}->perfdata_add(
            nlabel => 'memory.buffer.bytes',
            unit => 'B',
            value => $self->{result_values}->{buffer},
            min => 0
        );
    }

    # Perfdata cached
    if (defined($self->{result_values}->{cached})) {
        $self->{output}->perfdata_add(
            nlabel => 'memory.cached.bytes',
            unit => 'B',
            value => $self->{result_values}->{cached},
            min => 0
        );
    }

    # Perfdata slab
    if (defined($self->{result_values}->{slab})) {
        $self->{output}->perfdata_add(
            nlabel => 'memory.slab.bytes',
            unit => 'B',
            value => $self->{result_values}->{slab},
            min => 0
        );
    }
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    # === Détecter quels types de seuils sont configurés ===
    my $has_prct = (
        (defined($self->{instance_mode}->{option_results}->{warning_memory_usage_prct}) &&
         $self->{instance_mode}->{option_results}->{warning_memory_usage_prct} ne '') ||
        (defined($self->{instance_mode}->{option_results}->{critical_memory_usage_prct}) &&
         $self->{instance_mode}->{option_results}->{critical_memory_usage_prct} ne '')
    ) ? 1 : 0;

    my $has_free = (
        (defined($self->{instance_mode}->{option_results}->{warning_memory_usage_free}) &&
         $self->{instance_mode}->{option_results}->{warning_memory_usage_free} ne '') ||
        (defined($self->{instance_mode}->{option_results}->{critical_memory_usage_free}) &&
         $self->{instance_mode}->{option_results}->{critical_memory_usage_free} ne '')
    ) ? 1 : 0;

    # === Vérification des seuils ===
    my $exit_prct = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{prct_used},
        threshold => [
            { label => 'critical-memory-usage-prct', exit_litteral => 'critical' },
            { label => 'warning-memory-usage-prct',  exit_litteral => 'warning' }
        ]
    );

    my $exit_free = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{free},
        threshold => [
            { label => 'critical-memory-usage-free', exit_litteral => 'critical' },
            { label => 'warning-memory-usage-free',  exit_litteral => 'warning' }
        ]
    );

    # === Comportement selon les seuils configurés ===

    # Un seul type configuré → comportement standard (seuil unique)
    return $exit_prct if ($has_prct && !$has_free);
    return $exit_free if ($has_free && !$has_prct);

    # Les deux types configurés → logique ET
    # CRITICAL si au moins un est CRITICAL
    if ($exit_prct eq 'critical' || $exit_free eq 'critical') {
        return 'critical';
    }
    # WARNING seulement si LES DEUX sont WARNING
    if ($exit_prct eq 'warning' && $exit_free eq 'warning') {
        return 'warning';
    }
    # Sinon OK
    return 'ok';
}

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used (-%s): %s %s (%.2f%%) free: %s %s (%.2f%%) available: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{result_values}->{used_desc},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{available}),
        $self->{result_values}->{prct_available}
    );
}

sub custom_swap_output {
    my ($self, %options) = @_;

    return sprintf(
        'Swap total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
        { name => 'swap',   type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [
                    { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' },
                    { name => 'total' }, { name => 'used_desc' }, { name => 'available' }, { name => 'prct_available' },
                    { name => 'buffer' }, { name => 'cached' }, { name => 'slab' }
                ],
                closure_custom_output          => $self->can('custom_memory_output'),
                closure_custom_perfdata        => $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check => $self->can('custom_memory_threshold')
            }
        }
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'swap', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'swap-free', display_ok => 0, nlabel => 'swap.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap_free', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'swap-prct', display_ok => 0, nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap_prct', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'swap'                         => { name => 'check_swap' },
        'warning-memory-usage-prct:s'  => { name => 'warning_memory_usage_prct' },
        'critical-memory-usage-prct:s' => { name => 'critical_memory_usage_prct' },
        'warning-memory-usage-free:s'  => { name => 'warning_memory_usage_free' },
        'critical-memory-usage-free:s' => { name => 'critical_memory_usage_free' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # Validation seuils pourcentage utilisé
    if (defined($self->{option_results}->{warning_memory_usage_prct}) &&
        $self->{option_results}->{warning_memory_usage_prct} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'warning-memory-usage-prct',
            value => $self->{option_results}->{warning_memory_usage_prct}
        );
    }
    if (defined($self->{option_results}->{critical_memory_usage_prct}) &&
        $self->{option_results}->{critical_memory_usage_prct} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'critical-memory-usage-prct',
            value => $self->{option_results}->{critical_memory_usage_prct}
        );
    }

    # Validation seuils bytes libres
    if (defined($self->{option_results}->{warning_memory_usage_free}) &&
        $self->{option_results}->{warning_memory_usage_free} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'warning-memory-usage-free',
            value => $self->{option_results}->{warning_memory_usage_free}
        );
    }
    if (defined($self->{option_results}->{critical_memory_usage_free}) &&
        $self->{option_results}->{critical_memory_usage_free} ne '') {
        $self->{perfdata}->threshold_validate(
            label => 'critical-memory-usage-free',
            value => $self->{option_results}->{critical_memory_usage_free}
        );
    }
}

sub check_rhel_version {
    my ($self, %options) = @_;

    $self->{rhel_71} = 0;
    return if ($options{stdout} !~ /(?:Redhat|CentOS|Red[ \-]Hat).*?release\s+(\d+)\.(\d+)/mi);
    $self->{rhel_71} = 1 if ($1 >= 8 || ($1 == 7 && $2 >= 1));
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command         => 'cat',
        command_options => '/proc/meminfo /etc/redhat-release 2>&1',
        no_quit         => 1
    );

    # Buffer can be missing. In Openvz container for example.
    my $buffer_used = 0;
    my $available   = 0;
    my ($cached_used, $free, $total_size, $slab_used, $swap_total, $swap_free);

    foreach (split(/\n/, $stdout)) {
        if    (/^MemTotal:\s+(\d+)/i)    { $total_size  = $1 * 1024; }
        elsif (/^Cached:\s+(\d+)/i)      { $cached_used = $1 * 1024; }
        elsif (/^Buffers:\s+(\d+)/i)     { $buffer_used = $1 * 1024; }
        elsif (/^Slab:\s+(\d+)/i)        { $slab_used   = $1 * 1024; }
        elsif (/^MemFree:\s+(\d+)/i)     { $free        = $1 * 1024; }
        elsif (/^SwapTotal:\s+(\d+)/i)   { $swap_total  = $1 * 1024; }
        elsif (/^SwapFree:\s+(\d+)/i)    { $swap_free   = $1 * 1024; }
        elsif (/^MemAvailable:\s+(\d+)/i){ $available   = $1 * 1024; }
    }

    if (!defined($total_size) || !defined($cached_used) || !defined($free)) {
        $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
        $self->{output}->option_exit();
    }

    $self->check_rhel_version(stdout => $stdout);

    my $physical_used = $total_size - $free;
    my $nobuf_used    = $physical_used - $buffer_used - $cached_used;
    if ($self->{rhel_71} == 1) {
        $nobuf_used -= $slab_used if defined($slab_used);
    }

    my $used_desc = 'buffers/cache';
    $used_desc .= '/slab' if ($self->{rhel_71} == 1 && defined($slab_used));

    $self->{memory} = {
        total          => $total_size,
        used           => $nobuf_used,
        free           => $total_size - $nobuf_used,
        prct_used      => $nobuf_used * 100 / $total_size,
        prct_free      => 100 - ($nobuf_used * 100 / $total_size),
        used_desc      => $used_desc,
        available      => $available,
        prct_available => $available * 100 / $total_size,
        buffer         => $buffer_used,
        cached         => $cached_used,
        slab           => $slab_used
    };

    if (defined($self->{option_results}->{check_swap}) &&
        defined($swap_total) && $swap_total > 0) {
        $self->{swap} = {
            total     => $swap_total,
            used      => $swap_total - $swap_free,
            free      => $swap_free,
            prct_used => 100 - ($swap_free * 100 / $swap_total),
            prct_free => ($swap_free * 100 / $swap_total)
        };
    }
}

1;

__END__

=head1 MODE

Check physical memory (need '/proc/meminfo' file).

Command used: cat /proc/meminfo /etc/redhat-release 2>&1

=over 8

=item B<--warning-memory-usage-prct>

Warning threshold for memory usage in percentage.

Example: C<--warning-memory-usage-prct=80>

=item B<--critical-memory-usage-prct>

Critical threshold for memory usage in percentage.

Example: C<--critical-memory-usage-prct=90>

=item B<--warning-memory-usage-free>

Warning threshold for free memory in bytes.

To trigger when free memory is below a value, use C<@0:value> syntax.

Example: C<--warning-memory-usage-free=@0:1073741824> (alert if free < 1 GB)

=item B<--critical-memory-usage-free>

Critical threshold for free memory in bytes.

Example: C<--critical-memory-usage-free=@0:536870912> (alert if free < 512 MB)

=item B<--swap>

Check swap usage.

=back

=head1 THRESHOLD LOGIC

When only one type of threshold is configured, standard single-threshold behavior applies.

When both types are configured simultaneously, AND logic is used:

  - CRITICAL: if at least one threshold (prct OR free) is CRITICAL.
  - WARNING: only if BOTH thresholds (prct AND free) are WARNING.
  - OK: if at least one threshold is OK.

=cut
