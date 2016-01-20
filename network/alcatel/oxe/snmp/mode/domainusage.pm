#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::alcatel::oxe::snmp::mode::domainusage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    domain => { 
        '000_cac-usage'   => {
            set => {
                key_values => [ { name => 'display' }, { name => 'cacUsed' }, { name => 'cacAllowed' } ],
                closure_custom_calc => \&custom_cac_usage_calc,
                closure_custom_calc_extra_options => { label_output => 'External Communication', label_perf => 'cac' },
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            },
        },
        '001_conference-usage'   => {
            set => {
                key_values => [ { name => 'display' }, { name => 'confBusy' }, { name => 'confAvailable' } ],
                closure_custom_calc => \&custom_conference_usage_calc,
                closure_custom_calc_extra_options => { label_output => 'Conference circuits', label_perf => 'conference' },
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            },
        },
    }
};

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(label => $self->{result_values}->{label_perf} . '_used' . $extra_label,
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $self->{result_values}->{label_output},
                      $self->{result_values}->{total},
                      $self->{result_values}->{used}, $self->{result_values}->{prct_used},
                      $self->{result_values}->{free}, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_cac_usage_calc {
    my ($self, %options) = @_;

    if ($options{new_datas}->{$self->{instance} . '_cacAllowed'} <= 0) {
        $self->{error_msg} = "skipped (no allowed)";
        return -2;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_cacAllowed'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_cacUsed'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label_perf} = $options{extra_options}->{label_perf};
    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    return 0;
}

sub custom_conference_usage_calc {
    my ($self, %options) = @_;

    if ($options{new_datas}->{$self->{instance} . '_confAvailable'} <= 0) {
        $self->{error_msg} = "skipped (no available)";
        return -2;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_confAvailable'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_confBusy'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label_perf} = $options{extra_options}->{label_perf};
    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "no-component:s"          => { name => 'no_component' },
                                  "filter-domain:s"         => { name => 'filter_domain' },
                                });
    $self->{no_components} = undef;
    
    foreach my $key (('domain')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('domain')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{domain}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Domains are ok');
    }
    
    foreach my $id (sort keys %{$self->{domain}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{domain}}) {
            my $obj = $maps_counters->{domain}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{domain}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Domain '$self->{domain}->{$id}->{display}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Domain '$self->{domain}->{$id}->{display}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Domain '$self->{domain}->{$id}->{display}' $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    confAvailable            => { oid => '.1.3.6.1.4.1.637.64.4400.1.3.1.2' },
    confBusy                 => { oid => '.1.3.6.1.4.1.637.64.4400.1.3.1.3' },
    confOutOfOrder           => { oid => '.1.3.6.1.4.1.637.64.4400.1.3.1.4' },
    cacAllowed               => { oid => '.1.3.6.1.4.1.637.64.4400.1.3.1.9' },
    cacUsed                  => { oid => '.1.3.6.1.4.1.637.64.4400.1.3.1.10' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{domain} = {};
    my $oid_ipDomainEntry = '.1.3.6.1.4.1.637.64.4400.1.3.1';
    $self->{results} = $self->{snmp}->get_table(oid => $oid_ipDomainEntry,
                                                nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{cacAllowed}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        if (defined($self->{option_results}->{filter_domain}) && $self->{option_results}->{filter_domain} ne '' &&
            $instance !~ /$self->{option_results}->{filter_domain}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $self->{domain}->{$instance} = { display => $instance,
                                         %{$result}};
    }
    
    if (scalar(keys %{$self->{domain}}) <= 0) {
        $self->{output}->output_add(severity => defined($self->{no_components}) ? $self->{no_components} : 'unknown',
                                    short_msg => 'No components are checked.');
    }
}

1;

__END__

=head1 MODE

Check Domain usages.

=over 8

=item B<--filter-domain>

Filter by domain (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'cac-usage' (%), 'conference-usage' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'cac-usage' (%), 'conference-usage' (%).

=item B<--no-component>

Set the threshold where no components (Default: 'unknown' returns).

=back

=cut
