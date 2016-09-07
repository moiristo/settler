# Settler

[<img src="https://travis-ci.org/moiristo/settler.svg?branch=master"
alt="Build Status" />](https://travis-ci.org/moiristo/settler)

Settler can be used for defining application wide settings in Ruby. Settings
are loaded from a YAML file and stored in the database using ActiveRecord to
allow users to update settings on the fly. The YAML configuration allows you
to not only specify defaults, but setting value validations and typecasts as
well!


## NOTE

Settler v3 has not been released yet! You can find the latest v2 release code and docs here: https://github.com/moiristo/settler/tree/a2ed5a5d9e6932aa7ae68a2c2d4c3eef2a10c608

## Requirements

* Ruby 1.9.2, 1.9.3, 2.0.0, 2.1.5, 2.2.2, 2.3.0 (tested)

## Supported ORMs

* Activerecord 3.1, 3.2, 4.0, 4.1, 4.2, 5.0 (tested)
* In-memory store

## Installation

Add the gem to your Gemfile:

```ruby
gem 'settler'
```

## Upgrading from v2

In settler v3, settler objects have been namespaced under the namespace `Settler`. Please update your sources accordingly:

```ruby
Setting     => Settler::ORM::Activerecord::Setting
Typecaster  => Settler::Typecaster
```  

## Setup

### General

* A settler.yml file is needed to load the settings configuration. You can set its location as follows:

  ```ruby
  Settler.source = '/path/to/my/settler.yml'
  ```

  By default, it will be set to `config/settler.yml` for Rails. The contents of this file are described in the section 'Configuration'.

* A default YAML namespace can be set as follows:

  ```ruby
  Settler.namespace = 'staging'
  ```

### Rails/Activerecord

* You must create the table used by the `Settler::ORM::Activerecord::Setting` model and install an initial
  configuration file. Simply run this command:

  ```bash
  rails g settler
  ```

* This will create a migration and add a settler.yml configuration file
  in your config directory. Now just migrate the database:

  ```bash
  rake db:migrate
  ```

* Next, you'll have to edit the `settler.yml` file, of which the details are
  described in the Configuration section.

* You can manually set the configuration file source and default namespace
  as described above.

## Settings

* `Settler.orm` can be set to either `:activerecord` or `:ruby`. Default is `:activerecord`.
  * In `:ruby` mode, settings will not be persisted, but loaded in-memory instead.
  * In `:activerecord` mode, settings will be persisted using AR. However, settings will
    be loaded in `:ruby` mode when a database connection cannot be created or
    when the `settings` table has not been created (yet).
* `Settler.typecast_on_write` should be set to `true` if you want values to
  be typecasted before they are written to the database.
* `Settler.password_secret` can be used to set a custom secret for the
  `password` typecaster.


## Configuration

The initial version of `settler.yml` contains an example settings for specifying a google
analytics key. A setting consists of at least a key and a value. Consider
the following example:

```yml
google_analytics_key:
  label: Google analytics key
  value: 'UA-xxxxxx-x'
  editable: true
  deletable: false
  validations:
    presence: true
```

In this case, `google_analytics_key` is the key of the setting. Every nested
property is either an attribute of the setting or a list of validations.
Label, value, editable and deletable are attributes of the `Settler::Setting` model. If a
setting with a given key does not exist, it is created with the attributes
found. Therefore, you can consider these attributes as the default values for
the setting. See the validations section for more info on validations.

Note that you can use ERB in the configuration file if you need to. For
example:

```yaml
google_analytics_key:
  value: '<%= GOOGLE_ANALYTICS_KEY %>'
```

will evaluate the `GOOGLE_ANALYTICS_KEY` constant.

## Access settings

* Accessors will be created for every defined setting, returning a Setting
  instance:

  ```ruby
  >> Settler.google_analytics_key
  Setting Load (0.7ms)   SELECT * FROM "settings" WHERE ("settings"."key" = 'google_analytics_key') LIMIT 1
  +----+----------------------+----------------------+------------+----------+-----------+
  | id | key                  | label                | value      | editable | deletable |
  +----+----------------------+----------------------+------------+----------+-----------+
  | 6  | google_analytics_key | Google analytics key | UA-xxxxx-x | true     | false     |
  +----+----------------------+----------------------+------------+----------+-----------+
  ```

* You can access a setting's value quickly by using the index operator:

  ```ruby
  >> Settler[:google_analytics_key]
  Setting Load (0.7ms)   SELECT * FROM "settings" WHERE ("settings"."key" = 'google_analytics_key') LIMIT 1
  => "UA-xxxxx-x"
  ```

* Activerecord only: some named scopes for finding setting are available that may be useful as
  well:
  * `Settler::ORM::Activerecord::Setting.editable`: returns all editable settings.
  * `Settler::ORM::Activerecord::Setting.deletable`: returns all deletable settings.
  * `Settler::ORM::Activerecord::Setting.deleted`: returns all deleted settings.


## Typecasting

* Setting values can be typecasted to several types. This can easily be done
  by adding a 'typecast' property to `settler.yml`. For example:

  ```yaml
  float_value:
    label: A float that should be typecasted
    value: '0.25'
    typecast: float
  ```

  will ensure that the value returned by this setting will always be a float
  (`0.25`) instead if the string representation of a float.

* The following typecasters are available by default:
  * `integer`
  * `float`
  * `datetime`
  * `boolean`
  * `password`

  Note: the boolean typecaster will yield true when the value is `1`,`t` or
  `true` (case ignored), `false` otherwise.

* It is possible to create and use your own typecaster instead of the built
  in typecasters. A custom type caster should look like this:

  ```ruby
  class CustomTypecaster < Settler::Typecaster
    def typecast(value)
    # typecast and return value
    end
  end
  ```

When you require this class in your application, you can easily use your
typecaster by specifying its class name in the settler configuration:

  ```yaml
  custom_value:
    label: An integer that should be custom typecasted
    value: 1
    typecast: CustomTypecaster
  ```

## Validations

### Activerecord

* Validations are not stored in every setting, but are loaded on validation
  of a Setting instance. They apply to the value of the setting. The
  following validations can be created:
  * `presence`,  true/false.
  * `inclusion`, followed by a YAML array (e.g. `['a','b','c']`). Accepts a
    comma separated string as well.
  * `format`, followed by a YAML regex (e.g. `!ruby/regexp
    "/^UA-.{6}-.$/i"`). String can be given as well, which will be
    converted to a regex. Note that you will not be able to pass regex
    modifiers in that case, therefore the YAML regex syntax is
    recommended.

## Changing / Destroying settings

Settings are represented by your ORM of choice. In the case of ActiveRecord, you can just
update and destroy settings like you would update or destroy any AR model.

### Activerecord

* The `key` attribute is read only as it should never be changed through
  your application.

* By default, settings will only be editable or deletable iff the
  corresponding attribute is set to `true`. This will be enforced before
  saving or destroying a record:

  ```ruby
  >> Settler.google_analytics_key.destroy
  Setting Load (0.7ms)   SELECT \* FROM "settings" WHERE ("settings"."key" = 'google_analytics_key') LIMIT 1
  => false
  ```

* Settings can be reset to the values defined in the configuration file by
  calling reset!:

  ```ruby
  >> Settler.google_analytics_key.reset!
  => true
  ```

  Note that this will always work regardless of the `editable` attribute, so
  be careful when using this method!

* The `Settler::ORM::Activerecord::Setting` model performs a soft delete when it is destroyed, meaning the
  record is not really destroyed, but just marked as deleted. The reason for
  doing this is because settings are reloaded from the configuration file
  when your application is (re)started, unless a setting is already
  available in the database. Therefore, it should know about all deleted
  settings, otherwise it would re-insert the deleted setting. If you want to
  enforce this behaviour, use Setting#delete instead.

### Ruby

* The Ruby ORM just represents your YAML configuration as in-memory setting objects. You cannot edit or
  destroy these settings.

## Advanced usage

* When you define an inclusion validation on a setting, you can access these
  values for use in web forms by calling 'valid_values' on the setting:

  ```ruby
  >> Settler.search_algorithm.valid_values
  Setting Load (0.7ms)   SELECT * FROM "settings" WHERE ("settings"."key" = 'search_algorithm') LIMIT 1
  => ["ferret", "sphinx"]
  ```

  NB: This method returns nil when valid values cannot be found.

* Overriding setting attributes in the configuration is not as easy as it
  seems, since YAML doesn't support nested node merges. When overriding
  specific setting attributes, you should therefore do something like this:

  ```yaml
  settings: &settings
    google_analytics_key: &google
    label: Google analytics key
    value: 'UA-xxxxxx-x'

  development:
    <<: *settings
    google_analytics_key:
      <<: *google
      label: Development Google analytics key
      value: 'UA-xxxxxx-1'
  ```

* Report missing / raise missing

  * You can tell Settler to report missing attributes:

    ```ruby
    Settler.report_missing = true
    ```

    This will output a warning to `STDOUT` and (if present) the Rails logger to notify
    you that a missing setting was requested.

  * It is also possible to raise an exception instead when requesting
    missing attributes:

    ```ruby
    Settler.raise_missing = true
    ```


## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future
  version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to
  have your own version, that is fine but bump version in a commit by itself
  I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.


## Copyright

Copyright (c) 2016 Reinier de Lange. See LICENSE for details.