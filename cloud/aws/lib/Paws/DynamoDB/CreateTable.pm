
package Paws::DynamoDB::CreateTable {
  use Moose;
  has AttributeDefinitions => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeDefinition]', required => 1);
  has GlobalSecondaryIndexes => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::GlobalSecondaryIndex]');
  has KeySchema => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::KeySchemaElement]', required => 1);
  has LocalSecondaryIndexes => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::LocalSecondaryIndex]');
  has ProvisionedThroughput => (is => 'ro', isa => 'Paws::DynamoDB::ProvisionedThroughput', required => 1);
  has TableName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateTable');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::CreateTableOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::CreateTable - Arguments for method CreateTable on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateTable on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method CreateTable.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateTable.

As an example:

  $service_obj->CreateTable(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AttributeDefinitions => ArrayRef[Paws::DynamoDB::AttributeDefinition]

  

An array of attributes that describe the key schema for the table and
indexes.










=head2 GlobalSecondaryIndexes => ArrayRef[Paws::DynamoDB::GlobalSecondaryIndex]

  

One or more global secondary indexes (the maximum is five) to be
created on the table. Each global secondary index in the array includes
the following:

=over

=item *

I<IndexName> - The name of the global secondary index. Must be unique
only for this table.

=item *

I<KeySchema> - Specifies the key schema for the global secondary index.

=item *

I<Projection> - Specifies attributes that are copied (projected) from
the table into the index. These are in addition to the primary key
attributes and index key attributes, which are automatically projected.
Each attribute specification is composed of:

=over

=item *

I<ProjectionType> - One of the following:

=over

=item *

C<KEYS_ONLY> - Only the index and primary keys are projected into the
index.

=item *

C<INCLUDE> - Only the specified table attributes are projected into the
index. The list of projected attributes are in I<NonKeyAttributes>.

=item *

C<ALL> - All of the table attributes are projected into the index.

=back

=item *

I<NonKeyAttributes> - A list of one or more non-key attribute names
that are projected into the secondary index. The total count of
attributes provided in I<NonKeyAttributes>, summed across all of the
secondary indexes, must not exceed 20. If you project the same
attribute into two different indexes, this counts as two distinct
attributes when determining the total.

=back

=item *

I<ProvisionedThroughput> - The provisioned throughput settings for the
global secondary index, consisting of read and write capacity units.

=back










=head2 B<REQUIRED> KeySchema => ArrayRef[Paws::DynamoDB::KeySchemaElement]

  

Specifies the attributes that make up the primary key for a table or an
index. The attributes in I<KeySchema> must also be defined in the
I<AttributeDefinitions> array. For more information, see Data Model in
the I<Amazon DynamoDB Developer Guide>.

Each I<KeySchemaElement> in the array is composed of:

=over

=item *

I<AttributeName> - The name of this key attribute.

=item *

I<KeyType> - Determines whether the key attribute is C<HASH> or
C<RANGE>.

=back

For a primary key that consists of a hash attribute, you must provide
exactly one element with a I<KeyType> of C<HASH>.

For a primary key that consists of hash and range attributes, you must
provide exactly two elements, in this order: The first element must
have a I<KeyType> of C<HASH>, and the second element must have a
I<KeyType> of C<RANGE>.

For more information, see Specifying the Primary Key in the I<Amazon
DynamoDB Developer Guide>.










=head2 LocalSecondaryIndexes => ArrayRef[Paws::DynamoDB::LocalSecondaryIndex]

  

One or more local secondary indexes (the maximum is five) to be created
on the table. Each index is scoped to a given hash key value. There is
a 10 GB size limit per hash key; otherwise, the size of a local
secondary index is unconstrained.

Each local secondary index in the array includes the following:

=over

=item *

I<IndexName> - The name of the local secondary index. Must be unique
only for this table.

=item *

I<KeySchema> - Specifies the key schema for the local secondary index.
The key schema must begin with the same hash key attribute as the
table.

=item *

I<Projection> - Specifies attributes that are copied (projected) from
the table into the index. These are in addition to the primary key
attributes and index key attributes, which are automatically projected.
Each attribute specification is composed of:

=over

=item *

I<ProjectionType> - One of the following:

=over

=item *

C<KEYS_ONLY> - Only the index and primary keys are projected into the
index.

=item *

C<INCLUDE> - Only the specified table attributes are projected into the
index. The list of projected attributes are in I<NonKeyAttributes>.

=item *

C<ALL> - All of the table attributes are projected into the index.

=back

=item *

I<NonKeyAttributes> - A list of one or more non-key attribute names
that are projected into the secondary index. The total count of
attributes provided in I<NonKeyAttributes>, summed across all of the
secondary indexes, must not exceed 20. If you project the same
attribute into two different indexes, this counts as two distinct
attributes when determining the total.

=back

=back










=head2 B<REQUIRED> ProvisionedThroughput => Paws::DynamoDB::ProvisionedThroughput

  

=head2 B<REQUIRED> TableName => Str

  

The name of the table to create.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateTable in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

