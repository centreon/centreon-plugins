#
# $Id: Request.pm,v 33.11 2012/09/26 16:15:09 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::Request;

use 5.008;

use strict;
use Carp;

use MQSeries::Command::Base;
use MQSeries::Message;

our @ISA = qw(MQSeries::Command::Base MQSeries::Message);
our $VERSION = '1.34';

1;


