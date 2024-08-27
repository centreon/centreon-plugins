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

package database::db2::mode::tablespaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{tbsname}],
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_free_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{tbsname}],
        value => $self->{result_values}->{free},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_prct_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{tbsname}],
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub prefix_tbs_output {
    my ($self, %options) = @_;

    return sprintf(
        "tablespace '%s' ",
        $options{instance_value}->{tbsname}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tbs', type => 1, cb_prefix_output => 'prefix_tbs_output', message_multiple => 'All tablespaces are ok' }
    ];

    $self->{maps_counters}->{tbs} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} !~ /normal/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'tbsname' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'space-usage', nlabel => 'tablespace.space.usage.bytes', set => {
                key_values => [ 
                    { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'tbsname' }, { name => 'dbname' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'space-usage-free', nlabel => 'tablespace.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'tbsname' }, { name => 'dbname' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_free_perfdata')
            }
        },
        { label => 'space-usage-prct', nlabel => 'tablespace.space.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'tbsname' }, { name => 'dbname' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_prct_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    # from: https://labs.consol.de/nagios/check_db2_health/
    $options{sql}->query(query => q{
        SELECT
            tbsp_name, tbsp_type, tbsp_state, tbsp_usable_size_kb,
            tbsp_total_size_kb, tbsp_used_size_kb, tbsp_free_size_kb,
            COALESCE(tbsp_using_auto_storage, 0),
            COALESCE(tbsp_auto_resize_enabled, 0),
            -- COALESCE(tbsp_increase_size,0), --bigint, conversion problems with dbd
            CASE WHEN tbsp_increase_size IS NULL OR tbsp_increase_size = 0 THEN 0 ELSE 1 END,
            COALESCE(tbsp_increase_size_percent, 0)
        FROM
            sysibmadm.tbsp_utilization
        WHERE
            tbsp_type = 'DMS'
        UNION ALL
        SELECT
            tu.tbsp_name, tu.tbsp_type, tu.tbsp_state, tu.tbsp_usable_size_kb,
            tu.tbsp_total_size_kb, tu.tbsp_used_size_kb,
            (cu.fs_total_size_kb - cu.fs_used_size_kb) AS tbsp_free_size_kb,
            0, 0, 0, 0
        FROM
            sysibmadm.tbsp_utilization tu
        INNER JOIN (
            SELECT
               tbsp_id,
               1 AS fs_total_size_kb,
               0 AS fs_used_size_kb
            FROM
                sysibmadm.container_utilization
            WHERE
                (fs_total_size_kb IS NULL OR fs_used_size_kb IS NULL)
            GROUP BY
                tbsp_id
        ) cu
        ON
            (tu.tbsp_type = 'SMS' AND tu.tbsp_id = cu.tbsp_id)
        UNION ALL
        SELECT
            tu.tbsp_name, tu.tbsp_type, tu.tbsp_state, tu.tbsp_usable_size_kb,
            tu.tbsp_total_size_kb, tu.tbsp_used_size_kb,
            (cu.fs_total_size_kb - cu.fs_used_size_kb) AS tbsp_free_size_kb,
            0, 0, 0, 0
        FROM
            sysibmadm.tbsp_utilization tu
        INNER JOIN (
            SELECT
               tbsp_id,
               SUM(fs_total_size_kb) AS fs_total_size_kb,
               SUM(fs_used_size_kb) AS fs_used_size_kb
            FROM
                sysibmadm.container_utilization
            WHERE
                (fs_total_size_kb IS NOT NULL AND fs_used_size_kb IS NOT NULL)
            GROUP BY
                tbsp_id
        ) cu
        ON
            (tu.tbsp_type = 'SMS' AND tu.tbsp_id = cu.tbsp_id)
    });

    $self->{tbs} = {};
    my $dbname = $options{sql}->get_database_name();
    while (my $row = $options{sql}->fetchrow_arrayref()) {
        my $type = $row->[1] =~ /^[dD]/ ? 'dms' : 'sms';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $row->[0] !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping tablespace '" . $row->[0] . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping tablespace '" . $row->[0] . "': no matching filter.", debug => 1);
            next;
        }

        my $total = $row->[3] * 1024; # usable_size
        my $used = $row->[5] * 1024; # used_size
        if ($type eq 'sms') {
            $total = ($row->[5] * 1024) + ($row->[6] * 1024); # used_size + free_size
        }

        $self->{tbs}->{ $row->[0] } = {
            dbname => $dbname,
            tbsname => $row->[0],
            type => $type,
            state => $row->[2],
            total => $total,
            used => $used,
            free => $total - $used,
            prct_used => $used * 100 / $total,
            prct_free => 100 - ($used * 100 / $total)
        };
    }
}

1;

__END__

=head1 MODE

Check tablespaces.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-type>

Filter tablespaces by type (can be a regexp).

=item B<--filter-name>

Filter tablespaces by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{tbsname}, %{type}, %{state}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{tbsname}, %{type}, %{state}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} !~ /normal/i').
You can use the following variables: %{tbsname}, %{type}, %{state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
