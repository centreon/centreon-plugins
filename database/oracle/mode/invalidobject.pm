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

package database::oracle::mode::invalidobject;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_invalid_output', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'objects', set => {
                key_values => [ { name => 'invalid_objects' } ],
                output_template => 'objects : %s',
                perfdatas => [
                    { label => 'invalid_objects', value => 'invalid_objects', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'indexes', set => {
                key_values => [ { name => 'invalid_indexes' } ],
                output_template => 'indexes : %s',
                perfdatas => [
                    { label => 'invalid_indexes', value => 'invalid_indexes', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'ind-partitions', set => {
                key_values => [ { name => 'invalid_ind_partitions' } ],
                output_template => 'index partitions : %s',
                perfdatas => [
                    { label => 'invalid_ind_partitions', value => 'invalid_ind_partitions', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'ind-subpartitions', set => {
                key_values => [ { name => 'invalid_ind_subpartitions' } ],
                output_template => 'index subpartitions : %s',
                perfdatas => [
                    { label => 'invalid_ind_subpartitions', value => 'invalid_ind_subpartitions', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'registry-components', set => {
                key_values => [ { name => 'invalid_registry_components' } ],
                output_template => 'registry components : %s',
                perfdatas => [
                    { label => 'invalid_registry_components', value => 'invalid_registry_components', template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-message:s"    => { name => 'filter_message' },
        "retention-objects:s" => { name => 'retention_objects', default => 3 },
    });
    
    return $self;
}

sub prefix_invalid_output {
    my ($self, %options) = @_;
    
    return "Invalid ";
}

sub get_invalids {
    my ($self, %options) = @_;
    
    $self->{global}->{$options{type}} = 0;
    $options{sql}->query(query => $options{query});
    my $result = $options{sql}->fetchall_arrayref();
    foreach (@$result) {
        if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' &&
            $_->[0] !~ /$self->{option_results}->{filter_message}/) {
            $self->{output}->output_add(long_msg => "skipping $options{type} => '" . $_->[0] . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{$options{type}}++;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $options{sql}->connect();

    $self->get_invalids(%options, type => 'invalid_objects', query => q{
          SELECT
            O.object_type||' '||O.owner||'.'||O.object_name||' is '||O.status
          FROM dba_objects O 
            LEFT OUTER JOIN DBA_MVIEW_refresh_times V ON O.object_name = V.NAME AND O.owner = V.owner
          WHERE (LAST_REFRESH <= (SELECT sysdate - } . $self->{option_results}->{retention_objects} . q{ FROM dual) OR LAST_REFRESH is null) AND
            STATUS = 'INVALID' AND O.object_name NOT LIKE 'BIN$%'
    });

    $self->get_invalids(%options, type => 'invalid_indexes', query => q{
          SELECT index_type||' index '||owner||'.'||index_name||' of '||table_owner||'.'||table_name||' is '||status
          FROM dba_indexes
          WHERE status <> 'VALID' AND status <> 'N/A'
    });
    
    $self->get_invalids(%options, type => 'invalid_ind_partitions', query => q{
          SELECT partition_name||' of '||index_owner||'.'||index_name||' is '||status
          FROM dba_ind_partitions
          WHERE status <> 'USABLE' AND status <> 'N/A'
    });

    if ($options{sql}->is_version_minimum(version => '10.x')) {
        $self->get_invalids(%options, type => 'invalid_ind_subpartitions', query => q{
          SELECT subpartition_name||' of '||partition_name||' of '||index_owner||'.'||index_name||' is '||status
            FROM dba_ind_subpartitions
            WHERE status <> 'USABLE' AND status <> 'N/A'
        });
    }

    if ($options{sql}->is_version_minimum(version => '10.x')) {
        $self->get_invalids(%options, type => 'invalid_registry_components', query => q{
          SELECT namespace||'.'||comp_name||'-'||version||' is '||status
            FROM dba_registry
            WHERE status <> 'VALID' AND status <> 'OPTION OFF'
        });
    } else {
        $self->get_invalids(%options, type => 'invalid_registry_components', query => q{
          SELECT 'SCHEMA.'||comp_name||'-'||version||' is '||status
            FROM dba_registry
            WHERE status <> 'VALID' AND status <> 'OPTION OFF'
        });
    }

    $options{sql}->disconnect();
}

1;

__END__

=head1 MODE

Check faulty objects, indices, partitions.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^indexes$'

=item B<--retention-objects>

Retention in days for invalid objects (default : 3).

=item B<--filter-message>

Filter by message (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'objects', 'indexes', 'ind-partitions', 'ind-subpartitions',
'registry-components'.

=item B<--critical-*>

Threshold critical.
Can be: 'objects', 'indexes', 'ind-partitions', 'ind-subpartitions',
'registry-components'.

=back

=cut
