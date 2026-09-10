# Schéma des collections SNMP Rust

Le fichier `rs-collection.schema.json` décrit le format des fichiers JSON consommés par le binaire
`centreon-plugin-rust-snmp` en suivant le draft [2020-12](https://json-schema.org/draft/2020-12/schema). 
C'est ce format que doivent respecter les collections que l'on trouve dans [`../rs-collections/`](../rs-collections/).
La CI validera chaque collection par rapport à ce fichier de référence.

## Générer le site statique

Le format de ce fichier n'était pas fait pour être lu par une personne humaine, la manière la plus facile de le parcourir est de générer sa représentation en HTML/JS/CSS.

Pour cela, il faut d'abord installer `json-schema-for-humans` (`pip install json-schema-for-humans`) puis lancer :

```bash
.github/scripts/build-schema-doc.sh rust-plugins/schema/rs-collection.schema.json site
```

Le script écrit un site autonome dans `site/`. Ouvrir `site/rs-collections/snmp/index.html` dans un navigateur suffit à le consulter.

Un troisième argument optionnel ajoute un bandeau en tête de chaque page, ce dont la CI se sert pour marquer les rendus de pull request.

## Valider une collection

Pour valider une collection JSON, il faut avoir installé `check-jsonschema` (`pip install check-jsonschema`).  

Ici pour valider l'ensemble des collections supportées par Centreon :

```bash
check-jsonschema --schemafile rust-plugins/schema/rs-collection.schema.json rust-plugins/rs-collections/*/*.json
```

Pour contrôler la validité du schéma lui-même plutôt qu'une collection :

```bash
check-jsonschema --check-metaschema rs-collection.schema.json
```

Ce contrôle, ainsi que celui de toutes les collections sont joués par le hook `pre-commit` du dépôt puis par la CI.

## Consultation de la page générée

La CI du projet régénère et publie le site sur GitHub Pages :

<https://centreon.github.io/centreon-plugins/rs-collections/snmp/>

**Pendant la durée de vie de la PR**, il n'y a pas d'URL, pour relire le rendu malgré tout :

1. poser le label `upload-artifacts` sur la PR
2. relancer le workflow `rs-collection-schema`
3. télécharger l'artefact `schema-reference-preview` en bas de la page du run, le décompresser et ouvrir `index.html` dans votre navigateur
