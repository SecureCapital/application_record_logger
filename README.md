# ApplicationRecordLogger

Rails plugin to log data changes on application records. This is not general purpose log but specifically aims to grant easy access databased data-change logs associated with users and actions. This makes the extraction of historic data changes easy, but the module provides no further tools nor information for debugging. You may apply this gem to meet compliance needs, store all historical states of instances, or perhaps to find inappropriate user activity.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'application_record_logger'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install application_record_logger
```

To create `application_record_logs` table run:

```bash
$ rails g application_record_logger:install
$ rails db:migrate
```

## Uninstallation
To remove application_record_logs generte an uninstall migration:

```bash
$ rails g application_record_logger:uninstall
$ rails db:migrate
```

Reverse any conde changes related to usage of the gem, potentially:
  1. remove gem from gemfile
  2. Remove all `include ApplicationRecordLogger`
  3. Remove `config/initializers/application_record_logger.rb` or any other configuration of the gem
  4. Remove any setting of `current_user` on your models, likely in your controllers
  5. Remove any `after_action` in your controllers setting log data

## Usage
To associate all models with `application_record_logs` include `ApplicationRecordLogger` in `application_record.rb`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include ApplicationRecordLogger
  set_logging_callbacks!
end
```

 Including `ApplicationRecordLogger` will provide a set of callbacks on `after_create`, `after_update`, and `after_destroy` to create instances of `ApplicationRecordLog` storing the changes to the changed instances in a separate record, **IF** `set_logging_callbacks!` has been called. **ELSE** should you implement calls to log-creation yourself. The `application_record_logs` collection allows you to see the historical state and flow on a record, including the times of changes, the users committing the changes, the changes, action types, and  even the possibility to roll back a record to given point of time.

In order to associate a user with a change simply set the `current_user` to the instance that is about to change:

```ruby
class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def update
    @invoice = Invoice.find(params[:id])
    if @invoice.update(invoice_params)
      render json: @invoice.as_json, status: :ok
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  def authenticate_user!
    @current_user = warden.authenticate!(:my_strategy)
  end

  private
  def invoice_params
    # Notice that current_user is added to the data given from the authentication
    # process, which then will be set on the instance before save, allowing
    # the instance to create a log in context of @current_user
    params.fetch(:invoice, {}).permit(...).to_h.merge(current_user: @current_user)
  end
end
```

Now a put request from user 1 on invoice 1 may be summed up by following sudo statments:

```bash
put '/invoices/1', body: {invoice: {title: 'New title'}}

UPDATE `invoices` SET `title` = 'New title' WHERE `id` = 1;

INSERT INTO `application_record_logs` (`record_id`, `record_type`,`user_id`,`action`,`data`) VALUES (1, 'Invoice', 1, 'db_update', {'title': ['Old title', 'New title']});
```

In order to revoke the above action following code may be called:

```ruby
ApplicationRecordLog.rollback!(
  record_id: 1,
  record_type: 'Invoice',
  step: 1,
  action: ...,
  user_id: ...,
  user: ...,
  config: ...,
)
=> UPDATE `invoices` SET `title` = 'Old title' WHERE `id` = 1;
=> INSERT INTO `application_record_logs` (`record_id`, `record_type`,`user_id`,`action`,`data`) VALUES (1, 'Invoice', ..., 'rollback', {'title': ['New title', 'Old title']});
```

### Configuration
`ApplicationRecordLogger` holds a global configuration hash that is duplicated to each class including the module. The configuration contains:

| key | type | default | description |
|-|-|-|-|
|log_create | boolean | true | Wether or not to create log instances on create | 
|log_update | boolean | true | Wether or not to create log instances on update |
|log_destroy | boolean | true | Wether or not to create log instances on update |
|log_create_data | boolean | false | Wether or not a create log should hold the creation data. |
|log_user_activity_only | boolean | true | Wether or not to skip logs when no user is provided |
|log_fields | array | :default_log_fields | Array of strings contianing the column names that should be logged |
|log_field_types | array | SEE GEM | (~Global only) Array of symbols of which field_types logging is allowed for for generating the default_log_fields |
|log_exclude_field_names | array | SEE GEM | (~Global only) Array of strings of of which column names that should be excluded by default when generating default_log_fields |

#### log_fields
When a a class calls `logging_options` for the first time its own `:log_fields` will be set, accepting columns of the globally allowed types and excluding columns of globally discarded names (id, updated_at, created_at). The `:log_fields` determines what fields that should be watched for when creating an `applicaiton_record_log`. To override the default fields just configure the class:

```ruby
class Invoice < ApplicationRecord
  configure_logging_options do |opts|
    opts[:log_fields] = %w(my array of column names)
  end
end
```

Notice that if you desire to set an empty array the `configure_logging_options` cannot be used as the method will override empty fields with `default_log_fields`. To create an empty fieldset use the direct configuration:

```ruby
class Invoice < ApplicationRecord
  logging_options[:log_fields] = []
end
```

You should consider limiting `log_fields` to avoid logging larger text values (use the `log_field_types`) as it may produce to much data. Likewise may your system contain computed columns or systematic maintained data that alway can be reconstructed and thus should not be saved.

Notice that if you decide to include a new field, or create a new column this will not be logged to the history, thus a difference between the perceived and real history may occur.

#### log_create_data
If set to true each logged creation of an instance will produce a duplicate of the instance in the log-record, than can be rolled back to, given that `log_fields` do not change over the course of the applications life-span.

#### The `set_logging_callbacks!` method
The method sets callbacks after create, update and destroy to create a log instance. This is not activated by default due to avoidance of entanglement of the user object set in the controller and the models. If you desire to log user activity only you could consider handling log creation in the controller:

```ruby
class InvoicesController < ApplicationController
  before_action :authenticate_user!
  after_action :create_log, only: :update

  def update
    @invoice = Invoice.find(params[:id])
    if @invoice.update(invoice_params)
      render json: @invoice.as_json, status: :ok
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  def authenticate_user!
    @current_user = warden.authenticate!(:my_strategy)
  end

  def create_log
    unless @invoice.errors.any?
      ApplicationRecordLog.log(
        record: @invoice,
        user: @current_user,
        action: 'db_update',
      )
    end
  end

  private
  def invoice_params
    # Notice that current_user is added to the data given from the authentication
    # process, which then will be set on the instance before save, allowing
    # the instance to create a log in context of @current_user
    params.fetch(:invoice, {}).permit(...).to_h
  end
end
```

The above can easily be generalized across all the controllers, and should be preferred when only actions through the controllers should be logged, or actions associated with a user. The downside of the solution is the case where direct system changes are rolled out that modifying data and is not logged, thus removing the ability to track the real state of data.

## TODO
- Move test of rollback methods out of user
- Move test of logging out of Invoice

## Contributing
Contact author.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
