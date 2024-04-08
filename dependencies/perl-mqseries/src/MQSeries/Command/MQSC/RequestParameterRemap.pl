#
# $Id: RequestParameterRemap.pl,v 33.4 2012/09/26 16:13:36 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%RequestParameterRemap =
  (

   Queue =>
   {
    Key		=> 'QType',
    Values	=> $RequestValues{QType},
   },

  );

1;
