
package Paws::ElastiCache::CopySnapshot {
  use Moose;
  has SourceSnapshotName => (is => 'ro', isa => 'Str', required => 1);
  has TargetSnapshotName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CopySnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CopySnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CopySnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CopySnapshot - Arguments for method CopySnapshot on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method CopySnapshot on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method CopySnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CopySnapshot.

As an example:

  $service_obj->CopySnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> SourceSnapshotName => Str

  

The name of an existing snapshot from which to copy.










=head2 B<REQUIRED> TargetSnapshotName => Str

  

A name for the copied snapshot.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CopySnapshot in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

