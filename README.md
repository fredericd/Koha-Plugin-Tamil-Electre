# Plugin Tamil Electre

Le plugin Koha Tamil Electre permet d'exploiter dans Koha les services web
d'<a href="https://www.electre.com">Electre</a>.  Le plugin affiche à l'OPAC,
sur la page résultat et sur la page de détail, des informations obtenues chez
Electre, image de couverture, quatrième de couverture, etc.

## API Electre NG

Ce plugin utilise [l'API Electre NG](https://docs.electre-ng.com). Plus
précisément, un sous-ensemble de cette API qui s'appelle [Râteau
000](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#electre-api). 
Et plus précisément encore, le service web
[GET-Notices-by-multiple-EAN](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#get-notices-by-multiple-ean).

Ce service web permet d'obtenir les informations Electre relatives à des
ressources identifiées par leur EAN. Ces infos comprennent des images de
couverture, mais aussi des informations descriptives comme la
biographie de l'auteur ou la quatrième de couverture.

**Authentification** — L'accès à l'API Electre NG nécessite un abonnement à ce
service. Un _nom d'utilisateur_ et un _mot de passe_ sont fournis par Electre.
C'est ce qui permmet une authentification de type [OAuth
2.0](https://fr.wikipedia.org/wiki/OAuth) à l'API Electre NG.

**Information** — Les principales informations renvoyées sont les suivantes :

- Les URL de la couverture :
  - imageCouverture
  - imagetteCouverture
- Des informations textuelles :
  - biographie
  - quatriemeDeCouverture
  - tableDesMatieres
  - passagesMedia
  - bandesAnnonces
  - extrait

**Service web du plugin** — Le Plugin Electre expose et utilise un service web
intermédiaire qui présente une version mise en cache sur le serveur Koha des
informations obtenues de l'API Electre NG et construites à partir de celles-ci.

Exemple pour retrouver trois ISBN :

```
/api/v1/contrib/tamelec/notices?isbn=2748905490,9782213726595,9782818621790
```

qui renvoie un hash des ISBN :

```json
{
    "2748905490": {
        "electre": {
            "bandesAnnonces": null,
            "biographie": "<p>Historienne à l'université de Picardie Jules Verne (CAREF), Mélanie Fabre travaille sur l'éducation, les femmes et le genre, ainsi que sur la gauche à l'époque contemporaine.</p>",
            "catalogue": "Livre",
            "dateLiberationEmbargo": null,
            "dateMiseAJour": "2024-03-05 20:00:00.0",
            "desactive": false,
            "eans": [
                "9782748905496"
            ],
            "eansErrones": [],
            "eansJustes": [
                "9782748905496"
            ],
            "eansUtilises": [],
            "extrait": null,
            "imageCouverture": "https://media.electre-ng.com/images/image-id/51f2e9420931d76ea199ea097c30a5ec045d825e688938f42ea12fc8a4b78db7.jpg",
            "imagetteCouverture": "https://media.electre-ng.com/imagettes/image-id/51f2e9420931d76ea199ea097c30a5ec045d825e688938f42ea12fc8a4b78db7.jpg",
            "isbns": [
                "9782748905496"
            ],
            "isbnsErrones": [],
            "isbnsJustes": [
                "978-2-7489-0549-6"
            ],
            "isbnsUtilises": [],
            "legacyNoticeId": "0-10523987",
            "mesChampsExtras": null,
            "noticeId": "609003100194",
            "passagesMedia": null,
            "quatriemeDeCouverture": "<p>« Pour Pauline Kergomard, la crise de l'affaire ...",
            "source": "electre",
            "tableDesMatieres": ""
        },
        "koha": {
            "opac": {
                "info": "<style>\r\n  #electre-toc span {\r\n    margin-left: 4px;\r\n    font-size: 80%;\r\n    font-style: italic;\r\n  }\r\n  #electre-infos h1 {\r\n    font-transform: uppercase;\r\n    color: red;\r\n  }\r\n</style>\r\n<div id=\"electre-infos\">\r\n  \r\n    <div id=\"electre-biography\">\r\n      <h1>Biographies</h1>\r\n      <div><p>Historienne à l'université de Picardie Jules Verne (CAREF), Mélanie Fabre travaille sur l'éducation, les femmes et le genre, ainsi que sur la gauche à l'époque contemporaine.</p></div>\r\n    </div>\r\n  \r\n  \r\n    <div id=\"electre-backcover\">\r\n      <h1>Quatrième de couverture</h1>\r\n      <div><p>« Pour Pauline Kergomard, la crise de l'affaire </p></div>\r\n    </div>\r\n  \r\n  \r\n  \r\n</div>\r\n"
            }
        }
    },
    "9782213726595": {
        "electre": ...
        "koha": ...
    },
    "9782818621790": {
        "electre": ...
        "koha": ...
    }
}
```


## Configuration

Dans les Outils de plugins, vous voyez l'Extension *Tamil Electre*. Cliquez sur
Actions > Configurer.

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

## VERSIONS

* **1.0.1** / novembre 2024 — Version initiale

## LICENCE

This software is copyright (c) 2024 by Tamil s.a.r.l..

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

