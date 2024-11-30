# Plugin Tamil Electre

Le plugin Koha **_Tamil Electre_** permet d'exploiter dans Koha les services
web de <a href="https://www.electre.com">Electre</a>.  Le plugin affiche à
l'OPAC, sur la page résultat et sur la page de détail, des informations
obtenues chez Electre, image de couverture, quatrième de couverture, etc.

## API Electre NG

Ce plugin utilise [l'API Electre NG](https://docs.electre-ng.com). Plus
précisément, un sous-ensemble de cette API qui s'appelle [Râteau
000](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#electre-api). 
Et plus précisément encore, le service web
[GET-Notices-by-multiple-EAN](https://docs.electre-ng.com/1.19.0/electre-API-rateau-00-v1.19.0.html#get-notices-by-multiple-ean).

Ce service web exploite les informations Electre relatives à des ressources
identifiées par leur EAN. Ces infos comprennent des images de couverture, mais
aussi des informations descriptives comme la biographie de l'auteur ou la
quatrième de couverture.

**Authentification** — L'accès à l'API Electre NG nécessite un abonnement à ce
service. Un _nom d'utilisateur_ et un _mot de passe_ sont fournis par Electre.
C'est ce qui permet une authentification de type [OAuth
2.0](https://fr.wikipedia.org/wiki/OAuth) à l'API Electre NG.

**Informations** — Les principales informations renvoyées sont les suivantes :

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

**Service web du plugin** — Le Plugin **_Tamil Electre_** expose et utilise un
service web intermédiaire qui présente une version mise en cache sur le serveur
Koha des informations obtenues de l'API Electre NG et construites à partir de
celles-ci. Ce service web intermédiaire a aussi pour fonction de transformer
les éventuels ISBN-10 en ISBN-13 avant d'interroger l'API Electre NG qui
accepte uniquement des EAN (= ISBN-13).

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
            "biographie": "<p>Historienne à l'université de Picardie Jules...",
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
            "imageCouverture": "https://media.electre-ng.com/images/image-id/a4b78db7.jpg",
            "imagetteCouverture": "https://media.electre-ng.com/imagettes/image-id/fc8a4b78db7.jpg",
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
                "info": "<style>\r\n  #electre-toc span {\r\n    margin-left:
                4px;\r\n    font-size: 80%;\r\n    font-style: italic;\r\n
                }\r\n  #electre-infos h1 {\r\n    font-transform:
                uppercase;\r\n    color: red;\r\n  }\r\n</style>\r\n<div
                id=\"electre-infos\">\r\n  \r\n    <div
                id=\"electre-biography\">\r\n      <h1>Biographies</h1>\r\n
                <div><p>Historienne à l'université de Picardie Jules Verne
                (CAREF), Mélanie Fabre travaille sur l'éducation, les femmes et
                le genre, ainsi que sur la gauche à l'époque
                contemporaine.</p></div>\r\n    </div>\r\n  \r\n  \r\n    <div
                id=\"electre-backcover\">\r\n      <h1>Quatrième de
                couverture</h1>\r\n      <div><p>« Pour Pauline Kergomard, la
                crise de l'affaire </p></div>\r\n    </div>\r\n  \r\n  \r\n
                \r\n</div>\r\n"
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

Dans les Outils de plugins, vous voyez le plugin **_Tamil Electre_**. Cliquez sur
Actions > Configurer. La page de configuration est divisée en quatre sections.

**API Electre NG** — Contient les informations de connexion à l'API d'Electre :
point d'entrée des services web, de l'authentification OAuth 2, le nom
d'utilisateur et le mot de passe.

**Cache du plugin** — Afin de ne pas surcharger les serveurs d'Electre, le
plugin peut être paramétré pour mettre en cache les informations Electre. En
phase de test du plugin, on peut avoir intérêt à désactiver le cache : on verra
immédiatement le résultat des modifications apportées au template (voir plus
bas).

**OPAC / Détail** — Contrôle l'affichage des informations Electre sur la page
de détail de l'OPAC, image de couverture et informations textuelles. Pour les
textes, leur affichage est contrôlé par un _template_. Ces informations sont
affichées entre le pavé de la notice bibliographique et la table des
exemplaires. Le template utilise la syntaxe [Template
Toolkit](https://template-toolkit.org), la même qui est utilisée dans les
notifications Koha. Le template transforme les infos Electre en HTML. Ce code
HTML est placé dans la structure de données qui est mise en cache pour chaque
ISBN. Voir plus haut le service web intermédiaire du plugin : `koha.opac.info`.

**OPAC / Résultat** - Contrôle l'affichage des couvertures Electre sur la page
de résultat de l'OPAC.

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

Le plugin utilise par ailleurs un module Perl qu'on ne trouve pas en standard
avec Koha : `Pithub::Markdown`. il faut l'installer sur votre serveur Koha.

## VERSIONS

* **1.0.1** / novembre 2024 — Version initiale

## LICENCE

This software is copyright (c) 2024 by Tamil s.a.r.l..

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

