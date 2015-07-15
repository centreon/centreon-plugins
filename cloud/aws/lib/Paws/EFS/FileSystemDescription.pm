
package Paws::EFS::FileSystemDescription {
  use Moose;
  has CreationTime => (is => 'ro', isa => 'Str', required => 1);
  has CreationToken => (is => 'ro', isa => 'Str', required => 1);
  has FileSystemId => (is => 'ro', isa => 'Str', required => 1);
  has LifeCycleState => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str');
  has NumberOfMountTargets => (is => 'ro', isa => 'Int', required => 1);
  has OwnerId => (is => 'ro', isa => 'Str', required => 1);
  has SizeInBytes => (is => 'ro', isa => 'Paws::EFS::FileSystemSize', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::FileSystemDescription

=head1 ATTRIBUTES

=head2 B<REQUIRED> CreationTime => Str

  

The time at which the file system was created, in seconds, since
1970-01-01T00:00:00Z.









=head2 B<REQUIRED> CreationToken => Str

  

Opaque string specified in the request.









=head2 B<REQUIRED> FileSystemId => Str

  

The file system ID assigned by Amazon EFS.









=head2 B<REQUIRED> LifeCycleState => Str

  

A predefined string value that indicates the lifecycle phase of the
file system.









=head2 Name => Str

  

You can add tags to a file system (see CreateTags) including a "Name"
tag. If the file system has a "Name" tag, Amazon EFS returns the value
in this field.









=head2 B<REQUIRED> NumberOfMountTargets => Int

  

The current number of mount targets (see CreateMountTarget) the file
system has.









=head2 B<REQUIRED> OwnerId => Str

  

The AWS account that created the file system. If the file system was
created by an IAM user, the parent account to which the user belongs is
the owner.









=head2 B<REQUIRED> SizeInBytes => Paws::EFS::FileSystemSize

  

This object provides the latest known metered size of data stored in
the file system, in bytes, in its C<Value> field, and the time at which
that size was determined in its C<Timestamp> field. The C<Timestamp>
value is the integer number of seconds since 1970-01-01T00:00:00Z. Note
that the value does not represent the size of a consistent snapshot of
the file system, but it is eventually consistent when there are no
writes to the file system. That is, the value will represent actual
size only if the file system is not modified for a period longer than a
couple of hours. Otherwise, the value is not the exact size the file
system was at any instant in time.











=cut

