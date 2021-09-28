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

package hardware::devices::hms::ewon::snmp::mode::tags;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'status: ' . $self->{result_values}->{status};
}

sub custom_value_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'tag.value.count',
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{value},
        warning => defined($self->{instance_mode}->{warning_instance}) ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{instance_mode}->{warning_instance}) : undef,
        critical => defined($self->{instance_mode}->{critical_instance}) ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{instance_mode}->{critical_instance}) : undef
    );
}

sub custom_value_threshold {
    my ($self, %options) = @_;

    $self->{instance_mode}->{warning_instance} = undef;
    $self->{instance_mode}->{critical_instance} = undef;

    my $thresholds = [];
    foreach my $th (('critical', 'warning')) {
        my $i = 0;
        foreach (@{$self->{instance_mode}->{'tag_threshold_' . $th}}) {
            if ($self->{result_values}->{name} =~ /$_/ ||
                $self->{result_values}->{index} =~ /$_/) {
                $self->{instance_mode}->{$th . '_instance'} = $i; 
                push @$thresholds, { label => $th . '-' . $i, exit_litteral => $th };
                last;
            }
            $i++;
        }
    }

    return 'ok' if (scalar(@$thresholds) <= 0);

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value}, 
        threshold => $thresholds
    );
}

sub custom_value_output {
    my ($self, %options) = @_;

    my $output = 'value: %s';
    foreach (@{$self->{instance_mode}->{tag_output_values}}) {
        if ($self->{result_values}->{name} =~ /$_->{match}/ ||
            $self->{result_values}->{index} =~ /$_->{match}/) {
            $output = $_->{output};
            last;
        }
    }
    return sprintf(
        $output,
        $self->{result_values}->{value}
    );
}

sub prefix_tag_output {
    my ($self, %options) = @_;
    
    return "Tag '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'tags', type => 1, cb_prefix_output => 'prefix_tag_output', message_multiple => 'All tags are ok' }
    ];
    
    $self->{maps_counters}->{tags} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /alarm/', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'value', threshold => 0, set => {
                key_values => [ { name => 'value' }, { name => 'index' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_perfdata => $self->can('custom_value_perfdata'),
                closure_custom_threshold_check => $self->can('custom_value_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-tag-index:s'        => { name => 'filter_tag_index' },
        'filter-tag-name:s'         => { name => 'filter_tag_name' },
        'cache-expires-in:s'        => { name => 'cache_expires_in' },
        'tag-output-value:s@'       => { name => 'tag_output_value' },
        'tag-threshold-warning:s@'  => { name => 'tag_threshold_warning' },
        'tag-threshold-critical:s@' => { name => 'tag_threshold_critical' }
    });

    $self->{cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{cache_expires_in} = (defined($self->{option_results}->{cache_expires_in})) && $self->{option_results}->{cache_expires_in} =~ /(\d+)/ ?
        $1 : 7200;
    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{tag_output_values} = [];
    if (defined($self->{option_results}->{tag_output_value})) {
        foreach (@{$self->{option_results}->{tag_output_value}}) {
            my @fields = split /,/;
            my ($tag_output, $tag_match) = ($fields[0], '.*');
            if (defined($fields[1]) && $fields[1] ne '') {
                $tag_output = $fields[1];
                $tag_match = $fields[0];
            }
            next if (!defined($tag_output) || $tag_output eq '');
            push @{$self->{tag_output_values}}, { match => $tag_match, output => $tag_output}; 
        }
    }

    foreach (('warning', 'critical')) {
        my $i = 0;
        $self->{'tag_threshold_' . $_} = [];
        next if (!defined($self->{option_results}->{'tag_threshold_' . $_}));
        foreach my $option (@{$self->{option_results}->{'tag_threshold_' . $_}}) {
            my @fields = split(/,/, $option);
            my ($tag_threshold, $tag_match) = ($fields[0], '.*');
            if (defined($fields[1]) && $fields[1] ne '') {
                $tag_threshold = $fields[1];
                $tag_match = $fields[0];
            }
            next if (!defined($tag_threshold) || $tag_threshold eq '');
            if (($self->{perfdata}->threshold_validate(label => $_ . '-' . $i, value => $tag_threshold)) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong threshold '" . $tag_threshold . "'.");
                $self->{output}->option_exit();
            }
            push @{$self->{'tag_threshold_' . $_}}, $tag_match; 
            $i++;
        }
    }
}

sub get_tags {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'hms_ewon_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    my $updated = $self->{cache}->get(name => 'updated');
    my $tags = $self->{cache}->get(name => 'tags');

    if ($has_cache_file == 0 || !defined($updated) || (time() > ($updated + $self->{option_results}->{cache_expires_in}))) {
        my $snmp_result = $options{snmp}->get_table(
            oid => '.1.3.6.1.4.1.8284.2.1.3.1.11.1.3', # tagCfgName
            nothing_quit => 1
        );
        foreach (keys %$snmp_result) {
            /\.(\d+)$/;
            $tags->{$1} = $snmp_result->{$_};
        }

        $self->{cache}->write(data => {
            tags => $tags,
            updated => time()
        });
    }

    return $tags;
}

my $map_status = {
    0 => 'none', 1 => 'pretrig', 2 => 'alarm',
    3 => 'ack', 4 => 'rtn'
};
my $mapping = {
    value  => { oid => '.1.3.6.1.4.1.8284.2.1.3.1.11.1.4' }, # tagValue    
    status => { oid => '.1.3.6.1.4.1.8284.2.1.3.1.11.1.9', map => $map_status } # tagAlStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $tags = $self->get_tags(snmp => $options{snmp});

    $self->{tags} = {};
    foreach (keys %$tags) {
        $tags->{$_} = $self->{output}->decode($tags->{$_});
        if (defined($self->{option_results}->{filter_tag_index}) && $self->{option_results}->{filter_tag_index} ne '' &&
            $_ !~ /$self->{option_results}->{filter_tag_index}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $tags->{$_} . "': no matching 'org' filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_tag_name}) && $self->{option_results}->{filter_tag_name} ne '' &&
            $tags->{$_} !~ /$self->{option_results}->{filter_tag_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $tags->{$_} . "': no matching 'org' filter.", debug => 1);
            next;
        }

        $self->{tags}->{$_} = { name => $tags->{$_}, index => $_ };
    }

    if (scalar(keys %{$self->{tags}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No tags found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{tags}}],
        instance_regexp => '^(.*)$'
    );
    my $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{tags}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{tags}->{$_}->{value} = $result->{value};
        $self->{tags}->{$_}->{status} = $result->{status};
    }
}

1;

__END__

=head1 MODE

Check ewon tags.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-tag-index>

Filter tags by index (can be a regexp).

=item B<--filter-tag-name>

Filter tags by name (can be a regexp).

=item B<--cache-expires-in>

Cache expires each X secondes (Default: 7200)

=item B<--tag-output-value>

Change tag output (syntax: [regexp,]output) (Default: 'value: %s').
E.g: --tag-output-value='tagNameMatch,remaining: %s%%' 

=item B<--tag-threshold-warning> B<--tag-threshold-critical>

Set tag value threshold (syntax: [regexp,]threshold).
E.g: --tag-threshold-warning='tagNameMatch,50' --tag-threshold-critical='tagNameMatch,80'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /alarm/').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
