# Community contributors

## Description

Please include a short resume of the changes and what is the purpose of this pull request. 
Any relevant information should be added to help **reviewers** to understand what are the stakes 
of the pull request.

**Fixes** # (issue)
If you are fixing a github Issue already existing, mention it here.

## Type of change

- [ ] Patch fixing an issue (non-breaking change)
- [ ] New functionality (non-breaking change)
- [ ] Functionality enhancement or optimization (non-breaking change)
- [ ] Breaking change (patch or feature) that might cause side effects breaking part of the Software

## How this pull request can be tested ?

Please describe the **procedure** to verify that the goal of the PR is matched. 
Provide clear instructions so that it can be **correctly tested**.

Any **relevant details** of the configuration to perform the test should be added.
To integrate this pull request into our core we need to add some **automated tests** to check the proper 
functioning of this PR. Ideally we need the following informations:
* **SNMP**: MIB files and full snmpwalk of enterprise branch (`snmpwalk -ObentU -v 2c -c public address .1.3.6.1.4.1 > equipment.snmpwalk`) or [SNMP collections](https://thewatch.centreon.com/product-how-to-21/snmp-collection-tutorial-132).
* **HTTP API (SOAP, Rest/Json, XML-RPC)**: the documentation and some curl examples (command with -v + output) or HTTP [collections](https://thewatch.centreon.com/data-collection-6/centreon-plugins-discover-collection-modes-131).
* **CLI**: command line examples (command + result).
* **SQL**: queries + results + column types or [SQL collections](https://thewatch.centreon.com/product-how-to-21/sql-collection-tutorial-134).
* **JMX**: mbean names and attributes.

If some information is confidential, such as logins or IP addresses, obfuscate them in what is sent 
publicly and we'll get in touch with you by private message if this information is needed.

## Checklist

- [ ] I have followed the **[coding style guidelines](https://github.com/centreon/centreon-plugins/blob/develop/doc/en/developer/plugins_global.md#5-code-style-guidelines)** provided by Centreon
- [ ] I have commented my code, especially **hard-to-understand areas** of the PR.
- [ ] I have **rebased** my development branch on the base branch (develop).
- [ ] I have provide data or shown output displaying the result of this code in the plugin area concerned.

------------------------------------------------------------------------------------------------------
# Centreon team

## Description

**PLEASE MAKE SURE THAT THE BRANCH PR INCLUDES JIRA TICKET ID**

Please include a short resume of the changes and what is the purpose of this pull request. 
Any relevant information should be added to help **reviewers** to understand what are the stakes 
of the pull request.

**Fixes** # (issue)
If you are fixing a github Issue already existing, mention it here.
If you are fixing one or more JIRA ticket, mention it here too.

## Type of change

- [ ] Patch fixing an issue (non-breaking change)
- [ ] New functionality (non-breaking change)
- [ ] Functionality enhancement or optimization (non-breaking change)
- [ ] Breaking change (patch or feature) that might cause side effects breaking part of the Software

## How this pull request can be tested ?

Please describe the **procedure** to verify that the goal of the PR is matched. 
Provide clear instructions so that it can be **correctly tested**.
Mention the automated tests included in this FOR (what they test like mode/option combinations).

## Checklist

- [ ] I have followed the **[coding style guidelines](https://github.com/centreon/centreon-plugins/blob/develop/doc/en/developer/plugins_global.md#5-code-style-guidelines)** provided by Centreon
- [ ] I have commented my code, especially **hard-to-understand areas** of the PR.
- [ ] I have **rebased** my development branch on the base branch (develop).
- [ ] I have implemented automated tests related to my commits.
- [ ] I have reviewed all the help messages in all the .pm files I have modified.
  - [ ] All sentences begin with a capital letter.
  - [ ] All sentences are terminated by a period.
  - [ ] I am able to understand all the help messages, if not, exchange with the PO or TW to rewrite them.