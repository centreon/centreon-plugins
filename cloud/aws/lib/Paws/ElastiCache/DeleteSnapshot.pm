
package Paws::ElastiCache::DeleteSnapshot {
  use Moose;
  has SnapshotName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteSnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::DeleteSnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteSnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DeleteSnapshot - Arguments for method DeleteSnapshot on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteSnapshot on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DeleteSnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteSnapshot.

As an example:

  $service_obj->DeleteSnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> SnapshotName => Str

  

The name of the snapshot to be deleted.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteSnapshot in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

