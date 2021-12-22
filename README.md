Consul — A next gen authorization solution
==========================================

[![Tests](https://github.com/makandra/consul/workflows/Tests/badge.svg)](https://github.com/makandra/consul/actions) [![Code Climate](https://codeclimate.com/github/makandra/consul.png)](https://codeclimate.com/github/makandra/consul)


Consul is an authorization solution for Ruby on Rails where you describe *sets of accessible things* to control what a user can see or edit.

We have used Consul in combination with [assignable_values](https://github.com/makandra/assignable_values) to solve a variety of authorization requirements ranging from boring to bizarre.
Also see our crash course video: [Solving bizare authorization requirements with Rails](http://bizarre-authorization.talks.makandra.com/).

Consul is tested with Rails 5.2, 6.1 and 7.0 on Ruby 2.5, 2.7 and 3.0 (only if supported, for each Ruby/Rails combination). If you need support for Rails 3.2, please use [v0.13.2](https://github.com/makandra/consul/tree/v0.13.2).


Describing access to your application
-------------------------------------

You describe access to your application by putting a `Power` model into `app/models/power.rb`.
Inside your `Power` you can talk about what is accessible for the current user, e.g.

- [A scope of records a user may see](#scope-powers-relations)
- [Whether the user is allowed to use a particular screen](#boolean-powers)
- [A list of values a user may assign to a particular attribute](#validating-assignable-values)

A `Power` might look like this:

```rb
class Power
  include Consul::Power

  def initialize(user)
    @user = user
  end

  power :users do
    User if @user.admin?
  end

  power :notes do
    Note.by_author(@user)
  end

  power :dashboard do
    true # not a scope, but a boolean power. This is useful to control access to stuff that doesn't live in the database.
  end

end
```

There are no restrictions on the name or constructor arguments of this class.

You can deposit all kinds of objects in your power. See the sections below for details.


### Scope powers (relations)


A typical use case in a Rails application is to restrict access to your ActiveRecord models. For example:

- Anonymous visitors may only see public posts
- Users may only see their own notes
- Only admins may edit users

You do this by making your powers return an ActiveRecord scope (or "relation"):

```rb
class Power
  ...

  power :notes do
    Note.by_author(@user)
  end

  power :users do
    User if @user.admin?
  end

end
```

You can now query these powers in order to retrieve the scope:

```rb
power = Power.new(user)
power.notes  # => returns an ActiveRecord::Scope
```

Or you can ask if the power is given (meaning it's not `nil`):

```rb
power.notes? # => returns true if Power#notes returns a scope and not nil
```

Or you can raise an error unless a power is given, e.g. to guard access into a controller action:

```rb
power.notes! # => raises Consul::Powerless unless Power#notes returns a scope (even if it's empty)
```

Or you ask whether a given record is included in its scope (can be [optimized](#optimizing-record-checks-for-scope-powers)):

```rb
power.note?(Note.last) # => returns whether the given Note is in the Power#notes scope. Caches the result for subsequent queries.
```

Or you can raise an error unless a given record is included in its scope:

```rb
power.note!(Note.last) # => raises Consul::Powerless unless the given Note is in the Power#notes scope
```

See our crash course video [Solving bizare authorization requirements with Rails](http://bizarre-authorization.talks.makandra.com/) for many different use cases you can cover with this pattern.



### Defining different powers for different actions

If you have different access rights for e.g. viewing or updating posts, simply use different powers:


```rb
class Power
  ...

  power :notes do
    Note.published
  end

  power :updatable_notes do
    Note.by_author(@user)
  end

  power :destroyable_notes do
    Note if @user.admin?
  end

end
```

There is also a [shortcut to map different powers to RESTful controller actions](#protect-entry-into-controller-actions).



### Boolean powers

Boolean powers are useful to control access to stuff that doesn't live in the database:

```rb
class Power
  ...

  power :dashboard do
    true
  end

end
```

You can query it like the other powers:

```rb
power = Power.new(@user)
power.dashboard? # => true
power.dashboard! # => raises Consul::Powerless unless Power#dashboard? returns true
```


### Powers that give no access at all

Note that there is a difference between having access to an empty list of records, and having no access at all.
If you want to express that a user has no access at all, make the respective power return `nil`.

Note how the power in the example below returns `nil` unless the user is an admin:

```rb
class Power
  ...

  power :users do
    User if @user.admin?
  end

end
```

When a non-admin queries the `:users` power, she will get the following behavior:

```rb
power = Power.new(@user)
power.users # => returns nil
power.users? # => returns false
power.users! # => raises Consul::Powerless
power.user?(User.last) # => returns false
power.user!(User.last) # => raises Consul::Powerless
```



### Powers that only check a given object

Sometimes it is not convenient to define powers as a collection or scope (relation).
Sometimes you only want to store a method that checks whether a given object is accessible.

To do so, simply define a power that ends in a question mark:


```rb
class Power
  ...

  power :updatable_post? do |post|
    post.author == @user
  end

end
```

You can query such an power as always:

```rb
power = Power.new(@user)
power.updatable_post?(Post.last) # return true if the author of the post is @user
power.updatable_post!(Post.last) # raises Consul::Powerless unless the author of the post is @user
```


### Other types of powers

A power can return any type of object. For instance, you often want to return an array:

```rb
class Power
  ...

  power :assignable_note_states do
    if admin?
      %w[draft pending published retracted]
    else
      %w[draft pending]
    end
  end

end
```

You can query it like any other power. E.g. if a non-admin queries this power she will get the following behavior:

```rb
power.assignable_note_states # => ['draft', 'pending']
power.assignable_note_states? # => returns true
power.assignable_note_states! # => does nothing (because the power isn't nil)
power.assignable_note_state?('draft') # => returns true
power.assignable_note_state?('published') # => returns false
power.assignable_note_state!('published') # => raises Consul::Powerless
```


### Defining multiple powers at once

You can define multiple powers at once by giving multiple power names:

```rb
class Power
  ...

  power :destroyable_users, :updatable_users do
    User if admin?
  end

end
```


### Powers that require context (arguments)

Sometimes it can be useful to define powers that require context. To do so, just take an argument in your `power` block:

```rb
class Power
  ...

  power :client_notes do |client|
    client.notes.where(:state => 'published')
  end

end
```

When querying such a power, you always need to provide the context, e.g.:

```rb
client = ...
note = ...
Power.current.client_note?(client, note)
```


### Optimizing record checks for scope powers

You can query a scope power for a given record, e.g.

```rb
class Power
  ...

  power :posts do |post|
    Post.where(:author_id => @user.id)
  end
end

power = Power.new(@user)
power.post?(Post.last)
```

What Consul does internally is fetch **all** the IDs of the `power.posts` scope and test if the given
record's ID is among them. This list of IDs is cached for subsequent calls, so you will only touch the database once.

As scary as it might sound, fetching all IDs of a scope scales quiet nicely for many thousand records. There will
however be the point where you want to optimize this.

What you can do in Consul is to define a second power that checks a given record in plain Ruby:

```rb
class Power
  ...

  power :posts do |post|
    Post.where(:author_id => @user.id)
  end

  power :post? do |post|
    post.author_id == @user.id
  end

end
```

This way you do not need to touch the database at all.


Role-based permissions
----------------------

Consul has no built-in support for role-based permissions, but you can easily implement it yourself. Let's say your `User` model has a string column `role` which can be `"author"` or `"admin"`:

```rb
class Power
  include Consul::Power

  def initialize(user)
    @user = user
  end

  power :notes do
    case role
      when :admin then Note
      when :author then Note.by_author
    end
  end

  private

  def role
    @user.role.to_sym
  end

end
```


Controller integration
----------------------

It is convenient to expose the power for the current request to the rest of the application. Consul will help you with that if you tell it how to instantiate a power for the current request:

```rb
class ApplicationController < ActionController::Base
  include Consul::Controller

  current_power do
    Power.new(current_user)
  end

end
```

You now have a helper method `current_power` for your controller and views. Everywhere else, you can access it from `Power.current`. The power will be instantiated when the request is handed over from routing to `ApplicationController`, and will be nilified once the request was processed.

You can now use power scopes to control access:

```rb
class NotesController < ApplicationController

  def show
    @note = current_power.notes.find(params[:id])
  end

end
```


### Protect entry into controller actions

To make sure a power is given before every action in a controller:

```rb
class NotesController < ApplicationController
  power :notes
end
```

You can use `:except` and `:only` options like in before\_actions.

You can also map different powers to different actions:

```rb
class NotesController < ApplicationController
  power :notes, :map => { [:edit, :update, :destroy] => :changeable_notes }
end
```

Actions that are not listed in `:map` will get the default action `:notes`.

Note that in moderately complex authorization scenarios you will often find yourself writing a map like this:

```rb
class NotesController < ApplicationController
  power :notes, :map => {
    [:edit, :update] => :updatable_notes,
    [:new, :create] => :creatable_notes,
    [:destroy] => :destroyable_notes
  }
end
```

Because this pattern is so common, there is a shortcut `:crud` to do the same:

```rb
class NotesController < ApplicationController
  power :crud => :notes
end
```


And if your power [requires context](#powers-that-require-context-arguments) (is parametrized), you can give it using the `:context` method:

```rb
class ClientNotesController < ApplicationController

  power :client_notes, :context => :load_client

  private

  def load_client
    @client ||= Client.find(params[:client_id])
  end

end
```



### Auto-mapping a power scope to a controller method

It is often convenient to map a power scope to a private controller method:

```rb
class NotesController < ApplicationController

  power :notes, :as => :note_scope

  def show
    @note = note_scope.find(params[:id])
  end

end
```

This is especially useful when you are using a RESTful controller library like [resource_controller](https://github.com/jamesgolick/resource_controller). The mapped method is aware of the `:map` option.


### Multiple power-mappings for nested resources

When using [nested resources](http://guides.rubyonrails.org/routing.html#nested-resources) you probably want two power
checks and method mappings: One for the parent resource, another for the child resource.

Say you have the following routes:

```rb
resources :clients do
  resources :notes
end
```

And the following power definitions:

```rb
class Power
  ...

  power :clients do
    Client.active if signed_in?
  end

  power :client_notes do |client|
    client.notes.where(:state => 'published')
  end

end
```

You can now check and map both powers in the nested `NotesController`:

```rb
class NotesController < ApplicationController

  power :clients, :as => :client_scope
  power :client_notes, :context => :load_client, :as => :note_scope

  def show
    load_note
  end

  private

  def load_client
    @client ||= client_scope.find(params[:client_id])
  end

  def load_note
    @note ||= note_scope.find(params[:id])
  end

end
```

Note how we provide the `Client` parameter for the `:client_notes` power by using the `:context => :load_client`
option in the `power` directive.

### How to never forget a power check

You can force yourself to use a `power` check in every controller. This will raise `Consul::UncheckedPower` if you ever forget it:

```rb
class ApplicationController < ActionController::Base
  include Consul::Controller
  require_power_check
end
```

Note that this check is satisfied by *any* `.power` directive in the controller class or its ancestors, even if that `.power` directive has `:only` or `:except` options that do not apply to the current action.

Should you want to forego the power check (e.g. to remove authorization checks from an entirely public controller):

```rb
class ApiController < ApplicationController
  skip_power_check
end
```


Validating assignable values
----------------------------

Sometimes a scope is not enough to express what a user can edit. You will often want to give a user write access to a record, but restrict the values she can assign to a given field.

Consul leverages the [assignable_values](https://github.com/makandra/assignable_values) gem to add an optional authorization layer to your models. This layer adds additional validations in the context of a request, but skips those validations in other contexts (console, background jobs, etc.).

You can enable the authorization layer by using the macro `authorize_values_for`:

```rb
class Story < ActiveRecord::Base
  authorize_values_for :state
end
```

The macro defines an accessor `power` on instances of `Story`. If that field is set to a power, the values of `state` will be validated against a whitelist of values provided by that power. If that field is `nil`, the validation is skipped.

Here is a power implementation that can provide a list of assignable values for the example above:

```rb
class Power
  ...

  def assignable_story_states(story)
    if admin?
      ['delivered', 'accepted', 'rejected']
    else
      ['delivered']
    end
  end

end
```

Here you can see how to activate the authorization layer and use the new validations:

```rb
story = Story.new
Power.current = Power.new(:role => :guest) # activate the authorization layer

story.assignable_states # ['delivered'] # apparently we're not admins

story.state = 'accepted' # a disallowed value
story.valid? # => false

story.state = 'delivered' # an allowed value
story.valid? # => true
```

You can not only authorize scalar attributes like strings or integers that way, you can also authorize `belongs_to` associations:

```rb
class Story < ActiveRecord::Base
  belongs_to :project
  authorize_values_for :project
end

class Power
  ...

  power :assignable_story_projects do |story|
    user.account.projects
  end
end
```

The `authorize_values_for` macro comes with many useful options and details best explained in the [assignable_values README](https://github.com/makandra/assignable_values), so head over there for more. The macro is basically a shortcut for this:

```rb
assignable_values_for :field, :through => lambda { Power.current }
```

Memoization
-----------

All power methods are [memoized](https://www.justinweiss.com/articles/4-simple-memoization-patterns-in-ruby-and-one-gem/) for performance reasons. Multiple calls to the same method will only call your block the first time, and return a cached result afterwards:

```
power = Power.new
power.projects! # calls the `power :projects { ... }` block
power.projects! # returns the cached result from earlier
power.projects! # returns the cached result from earlier
```

If you want to discard all cached results, call `#unmemoize_all`:

```
power.unmemoize_all
```


Dynamic power access
--------------------

Consul gives you a way to dynamically access and query powers for a given name, model class or record.
A common use case for this are generic helper methods, e.g. a method to display an "edit" link for any given record
if the user is authorized to change that record:

```rb
module CrudHelper

  def edit_record_action(record)
    if current_power.include_record?(:updatable, record)
      link_to 'Edit', [:edit, record]
    end
  end

end
```

You can find a full list of available dynamic calls below:

| Dynamic call                                            | Equivalent                                 |
|---------------------------------------------------------|--------------------------------------------|
| `Power.current.send(:notes)`                            | `Power.current.notes`                      |
| `Power.current.include_power?(:notes)`                  | `Power.current.notes?`                     |
| `Power.current.include_power!(:notes)`                  | `Power.current.notes!`                     |
| `Power.current.include_object?(:notes, Note.last)`      | `Power.current.note?(Note.last)`           |
| `Power.current.include_object!(:notes, Note.last)`      | `Power.current.note!(Note.last)`           |
| `Power.current.for_model(Note)`                         | `Power.current.notes`                      |
| `Power.current.for_model(:updatable, Note)`             | `Power.current.updatable_notes`            |
| `Power.current.include_model?(Note)`                    | `Power.current.notes?`                     |
| `Power.current.include_model?(:updatable, Note)`        | `Power.current.updatable_notes?`           |
| `Power.current.include_model!(Note)`                    | `Power.current.notes!`                     |
| `Power.current.include_model!(:updatable, Note)`        | `Power.current.updatable_notes!`           |
| `Power.current.include_record?(Note.last)`              | `Power.current.note?(Note.last)`           |
| `Power.current.include_record?(:updatable, Note.last)`  | `Power.current.updatable_note?(Note.last)` |
| `Power.current.include_record!(Note.last)`              | `Power.current.note!(Note.last)`           |
| `Power.current.include_record!(:updatable, Note.last)`  | `Power.current.updatable_note!(Note.last)` |
| `Power.current.name_for_model(Note)`                    | `:notes`                                   |
| `Power.current.name_for_model(:updatable, Note)`        | `:updatable_notes`                         |



Querying a power that might be nil
----------------------------------

You will often want to access `Power.current` from another model, to e.g. iterate through the list of accessible users:

```rb
class UserReport

  def data
    Power.current.users.collect do |user|
      [user.name, user.email, user.income]
    end
  end

end
```

Good practice is for your model to not crash when `Power.current` is `nil`. This is the case when your model isn't
called as part of processing a browser request, e.g. on the console, during tests and during batch processes.
In such cases your model should simply skip authorization and assume that all users are accessible:

```rb
class UserReport

  def data
    accessible_users = Power.current.present? ? Power.current.users : User
    accessible_users.collect do |user|
      [user.name, user.email, user.income]
    end
  end

end
```

Because this pattern is so common, the `Power` class comes with a number of class methods you can use to either query
`Power.current` or, if it is not set, just assume that everything is accessible:

```rb
class UserReport

  def data
    Power.for_model(User).collect do |user|
      [user.name, user.email, user.income]
    end
  end

end
```

There is a long selection of class methods that behave neutrally in case `Power.current` is `nil`:

| Call                                                     | Equivalent                                                          |
|----------------------------------------------------------|---------------------------------------------------------------------|
| `Power.for_model(Note)`                                  | `Power.current.present? ? Power.current.notes : Note`               |
| `Power.for_model(:updatable, Note)`                      | `Power.current.present? ? Power.current.updatable_notes : Note`     |
| `Power.include_model?(Note)`                             | `Power.current.present? ? Power.notes? : true`                      |
| `Power.include_model?(:updatable, Note)`                 | `Power.current.present? ? Power.updatable_notes? : true`            |
| `Power.include_model!(Note)`                             | `Power.notes! if Power.current.present?`                            |
| `Power.include_model!(:updatable, Note)`                 | `Power.updatable_notes! if Power.current.present?`                  |
| `Power.include_record?(Note.last)`                       | `Power.current.present? ? Power.note?(Note.last) : true`            |
| `Power.include_record?(:updatable, Note.last)`           | `Power.current.present? ? Power.updatable_note?(Note.last?) : true` |
| `Power.include_record!(Note.last)`                       | `Power.note!(Note.last) if Power.current.present?`                  |
| `Power.include_record!(:updatable, Note.last)`           | `Power.updatable_note!(Note.last) if Power.current.present?`        |



Testing
-------

This section Some hints for testing authorization with Consul.

### Test that a controller checks against a power

Include the Consul Matcher `spec/support/consul_matchers.rb`:

```
require 'consul/spec/matchers'

RSpec.configure do |c|
  c.include Consul::Spec::Matchers
end
```

You can say this in any controller spec:

```rb
describe CakesController do

  it { should check_power(:cakes) }

end
```

You can test against all options of the `power` macro:

```rb
describe CakesController do

  it { should check_power(:cakes, :map => { [:edit, :update] => :updatable_cakes }) }

end
```

### Temporarily change the current power

When you set `Power.current` to a power in an RSpec example, you must remember to nilify it afterwards. Otherwise other examples will see your global changes.

A better way is to use the `.with_power` method to change the current power for the duration of a block:

```rb
admin = User.new(:role => 'admin')
admin_power = Power.new(admin)

Power.with_power(admin_power) do
  # run code that uses Power.current
end
```

`Power.current` will be `nil` (or its former value) after the block has ended.

A nice shortcut is that when you call `with_power` with an argument that is not already a `Power`, Consul will instantiate a `Power` for you:

```rb
admin = User.new(:role => 'admin')

Power.with_power(admin) do
  # run code that uses Power.current
end
```

There is also a method `.without_power` that runs a block without a current Power:

```rb
Power.without_power do
  # run code that should not see a Power
end
```


Installation
------------

Add the following to your `Gemfile`:

```
gem 'consul'
```

Now run `bundle install` to lock the gem into your project.


Development
-----------

We currently develop using Ruby 2.5.3 (see `.ruby-version`) since that version works for current versions of ActiveRecord that we support. GitHub Actions will test additional Ruby versions (2.3.8, 2.4.5, and 3.0.1).

There are tests in `spec`. We only accept PRs with tests. To run tests:

- Install Ruby 2.5.3
- run `bundle install`
- Put your database credentials into `spec/support/database.yml`. There's a `database.sample.yml` you can use as a template.
- There are gem bundles in the project root for each rails version that we support.
- You can bundle all test applications by saying `bundle exec rake matrix:install`
- You can run specs from the project root by saying `bundle exec rake matrix:spec`. This will run all gemfiles compatible with your current Ruby.

If you would like to contribute:

- Fork the repository.
- Push your changes **with specs**.
- Send me a pull request.

Note that we have configured GitHub Actions to automatically run tests in all supported Ruby versions and dependency sets after each push. We will only merge pull requests after a green GitHub Actions run.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)
