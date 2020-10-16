# Decidim::Suggestions

Suggestions is the place on Decidim's where citizens can promote a civic suggestion. Unlike
participatory processes that must be created by an administrator, Civic suggestions can be
created by any user of the platform.

A suggestion will contain attachments and comments from other users as well.

Prior to be published a suggestion must be technically validated. All the validation
process and communication between the platform administrators and the sponsorship
committee is managed via an administration UI.

## Usage

This plugin provides:

* A CRUD engine to manage suggestions.

* Public views for suggestions via a high level section in the main menu.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'decidim-suggestions', git: 'git@github.com:belighted/decidim-module-suggestions.git'
```

And then execute:

```bash
bundle
bundle exec rails decidim_suggestions:install:migrations
bundle exec rails db:migrate
```

## Database

The database requires the extension pg_trgm enabled. Contact your DBA to enable it.

```sql
CREATE EXTENSION pg_trgm;
```

## Deactivating authorization requirement and other module settings

Some of the settings of the module need to be set in the code of your app, for example in the file `config/initializers/decidim.rb`.

This is the case if you want to enable the creation of suggestions even when no authorization method is set.

Just use the following line:
```
Decidim::Suggestions.do_not_require_authorization = true
```

All the settings and their default values which can be overriden can be found in the file [`lib/decidim/suggestions.rb`](https://github.com/decidim/decidim/blob/master/decidim-suggestions/lib/decidim/suggestions.rb).

For example, you can also change the minimum number of required committee members to 1 (default is 2) by adding this line:
```
Decidim::Suggestions.minimum_committee_members = 1
```
Or change the number of days given to gather signatures to 365 (default is 120) with:
```
Decidim::Suggestions.default_signature_time_period_length = 365
```

## Rake tasks

This engine comes with three rake tasks that should be executed on daily basis. The best
way to execute these tasks is using cron jobs. You can manage this cron jobs in your
Rails application using the [Whenever GEM](https://github.com/javan/whenever) or even
creating them by hand.

### decidim_suggestions:check_validating

This task move all suggestions in validation phase without changes for the amount of
time defined in __Decidim::Suggestions::max_time_in_validating_state__. These suggestions
will be moved to __discarded__ state.

### decidim_suggestions:check_published

This task retrieves all published suggestions whose support method is online and the support
period has expired. Suggestions that have reached the minimum supports required will pass
to state __accepted__. The suggestions without enough supports will pass to __rejected__ state.

Suggestions with offline support method enabled (pure offline or mixed) will get its status updated
after the presential supports have been registered into the system.

### decidim_suggestions:notify_progress

This task sends notification mails when suggestions reaches the support percentages defined in
__Decidim::Suggestions.first_notification_percentage__ and __Decidim::Suggestions.second_notification_percentage__.

Author, members of the promoter committee and followers will receive it.

## Exporting online signatures

When the signature method is set to any or face to face it may be necessary to implement
a mechanism to validate that there are no duplicated signatures. To do so the engine provides
a functionality that allows exporting the online signatures to validate them against physical
signatures.

The signatures are exported as a hash string in order to preserve the identity of the signer together with her privacy.
Each hash is composed with the following criteria:

* Algorithm used: SHA1
* Format of the string hashed: "#{unique_id}#{title}#{description}"

There are some considerations that you must keep in mind:

* Title and description will be hashed using the same format included in the database, this is including html tags.
* Title and description will be hashed using the same locale used by the suggestion author. In case there is more
  than one locale available be sure that you change your locale settings to be inline with
  the locale used to generate the hashes outside Decidim.

## Seeding example data

In order to populate the database with example data proceed as usual in rails:

```bash
bundle exec rails db:seed
```

## Aditional considerations

### Cookies

This engine makes use of cookies to store large form data. You should change the
default session store or you might experience problems.

Check the [Rails configuration guide](http://guides.rubyonrails.org/configuring.html#rails-general-configuration)
in order to get instructions about changing the default session store.

## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

See [Decidim](https://github.com/decidim/decidim).
