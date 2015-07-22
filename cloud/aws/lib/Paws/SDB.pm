package Paws::SDB {
  use Moose;
  sub service { 'sdb' }
  sub version { '2009-04-15' }
  sub flattened_arrays { 1 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V2Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  has '+region_rules' => (default => sub {
    my $regioninfo;
      $regioninfo = [
    {
      constraints => [
        [
          'region',
          'equals',
          'us-east-1'
        ]
      ],
      uri => 'https://sdb.amazonaws.com'
    }
  ];

    return $regioninfo;
  });

  
  sub BatchDeleteAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::BatchDeleteAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub BatchPutAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::BatchPutAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::CreateDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::DeleteAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::DeleteDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DomainMetadata {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::DomainMetadata', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::GetAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDomains {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::ListDomains', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::PutAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Select {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SDB::Select', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB - Perl Interface to AWS Amazon SimpleDB

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('SDB')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon SimpleDB is a web service providing the core database functions
of data indexing and querying in the cloud. By offloading the time and
effort associated with building and operating a web-scale database,
SimpleDB provides developers the freedom to focus on application
development.

A traditional, clustered relational database requires a sizable upfront
capital outlay, is complex to design, and often requires extensive and
repetitive database administration. Amazon SimpleDB is dramatically
simpler, requiring no schema, automatically indexing your data and
providing a simple API for storage and access. This approach eliminates
the administrative burden of data modeling, index maintenance, and
performance tuning. Developers gain access to this functionality within
Amazon's proven computing environment, are able to scale instantly, and
pay only for what they use.

Visit http://aws.amazon.com/simpledb/ for more information.










=head1 METHODS

=head2 BatchDeleteAttributes(DomainName => Str, Items => ArrayRef[Paws::SDB::DeletableItem])

Each argument is described in detail in: L<Paws::SDB::BatchDeleteAttributes>

Returns: nothing

  

Performs multiple DeleteAttributes operations in a single call, which
reduces round trips and latencies. This enables Amazon SimpleDB to
optimize requests, which generally yields better throughput.

The following limitations are enforced for this operation:

=over

=item * 1 MB request size

=item * 25 item limit per BatchDeleteAttributes operation

=back











=head2 BatchPutAttributes(DomainName => Str, Items => ArrayRef[Paws::SDB::ReplaceableItem])

Each argument is described in detail in: L<Paws::SDB::BatchPutAttributes>

Returns: nothing

  

The C<BatchPutAttributes> operation creates or replaces attributes
within one or more items. By using this operation, the client can
perform multiple PutAttribute operation with a single call. This helps
yield savings in round trips and latencies, enabling Amazon SimpleDB to
optimize requests and generally produce better throughput.

The client may specify the item name with the C<Item.X.ItemName>
parameter. The client may specify new attributes using a combination of
the C<Item.X.Attribute.Y.Name> and C<Item.X.Attribute.Y.Value>
parameters. The client may specify the first attribute for the first
item using the parameters C<Item.0.Attribute.0.Name> and
C<Item.0.Attribute.0.Value>, and for the second attribute for the first
item by the parameters C<Item.0.Attribute.1.Name> and
C<Item.0.Attribute.1.Value>, and so on.

Attributes are uniquely identified within an item by their name/value
combination. For example, a single item can have the attributes C<{
"first_name", "first_value" }> and C<{ "first_name", "second_value" }>.
However, it cannot have two attribute instances where both the
C<Item.X.Attribute.Y.Name> and C<Item.X.Attribute.Y.Value> are the
same.

Optionally, the requester can supply the C<Replace> parameter for each
individual value. Setting this value to C<true> will cause the new
attribute values to replace the existing attribute values. For example,
if an item C<I> has the attributes C<{ 'a', '1' }, { 'b', '2'}> and C<{
'b', '3' }> and the requester does a BatchPutAttributes of C<{'I', 'b',
'4' }> with the Replace parameter set to true, the final attributes of
the item will be C<{ 'a', '1' }> and C<{ 'b', '4' }>, replacing the
previous values of the 'b' attribute with the new value.

This operation is vulnerable to exceeding the maximum URL size when
making a REST request using the HTTP GET method. This operation does
not support conditions using C<Expected.X.Name>, C<Expected.X.Value>,
or C<Expected.X.Exists>.

You can execute multiple C<BatchPutAttributes> operations and other
operations in parallel. However, large numbers of concurrent
C<BatchPutAttributes> calls can result in Service Unavailable (503)
responses.

The following limitations are enforced for this operation:

=over

=item * 256 attribute name-value pairs per item

=item * 1 MB request size

=item * 1 billion attributes per domain

=item * 10 GB of total user data storage per domain

=item * 25 item limit per C<BatchPutAttributes> operation

=back











=head2 CreateDomain(DomainName => Str)

Each argument is described in detail in: L<Paws::SDB::CreateDomain>

Returns: nothing

  

The C<CreateDomain> operation creates a new domain. The domain name
should be unique among the domains associated with the Access Key ID
provided in the request. The C<CreateDomain> operation may take 10 or
more seconds to complete.

The client can create up to 100 domains per account.

If the client requires additional domains, go to
http://aws.amazon.com/contact-us/simpledb-limit-request/.











=head2 DeleteAttributes(DomainName => Str, ItemName => Str, [Attributes => ArrayRef[Paws::SDB::Attribute], Expected => Paws::SDB::UpdateCondition])

Each argument is described in detail in: L<Paws::SDB::DeleteAttributes>

Returns: nothing

  

Deletes one or more attributes associated with an item. If all
attributes of the item are deleted, the item is deleted.

C<DeleteAttributes> is an idempotent operation; running it multiple
times on the same item or attribute does not result in an error
response.

Because Amazon SimpleDB makes multiple copies of item data and uses an
eventual consistency update model, performing a GetAttributes or Select
operation (read) immediately after a C<DeleteAttributes> or
PutAttributes operation (write) might not return updated item data.











=head2 DeleteDomain(DomainName => Str)

Each argument is described in detail in: L<Paws::SDB::DeleteDomain>

Returns: nothing

  

The C<DeleteDomain> operation deletes a domain. Any items (and their
attributes) in the domain are deleted as well. The C<DeleteDomain>
operation might take 10 or more seconds to complete.











=head2 DomainMetadata(DomainName => Str)

Each argument is described in detail in: L<Paws::SDB::DomainMetadata>

Returns: a L<Paws::SDB::DomainMetadataResult> instance

  

Returns information about the domain, including when the domain was
created, the number of items and attributes in the domain, and the size
of the attribute names and values.











=head2 GetAttributes(DomainName => Str, ItemName => Str, [AttributeNames => ArrayRef[Str], ConsistentRead => Bool])

Each argument is described in detail in: L<Paws::SDB::GetAttributes>

Returns: a L<Paws::SDB::GetAttributesResult> instance

  

Returns all of the attributes associated with the specified item.
Optionally, the attributes returned can be limited to one or more
attributes by specifying an attribute name parameter.

If the item does not exist on the replica that was accessed for this
operation, an empty set is returned. The system does not return an
error as it cannot guarantee the item does not exist on other replicas.











=head2 ListDomains([MaxNumberOfDomains => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::SDB::ListDomains>

Returns: a L<Paws::SDB::ListDomainsResult> instance

  

The C<ListDomains> operation lists all domains associated with the
Access Key ID. It returns domain names up to the limit set by
MaxNumberOfDomains. A NextToken is returned if there are more than
C<MaxNumberOfDomains> domains. Calling C<ListDomains> successive times
with the C<NextToken> provided by the operation returns up to
C<MaxNumberOfDomains> more domain names with each successive operation
call.











=head2 PutAttributes(Attributes => ArrayRef[Paws::SDB::ReplaceableAttribute], DomainName => Str, ItemName => Str, [Expected => Paws::SDB::UpdateCondition])

Each argument is described in detail in: L<Paws::SDB::PutAttributes>

Returns: nothing

  

The PutAttributes operation creates or replaces attributes in an item.
The client may specify new attributes using a combination of the
C<Attribute.X.Name> and C<Attribute.X.Value> parameters. The client
specifies the first attribute by the parameters C<Attribute.0.Name> and
C<Attribute.0.Value>, the second attribute by the parameters
C<Attribute.1.Name> and C<Attribute.1.Value>, and so on.

Attributes are uniquely identified in an item by their name/value
combination. For example, a single item can have the attributes C<{
"first_name", "first_value" }> and C<{ "first_name", second_value" }>.
However, it cannot have two attribute instances where both the
C<Attribute.X.Name> and C<Attribute.X.Value> are the same.

Optionally, the requestor can supply the C<Replace> parameter for each
individual attribute. Setting this value to C<true> causes the new
attribute value to replace the existing attribute value(s). For
example, if an item has the attributes C<{ 'a', '1' }>, C<{ 'b', '2'}>
and C<{ 'b', '3' }> and the requestor calls C<PutAttributes> using the
attributes C<{ 'b', '4' }> with the C<Replace> parameter set to true,
the final attributes of the item are changed to C<{ 'a', '1' }> and C<{
'b', '4' }>, which replaces the previous values of the 'b' attribute
with the new value.

You cannot specify an empty string as an attribute name.

Because Amazon SimpleDB makes multiple copies of client data and uses
an eventual consistency update model, an immediate GetAttributes or
Select operation (read) immediately after a PutAttributes or
DeleteAttributes operation (write) might not return the updated data.

The following limitations are enforced for this operation:

=over

=item * 256 total attribute name-value pairs per item

=item * One billion attributes per domain

=item * 10 GB of total user data storage per domain

=back











=head2 Select(SelectExpression => Str, [ConsistentRead => Bool, NextToken => Str])

Each argument is described in detail in: L<Paws::SDB::Select>

Returns: a L<Paws::SDB::SelectResult> instance

  

The C<Select> operation returns a set of attributes for C<ItemNames>
that match the select expression. C<Select> is similar to the standard
SQL SELECT statement.

The total size of the response cannot exceed 1 MB in total size. Amazon
SimpleDB automatically adjusts the number of items returned per page to
enforce this limit. For example, if the client asks to retrieve 2500
items, but each individual item is 10 kB in size, the system returns
100 items and an appropriate C<NextToken> so the client can access the
next page of results.

For information on how to construct select expressions, see Using
Select to Create Amazon SimpleDB Queries in the Developer Guide.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

