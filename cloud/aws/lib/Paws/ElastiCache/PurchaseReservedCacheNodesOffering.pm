
package Paws::ElastiCache::PurchaseReservedCacheNodesOffering {
  use Moose;
  has CacheNodeCount => (is => 'ro', isa => 'Int');
  has ReservedCacheNodeId => (is => 'ro', isa => 'Str');
  has ReservedCacheNodesOfferingId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PurchaseReservedCacheNodesOffering');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::PurchaseReservedCacheNodesOfferingResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'PurchaseReservedCacheNodesOfferingResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::PurchaseReservedCacheNodesOffering - Arguments for method PurchaseReservedCacheNodesOffering on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method PurchaseReservedCacheNodesOffering on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method PurchaseReservedCacheNodesOffering.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PurchaseReservedCacheNodesOffering.

As an example:

  $service_obj->PurchaseReservedCacheNodesOffering(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheNodeCount => Int

  

The number of cache node instances to reserve.

Default: C<1>










=head2 ReservedCacheNodeId => Str

  

A customer-specified identifier to track this reservation.

Example: myreservationID










=head2 B<REQUIRED> ReservedCacheNodesOfferingId => Str

  

The ID of the reserved cache node offering to purchase.

Example: 438012d3-4052-4cc7-b2e3-8d3372e0e706












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PurchaseReservedCacheNodesOffering in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

