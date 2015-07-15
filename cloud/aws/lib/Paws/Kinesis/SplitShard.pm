
package Paws::Kinesis::SplitShard {
  use Moose;
  has NewStartingHashKey => (is => 'ro', isa => 'Str', required => 1);
  has ShardToSplit => (is => 'ro', isa => 'Str', required => 1);
  has StreamName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SplitShard');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::SplitShard - Arguments for method SplitShard on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method SplitShard on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method SplitShard.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SplitShard.

As an example:

  $service_obj->SplitShard(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> NewStartingHashKey => Str

  

A hash key value for the starting hash key of one of the child shards
created by the split. The hash key range for a given shard constitutes
a set of ordered contiguous positive integers. The value for
C<NewStartingHashKey> must be in the range of hash keys being mapped
into the shard. The C<NewStartingHashKey> hash key value and all higher
hash key values in hash key range are distributed to one of the child
shards. All the lower hash key values in the range are distributed to
the other child shard.










=head2 B<REQUIRED> ShardToSplit => Str

  

The shard ID of the shard to split.










=head2 B<REQUIRED> StreamName => Str

  

The name of the stream for the shard split.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SplitShard in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

