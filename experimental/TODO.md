## Remarques diverses

Dans le cas OK, on a deux cas:
* Soit on affiche tout dans l'output
* Soit on met un message generique.

Pour les seuils, les noms doivent pouvoir être définis dans le json.

Il semble intéressant de mettre systématiquement l'agrégation en premier.

le concaténateur de chaîne " - " doit être paramétrable.

# Cas plus général
Généralement on a trois étapes:

1. Collect : je récupère les OIDs
2. Compute : je calcule les valeurs agrégées, ou certaines valeurs particulières
3. evaluation du status : je calcule le status du plugin
4. Je génère la sortie

l'idéal ici serait de séparer ces 4 actions, ceci permettrait que le jour où les plugins http arrivent on peut réutiliser les 3 dernières étapes.

## Métriques SNMP
La collect est faite à partir d'OIDs:
* SnmpGet multiples
* SnmpWalk multiples

Exemples:
* cpu
* mem

## Tables
* Certains OIDs vont remonter des labels
* Certains OIDs remontent les valeurs
* Certains OIDs remontent des seuils (min, max...)

Exemples:
* Disk

## Status
Il peut arriver qu'on traduise des entiers en chaînes de caractères. À définir par nous.
Dans d'autres cas, les valeurs sont déjà des chaînes de caractères.

# Un interpréteur de commandes
On a besoin sûrement d'un interpréteur pour remplacer tous les `eval` du perl. On va essayer de se restreindre à :
* calculs arithmétiques
* calculs booléens

## idée en tout genre
* snmp : est-ce qu'on gère snmpv1 qui n'implémente pas bulkwalk ?
* snmp : est-ce qu'on peux décaler le spécifique snmp pour garder la généricité (pour json plus tard) ?
* filter : est-ce qu'on devrai fusionner les différentes tables renvoyé par snmp pour filtrer plus facilement ?