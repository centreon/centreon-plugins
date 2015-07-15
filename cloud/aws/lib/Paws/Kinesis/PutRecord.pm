
package Paws::Kinesis::PutRecord {
  use Moose;
  has Data => (is => 'ro', isa => 'Str', required => 1);
  has ExplicitHashKey => (is => 'ro', isa => 'Str');
  has PartitionKey => (is => 'ro', isa => 'Str', required => 1);
  has SequenceNumberForOrdering => (is => 'ro', isa => 'Str');
  has StreamName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutRecord');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Kinesis::PutRecordOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::PutRecord - Arguments for method PutRecord on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutRecord on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method PutRecord.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutRecord.

As an example:

  $service_obj->PutRecord(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Data => Str

  

The data blob to put into the record, which is base64-encoded when the
blob is serialized. The maximum size of the data blob (the payload
before base64-encoding) is 50 kilobytes (KB)










=head2 ExplicitHashKey => Str

  

The hash value used to explicitly determine the shard the data record
is assigned to by overriding the partition key hash.










=head2 B<REQUIRED> PartitionKey => Str

  

Determines which shard in the stream the data record is assigned to.
Partition keys are Unicode strings with a maximum length limit of 256
characters for each key. Amazon Kinesis uses the partition key as input
to a hash function that maps the partition key and associated data to a
specific shard. Specifically, an MD5 hash function is used to map
partition keys to 128-bit integer values and to map associated data
records to shards. As a result of this hashing mechanism, all data
records with the same partition key will map to the same shard within
the stream.










=head2 SequenceNumberForOrdering => Str

  

Guarantees strictly increasing sequence numbers, for puts from the same
client and to the same partition key. Usage: set the
C<SequenceNumberForOrdering> of record I<n> to the sequence number of
record I<n-1> (as returned in the result when putting record I<n-1>).
If this parameter is not set, records will be coarsely ordered based on
arrival time.










=head2 B<REQUIRED> StreamName => Str

  

The name of the stream to put the data record into.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutRecord in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

