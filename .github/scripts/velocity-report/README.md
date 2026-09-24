# Rapport de vélocité des équipes

Script qui mesure l'activité de génération de code d'un dépôt GitHub : ce qui est
livré sur les branches d'intégration (`develop`, `master`…), mais aussi le travail
présent sur **toutes les autres branches**, qu'elles aient une PR ou non. Les
contributeurs sont séparés en **internes**, **externes**, **bots** et **agents IA**.

Le script produit :

- `velocity-report.json` : toutes les données calculées (réutilisables dans un autre outil) ;
- `velocity-report.html` : un rapport autonome (graphiques, tableaux triables, thème clair/sombre).

Seule la bibliothèque standard Python 3.8+ est nécessaire.

## Utilisation

```bash
# clone complet de toutes les branches (le script peut aussi le faire avec --fetch)
git fetch --unshallow origin '+refs/heads/*:refs/remotes/origin/*'

GITHUB_TOKEN=ghp_xxx python3 .github/scripts/velocity-report/velocity_report.py \
    --repo-path . \
    --github-repo centreon/centreon-plugins \
    --since 2025-09-01 \
    --out-dir /tmp/velocity \
    --cache-dir /tmp/velocity/cache
```

| Option | Rôle |
|---|---|
| `--since` / `--until` | Période analysée (par défaut : les 12 derniers mois). |
| `--github-repo` | `owner/nom` ; active les métriques de PR (sans elle : git seul). |
| `--integration-branches` | Branches considérées comme « livrées » (défaut : HEAD distant + `develop`/`main`/`master`). |
| `--config` | Fichier JSON de configuration (voir `config.example.json`). |
| `--cache-dir` | Cache des reviews des PR fermées pour accélérer les relances. |
| `--no-reviews` | Ne pas appeler l'API des reviews (un appel par PR). |
| `--no-github` | Git uniquement. |
| `--fetch` | Récupère l'historique complet de toutes les branches avant l'analyse. |

Le jeton GitHub (`GITHUB_TOKEN` ou `GH_TOKEN`) n'a besoin que d'un accès en lecture au dépôt.
Sur une année de `centreon-plugins`, le script fait environ 650 appels API et tourne en moins d'une minute.

## Ce qui est mesuré

**Livraison (branches d'intégration)**
- PR mergées par semaine et par catégorie d'auteur, taille des PR ;
- lead time (ouverture → merge), délai avant la première review par une autre personne ;
- lignes livrées (ajouts + suppressions), par zone du dépôt et par domaine de plugins.

**Travail hors intégration (toutes les autres branches)**
- commits présents uniquement sur des branches non intégrées ;
- statut de chaque branche : PR ouverte, brouillon, fermée sans merge, sans PR (active ou dormante), déjà intégrée ;
- avance / retard de chaque branche par rapport à `develop`.

**Interne / externe**
- une personne est interne si elle a utilisé une adresse `@centreon.com` pendant la période,
  ou si GitHub la déclare membre de l'organisation ; sinon elle est externe
  (un ancien salarié qui contribue avec une adresse personnelle est donc externe) ;
- les PR externes sont souvent fermées puis reprises dans une PR interne qui crédite
  l'auteur avec un trailer `Co-authored-by`. Le script les détecte et les classe
  « intégrées via PR interne », ce qui donne un vrai taux d'intégration des contributions
  externes (le taux de merge brut serait proche de zéro) ;
- délai d'intégration et de première review des PR externes, liste des PR externes en attente.

**Assistance IA** : PR et commits portant un marqueur explicite (Claude, Copilot…).
C'est un minimum : le code généré sans marqueur n'est pas détectable.

## Configuration

Copier `config.example.json` et l'adapter :

- `internal` / `external` : forcer la catégorie d'une personne (login, e-mail ou nom) ;
- `aliases` : fusionner plusieurs identités d'une même personne
  (`login:xxx`, `email:xxx`, `name:xxx`) ;
- `teams` : rattacher les personnes à des équipes, ce qui ajoute un tableau par équipe ;
- `exclude_paths`, `areas`, `non_code_areas` : fichiers ignorés (générés, lockfiles),
  découpage du dépôt en zones, zones exclues des « lignes de code » (fixtures de test) ;
- `stale_days` : seuil au-delà duquel une branche sans PR est dite dormante.

Les identités sont rapprochées automatiquement (même e-mail, même nom normalisé,
e-mail `noreply` GitHub, auteur du squash commit d'une PR). Les cas ambigus se
corrigent avec `aliases`.

## Limites

- Ces indicateurs mesurent un flux d'activité, pas la valeur livrée. Ils servent à
  repérer des goulets (reviews lentes, PR externes en attente, branches dormantes),
  pas à classer des personnes.
- Les branches supprimées après merge ne sont plus visibles : leur travail n'apparaît
  qu'à travers le squash commit de la PR.
- Les PR venant de forks n'ont pas de branche dans le dépôt : elles ne sont vues que via l'API.
