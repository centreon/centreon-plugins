
package Paws::EC2::DescribeAvailabilityZones {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has ZoneNames => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ZoneName' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeAvailabilityZones');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeAvailabilityZonesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeAvailabilityZones - Arguments for method DescribeAvailabilityZones on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeAvailabilityZones on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeAvailabilityZones.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeAvailabilityZones.

As an example:

  $service_obj->DescribeAvailabilityZones(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<message> - Information about the Availability Zone.

=item *

C<region-name> - The name of the region for the Availability Zone (for
example, C<us-east-1>).

=item *

C<state> - The state of the Availability Zone (C<available> |
C<impaired> | C<unavailable>).

=item *

C<zone-name> - The name of the Availability Zone (for example,
C<us-east-1a>).

=back










=head2 ZoneNames => ArrayRef[Str]

  

The names of one or more Availability Zones.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeAvailabilityZones in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

