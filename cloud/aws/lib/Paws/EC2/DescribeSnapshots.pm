
package Paws::EC2::DescribeSnapshots {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has OwnerIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'Owner' );
  has RestorableByUserIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'RestorableBy' );
  has SnapshotIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SnapshotId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeSnapshots');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeSnapshotsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSnapshots - Arguments for method DescribeSnapshots on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeSnapshots on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeSnapshots.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeSnapshots.

As an example:

  $service_obj->DescribeSnapshots(Att1 => $value1, Att2 => $value2, ...);

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

C<description> - A description of the snapshot.

=item *

C<owner-alias> - The AWS account alias (for example, C<amazon>) that
owns the snapshot.

=item *

C<owner-id> - The ID of the AWS account that owns the snapshot.

=item *

C<progress> - The progress of the snapshot, as a percentage (for
example, 80%).

=item *

C<snapshot-id> - The snapshot ID.

=item *

C<start-time> - The time stamp when the snapshot was initiated.

=item *

C<status> - The status of the snapshot (C<pending> | C<completed> |
C<error>).

=item *

C<tag>:I<key>=I<value> - The key/value combination of a tag assigned to
the resource.

=item *

C<tag-key> - The key of a tag assigned to the resource. This filter is
independent of the C<tag-value> filter. For example, if you use both
the filter "tag-key=Purpose" and the filter "tag-value=X", you get any
resources assigned both the tag key Purpose (regardless of what the
tag's value is), and the tag value X (regardless of what the tag's key
is). If you want to list only resources where Purpose is X, see the
C<tag>:I<key>=I<value> filter.

=item *

C<tag-value> - The value of a tag assigned to the resource. This filter
is independent of the C<tag-key> filter.

=item *

C<volume-id> - The ID of the volume the snapshot is for.

=item *

C<volume-size> - The size of the volume, in GiB.

=back










=head2 MaxResults => Int

  

The maximum number of snapshot results returned by C<DescribeSnapshots>
in paginated output. When this parameter is used, C<DescribeSnapshots>
only returns C<MaxResults> results in a single page along with a
C<NextToken> response element. The remaining results of the initial
request can be seen by sending another C<DescribeSnapshots> request
with the returned C<NextToken> value. This value can be between 5 and
1000; if C<MaxResults> is given a value larger than 1000, only 1000
results are returned. If this parameter is not used, then
C<DescribeSnapshots> returns all results. You cannot specify this
parameter and the snapshot IDs parameter in the same request.










=head2 NextToken => Str

  

The C<NextToken> value returned from a previous paginated
C<DescribeSnapshots> request where C<MaxResults> was used and the
results exceeded the value of that parameter. Pagination continues from
the end of the previous results that returned the C<NextToken> value.
This value is C<null> when there are no more results to return.










=head2 OwnerIds => ArrayRef[Str]

  

Returns the snapshots owned by the specified owner. Multiple owners can
be specified.










=head2 RestorableByUserIds => ArrayRef[Str]

  

One or more AWS accounts IDs that can create volumes from the snapshot.










=head2 SnapshotIds => ArrayRef[Str]

  

One or more snapshot IDs.

Default: Describes snapshots for which you have launch permissions.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeSnapshots in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

