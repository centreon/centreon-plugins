package storage::datacore::api::mode::eventcount;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    $options{options}->add_options(arguments => {

        'filter-server:s' => { name => 'filter_server', default => '' },
        'filter-pool:s'   => { name => 'filter_pool', default => '' } });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'event', type => 1 },
    ];
    $self->{maps_counters}->{event} = [
        # The label defines options name, a --warning-bytesallocatedpercentage and --critical-bytesallocatedpercentage will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        {
            label  => 'trace',
            nlabel => 'datacore.event.trace.count',
            set    => {
                key_values      => [ { name => 'trace' } ],
                output_template => 'number of trace event : %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },        {
            label  => 'info',
            nlabel => 'datacore.event.info.count',
            set    => {
                key_values      => [ { name => 'info' } ],
                output_template => 'number of info event : %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },{
            label  => 'warning',
            nlabel => 'datacore.event.warning.count',
            set    => {
                key_values      => [ { name => 'warning' } ],
                output_template => 'number of warning event : %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },{
            label  => 'critical',
            nlabel => 'datacore.event.critical.count',
            set    => {
                key_values      => [ { name => 'critical' } ],
                output_template => 'number of critical event : %s',
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
    $self->{event}->{warning} = "598";

}
1;