# Centren Collection modes
Centreon developed a method to scrap monitoring indicators, and It’s called **Collection**.

This kind of mode is handy if you are in one of the following situations:
* You can't find an existing plugin to monitor what you want or fulfill your particular need.
* You need to gather data from a in-house, black box, or third party application and transform it to be easier to analyze.
* Writing (or asking for) a dedicated plugin appears overkill because you simply want to monitor values and apply thresholds over them.

You can find more information on [The Watch](https://thewatch.centreon.com/data-collection-6/centreon-plugins-discover-collection-modes-131), the Centreon User Community.

Currently, Collection modes are available for:
* SNMP (check the [tutorial](https://thewatch.centreon.com/product-how-to-21/snmp-collection-tutorial-132))
* SQL (check the [tutorial](https://thewatch.centreon.com/product-how-to-21/sql-collection-tutorial-134))

Feel free to share here the file that you have developed.

* SNMP
  * [moxa-iologik-collection.json](snmp/moxa-iologik-collection.json): to monitor the DI channel status (OID [diStatus](http://www.circitor.fr/Mibs/Html/M/MOXA-IO-E2210-MIB.php#DiEntry)  .1.3.6.1.4.1.8691.10.2210.10.1.1.4 of MOXA ioLogik device
