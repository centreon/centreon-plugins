package storage::datacore::api::mode::poolspaceusage;
use strict;
use warnings;

# Use the counter module. It will save you a lot of work and will manage a lot of things for you.
# Consider this as mandatory when writing a new mode.
use base qw(centreon::plugins::templates::counter);
# Import some functions that will make your life easier when dealing with string values

# We will have to process some JSON, no need to reinvent the wheel, load the lib you installed in a previous section
use JSON::XS;
sub empty {
    my $value = shift;
    if (!defined($value) || $value eq '') {
        return 1;
    }
    return 0;
}
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
        { name => 'BytesAllocatedPercentage', type => 0 },
    ];
    $self->{maps_counters}->{BytesAllocatedPercentage} = [
        # The label defines options name, a --warning-bytesallocatedpercentage and --critical-bytesallocatedpercentage will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        {
            label => 'bytesallocatedpercentage',
            nlabel => 'datacore.pool.bytesallocated.percentage',
            set => {
            # Key value name is the name we will use to pass the data to this counter. You can have several ones.
                key_values => [ { name => 'bytesallocatedpercentage' } ],
                # Output template describe how the value will display
                output_template => 'Bytes Allocated : %s %%',
                # Perfdata array allow you to define relevant metrics properties (min, max) and its sprintf template format
                perfdatas => [
                    { template => '%d', unit=> '%', min => 0, max => 100}
                ]
            }
        }
    ];

}

sub manage_selection {
    my ($self, %options) = @_;

    my $pool_id = $options{custom}->request_pool_id(
        filter_server => $self->{option_results}->{filter_server},
        filter_pool   => $self->{option_results}->{filter_pool});


    my $data = $options{custom}->request_api(
        url_path  => '/RestService/rest.svc/1.0/performances/' . $pool_id,
    );
    $self->{BytesAllocatedPercentage}->{bytesallocatedpercentage} = $data->[0]->{"BytesAllocatedPercentage"};

}
1;