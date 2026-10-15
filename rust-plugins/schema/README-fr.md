# Schéma des collections SNMP Rust

Les fichiers `v<N>/rs-collection.schema.json` décrivent le format des fichiers JSON consommés par le
binaire `centreon-plugin-rust-snmp`, suivant le draft [2020-12](https://json-schema.org/draft/2020-12/schema).
C'est le format auquel les collections présentes dans [`../rs-collections/`](../rs-collections/)
doivent se conformer. La CI valide chaque collection contre la version qu'elle déclare.

## Un répertoire par version de format

```
schema/
  v0/rs-collection.schema.json   le format beta, celui utilisé aujourd'hui
```

À chaque version de format correspond un répertoire. Il est créé une fois, et ne reçoit ensuite que des
corrections rédactionnelles : descriptions, exemples, un `pattern` qui refusait une valeur
légitime. Un changement qui modifie le contrat doit être opéré dans une nouvelle version, de sorte que :

- une collection écrite pour un format n continue d'être validée par le fichier pour lequel
  elle a été écrite ;
- le format n+1 peut être travaillé, relu et fusionné pendant que le format n reste
  intact ;
- l'URL publiée d'une version est son répertoire, l'arborescence du dépôt ne peut donc pas diverger
  de ce que le site sert. Le build refuse un répertoire dont le `$id` du schéma désigne une autre
  version.

Le site publié porte toutes les versions présentes ici. Rien n'est à renommer, déplacer ou geler
quand une nouvelle apparaît : ajouter le répertoire suffit.

## Version du format

Une collection déclare la version du format, utilisée par le plugin pour s'assurer que cette collection est bien adaptée
à sa propre version, via la clé obligatoire `format_version` :

```json
{
  "format_version": 0,
  "collect": { "...": "..." }
}
```

Le plugin refuse explicitement une collection dont il ne sait pas traiter la version, plutôt que
d'échouer plus loin sur une clé qui a bougé ou disparu.

Cette version est indépendante de celle du paquet, qui suit le calendrier de livraison Centreon et
ne dit rien de la compatibilité. Seul un changement cassant les collections existantes l'incrémente :

| Changement                                                                                                          | Effet sur les collections existantes                                                       | Version du format  |
|---------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|--------------------|
| Retirer ou renommer une clé, rendre une clé optionnelle obligatoire, restreindre un enum, changer le sens d'une clé | elles cassent                                                                              | nouveau répertoire |
| Ajouter une clé optionnelle, ajouter une valeur d'enum                                                              | elles continuent de fonctionner, mais une nouvelle collection exige un plugin assez récent | inchangée          |
| Documentation, exemples                                                                                             | aucun                                                                                      | inchangée          |

**La version 0 est le format beta et n'offre aucune garantie de stabilité** : elle peut casser
jusqu'à la première version stable, qui portera le numéro 1.

## Pointer un éditeur vers le schéma

Une collection déclare le schéma qu'elle suit via une clé `$schema`, que les éditeurs comme PyCharm
ou VS Code exploitent pour la complétion, la documentation en ligne et la validation au fil de la
saisie :

```json
{
  "$schema": "https://centreon.github.io/centreon-plugins/rs-collections/snmp/v0/rs-collection.schema.json",
  "format_version": 0,
  "collect": { "...": "..." }
}
```

La CI contrôle que les deux clés concordent : le `$schema` d'une collection doit être le `$id` du
schéma que désigne son `format_version`. Ni ce contrôle ni le `$id` du schéma ne réécrivent l'URL
une seconde fois.

Cette clé est une convention comprise par les IDE, qui afficheront automatiquement des erreurs et des warnings si le
format d'une collection n'est pas conforme au schéma. Les validateurs comme `check-jsonschema` l'ignorent, et exigent
que le schéma soit passé (par exemple via l'option `--schemafile`).

## Validation d'une collection

Valider une collection JSON nécessite `jq` et `check-jsonschema` (`pip install check-jsonschema`).

Pour valider les collections supportées par Centreon, chacune en fonction de la version de format qu'elle
déclare dans `$schema` :

```bash
.github/scripts/validate-rs-collections.sh [file1] [file2] [...]
```

Des chemins de fichiers en arguments restreignent le contrôle à ceux-ci. Au-delà de la validation
par le schéma, le script signale une collection sans `format_version`, une collection déclarant une
version que le dépôt ne connaît pas, et une collection dont la clé `$schema` désigne une autre
version que son `format_version`.

C'est le script même que jouent le hook `pre-commit` et la CI : un commit ne peut donc pas passer un
contrôle que la pipeline refusera. Sans `check-jsonschema`, il avertit et effectue malgré tout les
contrôles ne nécessitant que `jq`, sauf sous GitHub Actions où son absence est une erreur.

Pour contrôler la validité d'un schéma lui-même plutôt qu'une collection :

```bash
check-jsonschema --check-metaschema rust-plugins/schema/v0/rs-collection.schema.json
```

Les deux commandes se lancent depuis la racine du dépôt.

## Génération du site statique

Le format de ce fichier n'étant pas fait pour être lu par une personne humaine, la manière la plus
facile de le parcourir est de générer sa représentation en HTML/JS/CSS.

Pour cela, il faut d'abord installer `json-schema-for-humans` (`pip install json-schema-for-humans`)
et `jq`, puis lancer :

```bash
.github/scripts/build-schema-doc.sh rust-plugins/schema site
```

Le script génère le rendu de chaque version présente dans le répertoire des schémas et écrit un site
autonome dans `site/`. Ouvrir `site/index.html` dans un navigateur suffit à le consulter.

Un troisième argument optionnel ajoute une bannière en haut de chaque page, ce dont la CI se sert
pour marquer les rendus de pull request.

## Consultation de la page générée

La CI du projet régénère et publie le site sur GitHub Pages :

<https://centreon.github.io/centreon-plugins/>

**Pendant la durée de vie de la PR**, il n'y a pas d'URL. Pour relire le rendu malgré tout :

1. poser le label `upload-artifacts` sur la PR
2. pousser un commit, au besoin vide, pour qu'un run démarre avec le label posé
3. télécharger l'artefact `schema-reference-preview` en bas de la page du run, le décompresser et
   ouvrir `index.html` dans votre navigateur
