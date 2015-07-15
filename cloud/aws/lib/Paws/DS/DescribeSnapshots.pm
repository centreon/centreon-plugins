
package Paws::DS::DescribeSnapshots {
  use Moose;
  has DirectoryId => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has SnapshotIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeSnapshots');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::DescribeSnapshotsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::DescribeSnapshots - Arguments for method DescribeSnapshots on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeSnapshots on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method DescribeSnapshots.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeSnapshots.

As an example:

  $service_obj->DescribeSnapshots(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DirectoryId => Str

  

The identifier of the directory to retrieve snapshot information for.










=head2 Limit => Int

  

The maximum number of objects to return.










=head2 NextToken => Str

  

The I<DescribeSnapshotsResult.NextToken> value from a previous call to
DescribeSnapshots. Pass null if this is the first call.










=head2 SnapshotIds => ArrayRef[Str]

  

A list of identifiers of the snapshots to obtain the information for.
If this member is null or empty, all snapshots are returned using the
I<Limit> and I<NextToken> members.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeSnapshots in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

