# ApplicationRecordLogger
Short description and motivation.

Rails plugin to log data changes to application records. This is not general purpose log but specifically aims to grant easy access databased data-change log associated with users and actions. This makes extracting logging information on records out of the box, but provides no further tools nor information for debugging. You may apply this gem to meet compliance needs, or perhaps to find inappropriate user activity.

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

## Usage
To log all models write:


```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include ApplicationRecordLogger
end
```
 Including `ApplicationRecordLogger` will provide a set of callbacks on `after_create`, `after_update`, and `after_destroy` to create instances of `ApplicationRecordLog` storing the changes to the changed instances in a separate record. This will allow you to see the historical state and flow on a record, including the times of changes, the users committing the changes, the changes, action types, and  even the possibility to recreate a record to given point of time.

 In order to associate a user with a change simply set the `current_user` to the instance that is about to change:

```ruby
class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def update
    @invoice = Invoice.find(params[:id])
    if @invoice.update(invoice_params)
      render json: @invoice.as_json, status: :ok
    else
      render json: @item.errors, status: :unprocessable_entity
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

### Configuration
To come

## TODO
The list is incomplete

- Allow save with logging disabled
- Ensure create log never created if no user is associated (contentless)
- Remove message
- Test {configuration, module, rollback, create update, destroy, deep serialized log}

## Contributing
Contact author.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
