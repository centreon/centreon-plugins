# Copyright 2024 Centreon (http://www.centreon.com/)
# Licensed under the Apache License, Version 2.0

package hardware::server::cisco::ucs::redfish::mode::faults;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::statefile;
use POSIX qw(mktime);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'events', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All system events are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'events.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total events: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{events} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'severity' }, { name => 'message' },
                { name => 'sensor' }, { name => 'created' },
            ],
            output_template => "event '%s' [severity: %s] [sensor: %s]: %s [created: %s]",
            output_use      => ['id', 'severity', 'sensor', 'message', 'created'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

# Redfish severity values: OK, Warning, Critical (also MessageSeverity on some UCS)
sub _threshold_check {
    my ($self, %options) = @_;
    my $sev = lc($self->{result_values}->{severity} // '');
    return 'OK'       if $sev eq 'ok';
    return 'WARNING'  if $sev =~ /^warning/;
    return 'CRITICAL' if $sev =~ /^critical/;
    return 'UNKNOWN';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Event '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-msg:s'      => { name => 'filter_msg' },
        'filter-severity:s' => { name => 'filter_severity' },
        'retention-time:s'  => { name => 'retention_time' },
        'memory'            => { name => 'memory' },
        'log-service:s'     => { name => 'log_service', default => 'SEL' },
        'warning-status:s'  => { name => 'warning_status',  default => '%{severity} =~ /Warning/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{severity} =~ /Critical/i' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(option_results => $self->{option_results});
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_path = $options{custom}->{api_path};

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(
            statefile => 'cisco_ucs_redfish_faults_' . $options{custom}->{hostname}
        );
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    # Find Managers and their LogServices
    my $managers = $options{custom}->get_collection(endpoint => '/Managers');
    my @raw_events;

    for my $mgr (@{$managers}) {
        my $log_url = $mgr->{LogServices}->{'@odata.id'} // '';
        next if $log_url eq '';
        $log_url =~ s{^\Q$api_path\E}{};

        my $log_services = $options{custom}->request(endpoint => $log_url);
        for my $svc_ref (@{$log_services->{Members} // []}) {
            my $svc_url = $svc_ref->{'@odata.id'} // '';
            next if $svc_url eq '';
            $svc_url =~ s{^\Q$api_path\E}{};

            # Only read the configured log service (default: SEL)
            next unless $svc_url =~ /$self->{option_results}->{log_service}/i;

            my $entries = $options{custom}->request(endpoint => $svc_url . '/Entries');
            push @raw_events, @{$entries->{Members} // []};
        }
    }

    $self->{global} = { total => 0 };
    $self->{events} = {};
    my $current_time = time();

    for my $event (@raw_events) {
        my $id       = $event->{'Id'}         // 'unknown';
        my $severity = $event->{'Severity'}   // $event->{'MessageSeverity'} // 'OK';
        my $message  = $event->{'Message'}    // '';
        my $sensor   = $event->{'SensorType'} // $event->{'EntryType'} // '';
        my $created  = $event->{'Created'}    // '';

        next if $severity =~ /^OK$/i;

        next if defined($self->{option_results}->{filter_msg})
            && $self->{option_results}->{filter_msg} ne ''
            && $message !~ /$self->{option_results}->{filter_msg}/;

        next if defined($self->{option_results}->{filter_severity})
            && $self->{option_results}->{filter_severity} ne ''
            && $severity !~ /$self->{option_results}->{filter_severity}/;

        if (defined($self->{option_results}->{retention_time})
            && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $event_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $current_time - $event_time > $self->{option_results}->{retention_time} * 60;
        }

        if (defined($last_time)
            && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $event_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $event_time <= $last_time;
        }

        $self->{global}->{total}++;
        $self->{events}->{$id} = {
            id       => $id,
            severity => $severity,
            message  => $message,
            sensor   => $sensor,
            created  => $created,
        };
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS system events via Redfish LogServices.

=over 8

=item B<--log-service>

Log service name to query (default: SEL). Use 'FaultList' for Cisco-specific logs.

=item B<--filter-msg>

Filter events by message (regexp).

=item B<--filter-severity>

Filter events by severity (regexp).

=item B<--retention-time>

Only report events from the last N minutes.

=item B<--memory>

Only report new events since last check.

=item B<--warning-status>

Warning threshold (default: '%{severity} =~ /Warning/i').

=item B<--critical-status>

Critical threshold (default: '%{severity} =~ /Critical/i').

=back

=cut
