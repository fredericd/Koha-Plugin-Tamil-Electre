# Plugin Tamil Electre

Le plugin Koha Tamil Electre permet d'exploiter dans Koha les services web
d'<a href="https://www.electre.com">Electre</a>.

## Installation

**Activation des plugins** — Si ce n'est pas déjà fait, dans Koha, activez les
plugins. Demandez à votre prestataire Koha de le faire, ou bien vérifiez les
points suivants :

- Dans `koha-conf.xml`, activez les plugins.
- Dans le fichier de configuration d'Apache, définissez l'alias `/plugins`.
  Faites en sorte que le répertoire pointé ait les droits nécessaires.

**📁 TÉLÉCHARGEMENT** — Récupérez sur le site [Tamil](https://www.tamil.fr)
l'archive de l'Extension **[Tamil
Electre](https://www.tamil.fr/download/koha-plugin-tamil-electre-1.0.1.kpz)**.

Dans l'interface pro de Koha, allez dans `Outils > Outils de Plugins`. Cliquez
sur Télécharger un plugin. Choisissez l'archive **téléchargée** à l'étape
précédente. Cliquez sur Télécharger.

## Utilisation du plugin

### Synopsis

Le plugin affiche à l'OPAC, sur la page résultat et détail, des informations
obtenues chez Electre.

### API Electre NG

Ce plugin utilise [l'API Electre NG](https://docs.electre-ng.com). Plus
précisément, un sous-ensemble de cette API qui s'appelle [Rateau
000](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#electre-api). 
Et plus précisément encore, le service web
[GET-Notices-by-multiple-EAN](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#get-notices-by-multiple-ean).

Ce service web permet d'obtenir les informations Electre relatives à des
ressources identifiées par leur EAN. Ces infos comprennent des images de
couverture, mais aussi des informations descriptives comme la
biographie de l'auteur ou la quatrième de couverture.

**Authentification** — L'accès à l'API Electre NG nécessite un abonnement à ce
service. Un _nom d'utilisateur_ et un _mot de passe_ est fourni par Electre.

**Information** — Les principales informations renvoyées sont les suivantes :

- imageCouverture
- imagetteCouverture
- biographie
- quatriemeDeCouverture
- tableDesMatieres
- passagesMedia
- bandesAnnonces
- extrait


### Configuration

Dans les Outils de plugins, vous voyez l'Extension *Tamil Electre*. Cliquez sur
Actions > Configurer.

## VERSIONS

* **1.0.1** / novembre 2024 — Version initiale

## LICENCE

This software is copyright (c) 2024 by Tamil s.a.r.l..

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

