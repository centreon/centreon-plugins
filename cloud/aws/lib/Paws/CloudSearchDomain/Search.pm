
package Paws::CloudSearchDomain::Search {
  use Moose;
  has cursor => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'cursor' );
  has expr => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'expr' );
  has facet => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'facet' );
  has filterQuery => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'fq' );
  has highlight => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'highlight' );
  has partial => (is => 'ro', isa => 'Bool', traits => ['ParamInQuery'], query_name => 'partial' );
  has query => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'q' , required => 1);
  has queryOptions => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'q.options' );
  has queryParser => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'q.parser' );
  has return => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'return' );
  has size => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'size' );
  has sort => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'sort' );
  has start => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'start' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Search');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-01-01/search?format=sdk&pretty=true');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearchDomain::SearchResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SearchResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearchDomain::Search - Arguments for method Search on Paws::CloudSearchDomain

=head1 DESCRIPTION

This class represents the parameters used for calling the method Search on the 
Amazon CloudSearch Domain service. Use the attributes of this class
as arguments to method Search.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Search.

As an example:

  $service_obj->Search(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cursor => Str

  

Retrieves a cursor value you can use to page through large result sets.
Use the C<size> parameter to control the number of hits to include in
each response. You can specify either the C<cursor> or C<start>
parameter in a request; they are mutually exclusive. To get the first
cursor, set the cursor value to C<initial>. In subsequent requests,
specify the cursor value returned in the hits section of the response.

For more information, see Paginating Results in the I<Amazon
CloudSearch Developer Guide>.










=head2 expr => Str

  

Defines one or more numeric expressions that can be used to sort
results or specify search or filter criteria. You can also specify
expressions as return fields.

You specify the expressions in JSON using the form
C<{"EXPRESSIONNAME":"EXPRESSION"}>. You can define and use multiple
expressions in a search request. For example:

C<{"expression1":"_score*rating", "expression2":"(1/rank)*year"}>

For information about the variables, operators, and functions you can
use in expressions, see Writing Expressions in the I<Amazon CloudSearch
Developer Guide>.










=head2 facet => Str

  

Specifies one or more fields for which to get facet information, and
options that control how the facet information is returned. Each
specified field must be facet-enabled in the domain configuration. The
fields and options are specified in JSON using the form
C<{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}>.

You can specify the following faceting options:

=over

=item *

C<buckets> specifies an array of the facet values or ranges to count.
Ranges are specified using the same syntax that you use to search for a
range of values. For more information, see Searching for a Range of
Values in the I<Amazon CloudSearch Developer Guide>. Buckets are
returned in the order they are specified in the request. The C<sort>
and C<size> options are not valid if you specify C<buckets>.

=item *

C<size> specifies the maximum number of facets to include in the
results. By default, Amazon CloudSearch returns counts for the top 10.
The C<size> parameter is only valid when you specify the C<sort>
option; it cannot be used in conjunction with C<buckets>.

=item *

C<sort> specifies how you want to sort the facets in the results:
C<bucket> or C<count>. Specify C<bucket> to sort alphabetically or
numerically by facet value (in ascending order). Specify C<count> to
sort by the facet counts computed for each facet value (in descending
order). To retrieve facet counts for particular values or ranges of
values, use the C<buckets> option instead of C<sort>.

=back

If no facet options are specified, facet counts are computed for all
field values, the facets are sorted by facet count, and the top 10
facets are returned in the results.

To count particular buckets of values, use the C<buckets> option. For
example, the following request uses the C<buckets> option to calculate
and return facet counts by decade.

C<{"year":{"buckets":["[1970,1979]","[1980,1989]","[1990,1999]","[2000,2009]","[2010,}"]}}>

To sort facets by facet count, use the C<count> option. For example,
the following request sets the C<sort> option to C<count> to sort the
facet values by facet count, with the facet values that have the most
matching documents listed first. Setting the C<size> option to 3
returns only the top three facet values.

C<{"year":{"sort":"count","size":3}}>

To sort the facets by value, use the C<bucket> option. For example, the
following request sets the C<sort> option to C<bucket> to sort the
facet values numerically by year, with earliest year listed first.

C<{"year":{"sort":"bucket"}}>

For more information, see Getting and Using Facet Information in the
I<Amazon CloudSearch Developer Guide>.










=head2 filterQuery => Str

  

Specifies a structured query that filters the results of a search
without affecting how the results are scored and sorted. You use
C<filterQuery> in conjunction with the C<query> parameter to filter the
documents that match the constraints specified in the C<query>
parameter. Specifying a filter controls only which matching documents
are included in the results, it has no effect on how they are scored
and sorted. The C<filterQuery> parameter supports the full structured
query syntax.

For more information about using filters, see Filtering Matching
Documents in the I<Amazon CloudSearch Developer Guide>.










=head2 highlight => Str

  

Retrieves highlights for matches in the specified C<text> or
C<text-array> fields. Each specified field must be highlight enabled in
the domain configuration. The fields and options are specified in JSON
using the form
C<{"FIELD":{"OPTION":VALUE,"OPTION:"STRING"},"FIELD":{"OPTION":VALUE,"OPTION":"STRING"}}>.

You can specify the following highlight options:

=over

=item * C<format>: specifies the format of the data in the text field:
C<text> or C<html>. When data is returned as HTML, all non-alphanumeric
characters are encoded. The default is C<html>.

=item * C<max_phrases>: specifies the maximum number of occurrences of
the search term(s) you want to highlight. By default, the first
occurrence is highlighted.

=item * C<pre_tag>: specifies the string to prepend to an occurrence of
a search term. The default for HTML highlights is C<&lt;em&gt;>. The
default for text highlights is C<*>.

=item * C<post_tag>: specifies the string to append to an occurrence of
a search term. The default for HTML highlights is C<&lt;/em&gt;>. The
default for text highlights is C<*>.

=back

If no highlight options are specified for a field, the returned field
text is treated as HTML and the first match is highlighted with
emphasis tags: C<&lt;emE<gt>search-term&lt;/em&gt;>.

For example, the following request retrieves highlights for the
C<actors> and C<title> fields.

C<{ "actors": {}, "title": {"format": "text","max_phrases":
2,"pre_tag": "B<","post_tag": ">"} }>










=head2 partial => Bool

  

Enables partial results to be returned if one or more index partitions
are unavailable. When your search index is partitioned across multiple
search instances, by default Amazon CloudSearch only returns results if
every partition can be queried. This means that the failure of a single
search instance can result in 5xx (internal server) errors. When you
enable partial results, Amazon CloudSearch returns whatever results are
available and includes the percentage of documents searched in the
search results (percent-searched). This enables you to more gracefully
degrade your users' search experience. For example, rather than
displaying no results, you could display the partial results and a
message indicating that the results might be incomplete due to a
temporary system outage.










=head2 B<REQUIRED> query => Str

  

Specifies the search criteria for the request. How you specify the
search criteria depends on the query parser used for the request and
the parser options specified in the C<queryOptions> parameter. By
default, the C<simple> query parser is used to process requests. To use
the C<structured>, C<lucene>, or C<dismax> query parser, you must also
specify the C<queryParser> parameter.

For more information about specifying search criteria, see Searching
Your Data in the I<Amazon CloudSearch Developer Guide>.










=head2 queryOptions => Str

  

Configures options for the query parser specified in the C<queryParser>
parameter. You specify the options in JSON using the following form
C<{"OPTION1":"VALUE1","OPTION2":VALUE2"..."OPTIONN":"VALUEN"}.>

The options you can configure vary according to which parser you use:

=over

=item * C<defaultOperator>: The default operator used to combine
individual terms in the search string. For example: C<defaultOperator:
'or'>. For the C<dismax> parser, you specify a percentage that
represents the percentage of terms in the search string (rounded down)
that must match, rather than a default operator. A value of C<0%> is
the equivalent to OR, and a value of C<100%> is equivalent to AND. The
percentage must be specified as a value in the range 0-100 followed by
the percent (%) symbol. For example, C<defaultOperator: 50%>. Valid
values: C<and>, C<or>, a percentage in the range 0%-100% (C<dismax>).
Default: C<and> (C<simple>, C<structured>, C<lucene>) or C<100>
(C<dismax>). Valid for: C<simple>, C<structured>, C<lucene>, and
C<dismax>.

=item * C<fields>: An array of the fields to search when no fields are
specified in a search. If no fields are specified in a search and this
option is not specified, all text and text-array fields are searched.
You can specify a weight for each field to control the relative
importance of each field when Amazon CloudSearch calculates relevance
scores. To specify a field weight, append a caret (C<^>) symbol and the
weight to the field name. For example, to boost the importance of the
C<title> field over the C<description> field you could specify:
C<"fields":["title^5","description"]>. Valid values: The name of any
configured field and an optional numeric value greater than zero.
Default: All C<text> and C<text-array> fields. Valid for: C<simple>,
C<structured>, C<lucene>, and C<dismax>.

=item * C<operators>: An array of the operators or special characters
you want to disable for the simple query parser. If you disable the
C<and>, C<or>, or C<not> operators, the corresponding operators (C<+>,
C<|>, C<->) have no special meaning and are dropped from the search
string. Similarly, disabling C<prefix> disables the wildcard operator
(C<*>) and disabling C<phrase> disables the ability to search for
phrases by enclosing phrases in double quotes. Disabling precedence
disables the ability to control order of precedence using parentheses.
Disabling C<near> disables the ability to use the ~ operator to perform
a sloppy phrase search. Disabling the C<fuzzy> operator disables the
ability to use the ~ operator to perform a fuzzy search. C<escape>
disables the ability to use a backslash (C<\>) to escape special
characters within the search string. Disabling whitespace is an
advanced option that prevents the parser from tokenizing on whitespace,
which can be useful for Vietnamese. (It prevents Vietnamese words from
being split incorrectly.) For example, you could disable all operators
other than the phrase operator to support just simple term and phrase
queries: C<"operators":["and","not","or", "prefix"]>. Valid values:
C<and>, C<escape>, C<fuzzy>, C<near>, C<not>, C<or>, C<phrase>,
C<precedence>, C<prefix>, C<whitespace>. Default: All operators and
special characters are enabled. Valid for: C<simple>.

=item * C<phraseFields>: An array of the C<text> or C<text-array>
fields you want to use for phrase searches. When the terms in the
search string appear in close proximity within a field, the field
scores higher. You can specify a weight for each field to boost that
score. The C<phraseSlop> option controls how much the matches can
deviate from the search string and still be boosted. To specify a field
weight, append a caret (C<^>) symbol and the weight to the field name.
For example, to boost phrase matches in the C<title> field over the
C<abstract> field, you could specify: C<"phraseFields":["title^3",
"plot"]> Valid values: The name of any C<text> or C<text-array> field
and an optional numeric value greater than zero. Default: No fields. If
you don't specify any fields with C<phraseFields>, proximity scoring is
disabled even if C<phraseSlop> is specified. Valid for: C<dismax>.

=item * C<phraseSlop>: An integer value that specifies how much matches
can deviate from the search phrase and still be boosted according to
the weights specified in the C<phraseFields> option; for example,
C<phraseSlop: 2>. You must also specify C<phraseFields> to enable
proximity scoring. Valid values: positive integers. Default: 0. Valid
for: C<dismax>.

=item * C<explicitPhraseSlop>: An integer value that specifies how much
a match can deviate from the search phrase when the phrase is enclosed
in double quotes in the search string. (Phrases that exceed this
proximity distance are not considered a match.) For example, to specify
a slop of three for dismax phrase queries, you would specify
C<"explicitPhraseSlop":3>. Valid values: positive integers. Default: 0.
Valid for: C<dismax>.

=item * C<tieBreaker>: When a term in the search string is found in a
document's field, a score is calculated for that field based on how
common the word is in that field compared to other documents. If the
term occurs in multiple fields within a document, by default only the
highest scoring field contributes to the document's overall score. You
can specify a C<tieBreaker> value to enable the matches in
lower-scoring fields to contribute to the document's score. That way,
if two documents have the same max field score for a particular term,
the score for the document that has matches in more fields will be
higher. The formula for calculating the score with a tieBreaker is
C<(max field score) + (tieBreaker) * (sum of the scores for the rest of
the matching fields)>. Set C<tieBreaker> to 0 to disregard all but the
highest scoring field (pure max): C<"tieBreaker":0>. Set to 1 to sum
the scores from all fields (pure sum): C<"tieBreaker":1>. Valid values:
0.0 to 1.0. Default: 0.0. Valid for: C<dismax>.

=back










=head2 queryParser => Str

  

Specifies which query parser to use to process the request. If
C<queryParser> is not specified, Amazon CloudSearch uses the C<simple>
query parser.

Amazon CloudSearch supports four query parsers:

=over

=item * C<simple>: perform simple searches of C<text> and C<text-array>
fields. By default, the C<simple> query parser searches all C<text> and
C<text-array> fields. You can specify which fields to search by with
the C<queryOptions> parameter. If you prefix a search term with a plus
sign (+) documents must contain the term to be considered a match.
(This is the default, unless you configure the default operator with
the C<queryOptions> parameter.) You can use the C<-> (NOT), C<|> (OR),
and C<*> (wildcard) operators to exclude particular terms, find results
that match any of the specified terms, or search for a prefix. To
search for a phrase rather than individual terms, enclose the phrase in
double quotes. For more information, see Searching for Text in the
I<Amazon CloudSearch Developer Guide>.

=item * C<structured>: perform advanced searches by combining multiple
expressions to define the search criteria. You can also search within
particular fields, search for values and ranges of values, and use
advanced options such as term boosting, C<matchall>, and C<near>. For
more information, see Constructing Compound Queries in the I<Amazon
CloudSearch Developer Guide>.

=item * C<lucene>: search using the Apache Lucene query parser syntax.
For more information, see Apache Lucene Query Parser Syntax.

=item * C<dismax>: search using the simplified subset of the Apache
Lucene query parser syntax defined by the DisMax query parser. For more
information, see DisMax Query Parser Syntax.

=back










=head2 return => Str

  

Specifies the field and expression values to include in the response.
Multiple fields or expressions are specified as a comma-separated list.
By default, a search response includes all return enabled fields
(C<_all_fields>). To return only the document IDs for the matching
documents, specify C<_no_fields>. To retrieve the relevance score
calculated for each document, specify C<_score>.










=head2 size => Int

  

Specifies the maximum number of search hits to include in the response.










=head2 sort => Str

  

Specifies the fields or custom expressions to use to sort the search
results. Multiple fields or expressions are specified as a
comma-separated list. You must specify the sort direction (C<asc> or
C<desc>) for each field; for example, C<year desc,title asc>. To use a
field to sort results, the field must be sort-enabled in the domain
configuration. Array type fields cannot be used for sorting. If no
C<sort> parameter is specified, results are sorted by their default
relevance scores in descending order: C<_score desc>. You can also sort
by document ID (C<_id asc>) and version (C<_version desc>).

For more information, see Sorting Results in the I<Amazon CloudSearch
Developer Guide>.










=head2 start => Int

  

Specifies the offset of the first search hit you want to return. Note
that the result set is zero-based; the first result is at index 0. You
can specify either the C<start> or C<cursor> parameter in a request,
they are mutually exclusive.

For more information, see Paginating Results in the I<Amazon
CloudSearch Developer Guide>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Search in L<Paws::CloudSearchDomain>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

