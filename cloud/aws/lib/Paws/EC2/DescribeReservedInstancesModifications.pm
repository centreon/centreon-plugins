
package Paws::EC2::DescribeReservedInstancesModifications {
  use Moose;
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'nextToken' );
  has ReservedInstancesModificationIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ReservedInstancesModificationId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedInstancesModifications');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeReservedInstancesModificationsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeReservedInstancesModifications - Arguments for method DescribeReservedInstancesModifications on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedInstancesModifications on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeReservedInstancesModifications.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedInstancesModifications.

As an example:

  $service_obj->DescribeReservedInstancesModifications(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<client-token> - The idempotency token for the modification request.

=item *

C<create-date> - The time when the modification request was created.

=item *

C<effective-date> - The time when the modification becomes effective.

=item *

C<modification-result.reserved-instances-id> - The ID for the Reserved
Instances created as part of the modification request. This ID is only
available when the status of the modification is C<fulfilled>.

=item *

C<modification-result.target-configuration.availability-zone> - The
Availability Zone for the new Reserved Instances.

=item *

C<modification-result.target-configuration.instance-count > - The
number of new Reserved Instances.

=item *

C<modification-result.target-configuration.instance-type> - The
instance type of the new Reserved Instances.

=item *

C<modification-result.target-configuration.platform> - The network
platform of the new Reserved Instances (C<EC2-Classic> | C<EC2-VPC>).

=item *

C<reserved-instances-id> - The ID of the Reserved Instances modified.

=item *

C<reserved-instances-modification-id> - The ID of the modification
request.

=item *

C<status> - The status of the Reserved Instances modification request
(C<processing> | C<fulfilled> | C<failed>).

=item *

C<status-message> - The reason for the status.

=item *

C<update-date> - The time when the modification request was last
updated.

=back










=head2 NextToken => Str

  

The token to retrieve the next page of results.










=head2 ReservedInstancesModificationIds => ArrayRef[Str]

  

IDs for the submitted modification request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedInstancesModifications in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

