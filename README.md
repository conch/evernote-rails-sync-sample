# evernote-rails-sync-sample
Sample Ruby on Rails app that shows how to perform synchronization with Evernote

## Prerequisites
### Ruby, Gems, Rails
This runs on Ruby 2.2.1 and Rails 4. Before you run the server, run
<pre>
bundle install
</pre>
to install the gems from the `Gemfile`. This assumes you have the Bundler gem installed
### PostgreSQL
To get the foundation of this app, run 'rails new myapp --database=postgresql'

Postgres must be installed and running on the machine that runs this sample.

Before running this sample for the first time, setup the database by running:
<pre>
rake db:create:all
rake db:migrate
rake db:seed
</pre>

To run the app, run
<pre>
rails server
</pre>
### Evernote API Key
You will need to request a consumer key and secret from Evernote to use their API.
Then set them as the following environment variables from the terminal in order to run this sample.
<pre>
export EVERNOTE_CONSUMER_KEY="<consumer key>"
export EVERNOTE_SECRET="<secret>"
export EVERNOTE_URL="https://sandbox.evernote.com" # can switch to https://www.evernote.com after you activate your consumer key on the production service
</pre>
