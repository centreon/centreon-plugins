package storage::datacore::api::mode::alertscount;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

my %alerts_level = ('trace' => 0, 'info' => 1, 'warning' => 2, 'error' => 3);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    $options{options}->add_options(arguments => {

        'filter-server:s' => { name => 'filter_server', default => '' },
        'max-alert-age:s' => { name => 'max_alert_age' } });
    $self->{output} = $options{output};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alerts', type => 0 },
    ];
    $self->{maps_counters}->{alerts} = [
        # The label defines options name, a --warning-bytesallocatedpercentage and --critical-bytesallocatedpercentage will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        {
            label  => 'error',
            nlabel => 'datacore.event.error.count',
            set    => {
                key_values      => [ { name => 'error' } ],
                output_template => 'number of error alerts : %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }, {
        label  => 'warning',
        nlabel => 'datacore.alerts.warning.count',
        set    => {
            key_values      => [ { name => 'warning' } ],
            output_template => 'number of warning alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    }, {
        label  => 'info',
        nlabel => 'datacore.alerts.info.count',
        set    => {
            key_values      => [ { name => 'info' } ],
            output_template => 'number of info alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    }, {
        label  => 'trace',
        nlabel => 'datacore.alerts.trace.count',
        set    => {
            key_values      => [ { name => 'trace' } ],
            output_template => 'number of trace alerts : %s',
            perfdatas       => [ { template => '%d', min => 0 } ]
        }
    },
    ];

}

sub manage_selection {
    my ($self, %options) = @_;

    my $data = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/alerts'
    );
    my $alerts_count = $self->order_alerts($data);
    $self->{alerts}->{trace} = $alerts_count->{$alerts_level{trace}}->{count};
    $self->{alerts}->{info} = $alerts_count->{$alerts_level{info}}->{count};
    $self->{alerts}->{warning} = $alerts_count->{$alerts_level{warning}}->{count};
    $self->{alerts}->{error} = $alerts_count->{$alerts_level{error}}->{count};

}
# take a decoded json reference and send back a hash with loglevel as key and number of alerts as value.
sub order_alerts {
    my ($self, $alerts) = @_;
    my %alerts_count = (
        0 => {count => 0, list => []},
        1 => {count => 0, list => []},
        2 => {count => 0, list => []},
        3 => {count => 0, list => []});

    for my $alert (@$alerts) {

        # here we should allow to filter on somme element like machineName  or messageText
        # spec require to filter on time of the log.
        $alert->{TimeStamp} =~ /\/Date\((\d+)\)\/$/;
        my $alert_date = $1;
        # filter on age of the alert with a user defined max age
        next if (defined($self->{option_results}->{max_alert_age})
            and $alert_date < (time - $self->{option_results}->{max_alert_age}) * 1000);
        # filter on the machine issuing the alert with a user defined regex
        next if (defined($self->{option_results}->{filter_server})
            and $alert->{MachineName} =~ /$self->{option_results}->{filter_server}/);

        $alerts_count{$alert->{Level}}->{count}++;
        # we don't want to clog the long output, so we keep only the few first logs.
        #print "add log to " . $alert->{Level};
        push(@{$alerts_count{$alert->{Level}}->{list}}, $alert->{MessageText}) ;
    }

    #print $alerts_count{$alerts_level{error}};
    $self->{output}->output_add(long_msg => "error : " . join("\n", $alerts_count{$alerts_level{error}}->{list}));
    $self->{output}->output_add(long_msg => "info : " . join("\n", $alerts_count{$alerts_level{info}}->{list}));

    return \%alerts_count;
}
1;