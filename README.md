# Listes scolaires — application mobile (Flutter + Odoo 18)

Application mobile pour traiter les listes scolaires en librairie/papeterie.
**Une seule base de données : ton Odoo 18.** L'app ne stocke rien en local.

Fonctionnel : connexion par employé (compte Odoo), navigation **Ville → École →
Niveau**, **stock réel**, **commandes fournisseurs** avec **validation
responsable** et **traçabilité** native d'Odoo.

## 1. Installer le module Odoo

Le dossier `listes_scolaires_odoo/` est un module Odoo 18 qui crée la structure
Ville → École → Niveau dans ta base.

1. Copier `listes_scolaires_odoo/` dans le dossier addons de ton Odoo.
2. Odoo → Apps → Mettre à jour la liste des applications.
3. Installer **« Listes scolaires »**.
4. Créer quelques Villes / Écoles / Niveaux (menu « Listes scolaires »), et
   ajouter des manuels (produits) à un niveau.
5. Vérifier que les manuels ont un **fournisseur** (onglet Achat du produit) pour
   que les commandes se regroupent automatiquement.
6. Achats → Configuration → activer **les niveaux d'approbation** si tu veux la
   validation par montant.

## 2. Configurer l'app

- `lib/odoo_config.dart` : renseigner `baseUrl` (URL de ton Odoo) et `db`.
- Créer une **clé API** par utilisateur : Odoo → Préférences → Sécurité du compte.

## 3. Lancer

```bash
flutter pub get
flutter run
```

À la connexion : URL, base, identifiant, clé API. Le rôle (employé / responsable)
est déterminé automatiquement : un utilisateur du groupe **Acheteur / Responsable
des achats** voit l'écran de validation, les autres voient le parcours employé.

## Parcours

- **Employé** : Ville → École → Niveau → stock (en stock / insuffisant / à
  commander) → « Préparer la commande » → « Envoyer pour validation ».
  - Niveau absent : « Scanner les ISBN » (recherche produit par code-barres) ou
    « Ajouter par recherche de titre » (listes sans ISBN).
- **Responsable** : liste des commandes, validation / refus, **historique**
  (créée par X, validée par Y) lu depuis Odoo (`create_uid` / `write_uid`).

## Structure de l'app

```
lib/
  main.dart          Routage (connexion / employé / responsable)
  odoo_config.dart   URL + base de ton Odoo
  odoo_service.dart  Connexion JSON-RPC + repository (hiérarchie, stock, commandes)
  app_state.dart     État global (Provider) — tout vient d'Odoo
  models.dart        Modèles
  theme.dart         Thème
  widgets.dart       Widgets partagés
  screens/           auth · browse · kit · create · admin
```

## Étapes suivantes

- **Scan caméra réel** : intégrer `mobile_scanner` (l'écran de scan utilise une
  saisie d'ISBN ; le résultat est cherché dans Odoo par code-barres).
- **Lecture IA des listes papier** : l'extraction des titres depuis une photo se
  fait **côté backend** (ton serveur appelle le modèle de vision, sans clé en
  dur dans l'app), puis l'app cherche les titres dans Odoo. L'écran « par titre »
  est la version manuelle de cette étape.
