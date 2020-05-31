# sql-foo
tools, utils, helpers for converting &amp; translating Mysql/Oracle/Mariadb SQL dumps


... unrelated JSON-Schema-sample:

```json
{
  "accountOwner": {
    "$id": "#/definitions/accountOwner",
    "type": "string",
    "title": "accountOwner",
    "description": "accountOwner description",
    "maxLength": 300,
    "default": "MIPO-Testk 29",
    "examples": [
        "Maier Can DE",
        "Heymann Lewin",
        "Reiter Madeleine",
        "Fechner Lorenz"
    ]
  },
  "drebaCode": {
    "$id": "#/definitions/drebaCode",
    "type": "string",
    "title": "drebaCode",
    "description": "drebaCode description",
    "maxLength": 300,
    "default": "077",
    "examples": [
        "478",
        "330",
        "528",
        "800"
    ]
  },
  "help_url_object": {
    "$id": "#/definitions/help_url_object",
    "type": "object",
    "title": "HILFE_URL_item_object",
    "description": "help_url_object description",
    "properties": {
        "siteKey": {
            "$ref": "#/definitions/siteKey"
        },
        "url": {
            "$ref": "#/definitions/url"
        },
        "locale": {
            "$ref": "#/definitions/locale"
        }
    },
    "required": [
        "siteKey",
        "url",
        "locale"
    ]
  },
}
```
