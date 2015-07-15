
package Paws::CloudTrail::LookupEvents {
  use Moose;
  has EndTime => (is => 'ro', isa => 'Str');
  has LookupAttributes => (is => 'ro', isa => 'ArrayRef[Paws::CloudTrail::LookupAttribute]');
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'LookupEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudTrail::LookupEventsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail::LookupEvents - Arguments for method LookupEvents on Paws::CloudTrail

=head1 DESCRIPTION

This class represents the parameters used for calling the method LookupEvents on the 
AWS CloudTrail service. Use the attributes of this class
as arguments to method LookupEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to LookupEvents.

As an example:

  $service_obj->LookupEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EndTime => Str

  

Specifies that only events that occur before or at the specified time
are returned. If the specified end time is before the specified start
time, an error is returned.










=head2 LookupAttributes => ArrayRef[Paws::CloudTrail::LookupAttribute]

  

Contains a list of lookup attributes. Currently the list can contain
only one item.










=head2 MaxResults => Int

  

The number of events to return. Possible values are 1 through 50. The
default is 10.










=head2 NextToken => Str

  

The token to use to get the next page of results after a previous API
call. This token must be passed in with the same parameters that were
specified in the the original call. For example, if the original call
specified an AttributeKey of 'Username' with a value of 'root', the
call with NextToken should include those same parameters.










=head2 StartTime => Str

  

Specifies that only events that occur after or at the specified time
are returned. If the specified start time is after the specified end
time, an error is returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method LookupEvents in L<Paws::CloudTrail>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

