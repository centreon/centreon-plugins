# Documentation du script check_microsens_G7

## Description (FR)
Ce script permet de superviser les équipements **Microsens G7** via SNMP.  
Il est compatible avec SNMP v2c et v3, et fournit différents modes de vérification.

### Modes disponibles
- **uptime** : Affiche la durée depuis le dernier redémarrage du switch.
- **temperature** : Retourne la température système et applique des seuils (warning/critical).
- **ports** : Vérifie l’état des ports (link up/down, forwarding, blocking, etc.).
- **poe** : Vérifie la consommation PoE totale et par port.
- **g8032** : Vérifie l’état du Ring G.8032 (redondance).
- **firmware** : Retourne la version du firmware.
- **system** : Retourne les infos système (hostname, serial, MAC, CPU, mémoire, température).
- **config** : Vérifie la configuration (DNS, NTP, TACACS, mode d’authentification).

### Exemples de commandes (FR)
- Vérifier l’uptime en SNMP v2c :  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m uptime
  ```

- Vérifier la température avec seuils :  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m temperature -w 60 -c 75
  ```

- Vérifier les ports en SNMP v3 :  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -v3 -u snmp --authproto MD5 --authpass "password" -m ports
  ```

- Vérifier la configuration (DNS/NTP/TACACS) :  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m config
  ```


---

## Description (EN)
This script allows monitoring of **Microsens G7** devices via SNMP.  
It supports SNMP v2c and v3, and provides different verification modes.

### Available modes
- **uptime**: Displays the time since the last reboot of the switch.
- **temperature**: Returns the system temperature and applies thresholds (warning/critical).
- **ports**: Checks the status of the ports (link up/down, forwarding, blocking, etc.).
- **poe**: Checks the total and per-port PoE consumption.
- **g8032**: Checks the G.8032 Ring state (redundancy).
- **firmware**: Returns the firmware version.
- **system**: Returns system info (hostname, serial, MAC, CPU, memory, temperature).
- **config**: Verifies configuration (DNS, NTP, TACACS, authentication mode).

### Command examples (EN)
- Check uptime with SNMP v2c:  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m uptime
  ```

- Check temperature with thresholds:  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m temperature -w 60 -c 75
  ```

- Check ports with SNMP v3:  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -v3 -u snmp --authproto MD5 --authpass "password" -m ports
  ```

- Check configuration (DNS/NTP/TACACS):  
  ```bash
  ./check_microsens_G7.pl -H 192.168.1.10 -C public -v 2c -m config
  ```
