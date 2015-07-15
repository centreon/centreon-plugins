
package Paws::RedShift::DescribeTags {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has ResourceName => (is => 'ro', isa => 'Str');
  has ResourceType => (is => 'ro', isa => 'Str');
  has TagKeys => (is => 'ro', isa => 'ArrayRef[Str]');
  has TagValues => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeTags');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::TaggedResourceListMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeTagsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::DescribeTags - Arguments for method DescribeTags on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeTags on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method DescribeTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeTags.

As an example:

  $service_obj->DescribeTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<marker> parameter and retrying the command. If
the C<marker> field is empty, all response records have been retrieved
for the request.










=head2 MaxRecords => Int

  

The maximum number or response records to return in each call. If the
number of remaining response records exceeds the specified
C<MaxRecords> value, a value is returned in a C<marker> field of the
response. You can retrieve the next set of records by retrying the
command with the returned C<marker> value.










=head2 ResourceName => Str

  

The Amazon Resource Name (ARN) for which you want to describe the tag
or tags. For example,
C<arn:aws:redshift:us-east-1:123456789:cluster:t1>.










=head2 ResourceType => Str

  

The type of resource with which you want to view tags. Valid resource
types are:

=over

=item * Cluster

=item * CIDR/IP

=item * EC2 security group

=item * Snapshot

=item * Cluster security group

=item * Subnet group

=item * HSM connection

=item * HSM certificate

=item * Parameter group

=item * Snapshot copy grant

=back

For more information about Amazon Redshift resource types and
constructing ARNs, go to Constructing an Amazon Redshift Amazon
Resource Name (ARN) in the Amazon Redshift Cluster Management Guide.










=head2 TagKeys => ArrayRef[Str]

  

A tag key or keys for which you want to return all matching resources
that are associated with the specified key or keys. For example,
suppose that you have resources tagged with keys called C<owner> and
C<environment>. If you specify both of these tag keys in the request,
Amazon Redshift returns a response with all resources that have either
or both of these tag keys associated with them.










=head2 TagValues => ArrayRef[Str]

  

A tag value or values for which you want to return all matching
resources that are associated with the specified value or values. For
example, suppose that you have resources tagged with values called
C<admin> and C<test>. If you specify both of these tag values in the
request, Amazon Redshift returns a response with all resources that
have either or both of these tag values associated with them.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeTags in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

