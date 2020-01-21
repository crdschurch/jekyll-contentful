# jekyll-contentful

[![Build Status](https://travis-ci.org/crdschurch/jekyll-contentful.svg?branch=master)](https://travis-ci.org/crdschurch/jekyll-contentful)

`jekyll-contentful` is a plugin that integrates blog content from the [Contentful API](https://www.contentful.com/developers/docs/references/content-delivery-api/) with your Jekyll site.

## Installation

Add the following to your `Gemfile` and bundle...

```ruby
gem "jekyll-contentful", "~> 1.0", git: 'https://github.com/crdschurch/jekyll-contentful.git'
```

Note, in order to support Contentful environents, this project requires [v2.6.0](https://github.com/contentful/contentful.rb/releases/tag/v2.6.0) or greater of the [Contentful gem](http://rubygems.org/gems/contentful).

## Configuration

As of version 1.0, this library doesn't need a ton of configuration to do its thing. In fact, by default `jekyll-contentful` will pull all content-models from your Contentful space unless you explicitly exclude them.

### Excluding Content Models

If you do not want to query and generate collection documents for a specific content-model, you can add the following Jekyll's `_config.yml` file where the exclude array contains one or more Contentful ids. This will tell `jekyll-contentful` to pull in all content-models, except `article` and `podcast`.

```
contentful:
  exclude:
    - article
    - product
```

If you want to exclude all models not otherwise specified, you can do the following...

```
contentful:
  exclude:
    - '*'
```

### Specifying Filenames

By default, the names for any files generated in the collections directory will adhere to the following format... `#{content-type}-#{id}.md`.

In some cases, you may want to manipulate the filenames so that they work better with Jekyll's internal publishing logic. For each collection in your `_config.yml` file, you can specify the template for resulting filenames. Note, this template is parsed like any other Liquid template so you can access any filters and/or frontmatter data for the individual document...

```yaml
collections:
  articles:
    filename: "{{ some_date_field | date: '%Y-%m-%d' }}-{{ slug }}"
    output: false
```

### Specifying Content Date

To ensure anything with a specified date in the future is not written for processing you have the following options:

1. add the following to your _config.yml:

    ```yaml
    contentful:
      some_content_type:
        map:
          published_at: 'some_date_field'
    ```
    Where `some_date_field` represents a date to begin writing content to disk

2. by default have a `published_at` field with the appropriate start date to begin writing content to disk

To ensure anything with a specified unpublished date in the past is not written for processing you have the following options:

1. add the following to your _config.yml:
    ```yaml
    contentful:
      some_content_type:
        map:
          date: 'some_date_field'
          unpublished_at: 'some_other_date_field'
    ```
    Where `some_other_date_field` represents a date to stop writing content to disk

2. by default have an `unpublished_at` field with the appropriate end date to stop writing content to disk

NOTE – `jekyll-contentful` will only write content that is less than or equal to today's date if a `published_at` field exists in the frontmatter. This makes it possible to ensure no content with a future date is aggregated from Contentful / rendered within your static site. Furthermore, if an `unpublished_at` is specified that is <= now the content will not write to disk, ignoring `published_at` entirely.

### Linked Entries

Contentful content models can contain _reference_ fields in which an entry can associate one or many other entries to it. In some cases you may want to apply the reciprocal reference to the frontmatter of an entry. This gem currently supports one specific case in which you can accomplish this:

Suppose you have two content types -- _question_ and _answer_ -- and you have configured these content models such that the _question_ content type has a _many reference_ field called `answers` in which you can add and arrange answers to the question. If you want to display a question on an answer's page in Jekyll, you'd have to query through Liquid (which is slow) or write a custom Jekyll plugin (which is faster, but still slow). Alternatively, jekyll-contentful can drop the frontmatter for a question inside the frontmatter for each of its answers.

The configuration for this type of relationship looks like this:

```yml
contentful:
  # ...
  (content_type):
    belongs_to:
      (associated_content_type): (reference_field_name)
```

For this particular example, the config would look like this:

```yml
contentful:
  # ...
  answer:
    belongs_to:
      question: answers
```

_Note: Currently only `belongs_to` reciprocal relationships are supported._

### Query Controls

While you can control queries for all content types from the command line (see [_Usage_](#usage) below), you can also control the query for individual content types within the config file.

The following keys are available:

- `query`
- `limit`
- `order`

For example:

```yml
contentful:
  # ...
  article:
    limit: 10
    query: fields.published_at[lte]=2018-08-16
    order: sys.createdAt
```

Note: for more fine-grained control of ordering try using `desc`. For example:
`order: 'published_at desc'` would return entries sorted by most recent published
date.

See [_Usage_](#usage) for additional details.

## Specifying Content Field

To make use of [Jekyll's `content` and `excerpt` methods](https://jekyllrb.com/docs/posts/), the command will look for a `content` option in your collections configuration. If it does not exist, it will attempt to fall back to body, and otherwise include no content in the body of the entry's YML file.

Given the following example:

```yml
collections:
  articles:
  # ...
  authors:
    # ...
    content: bio
```

If there is a `body` field on the `article` content type in Contentful, the content of that field will be rendered as the content of the entry's YML file. Otherwise it will be blank. On the other hand, the script will render the `bio` field for authors' entry files as the content.

## Environment Variables

The following environment variables are required to run the script. Please make sure they are exported to the same scope in which your Jekyll commands are run.

| Name                          | Description                                           | Default  |
| ----------------------------- | ----------------------------------------------------- | -------- |
| `CONTENTFUL_ACCESS_TOKEN`     | Access token for Contentful's Delivery or Preview API |          |
| `CONTENTFUL_MANAGEMENT_TOKEN` | Access token for Contentful's Management API          |          |
| `CONTENTFUL_SPACE_ID`         | ID specifying Contentful Space                        |          |
| `CONTENTFUL_ENV`              | Contentful environment                                | `master` |

## Content Distribution

You can choose to only include content relative to a specific "distribution channel" by passing the `--sites` flag when running the command. This is useful if you need to author content for multiple sites in a single Contentful space.

In order to make use of this feature, you'll need to add a new JSON object field to your content model(s) that specifies which sites that content should be distributed to. The contents of that field should look like this...

```
[
  {
    "site": "www.crossroads.net"
  }
]
```

The default name for this field is `distribution_channels`. Let's assume the name of that field is actually just `channels` so you would add the following to your site's `_config.yml` file to tell `jekyll-contentful` which field to look for...

```
contentful:
  config:
    sites: channels
```

Now, when pulling content from Contentful using this Gem, you would pass the following flag to only include content that contains the entry `www.crossroads.net` within the `channels` field...

```
$ bundle exec jekyll contentful --sites www.crossroads.net
```

Note, when passing the `--sites` flag, only those content-models that contain the field specified will be subject to exclusion.

## Usage

Once configured as described above, you can run the following Jekyll subcommand to persist content from the API to your local `collections/` directory.

```text
$ bundle exec jekyll contentful
```

You can reduce the volume of content returned from Contentful by specifying one or more collections on the command line and/or speciyfing a limit. The following example will return (up to) 10 records for both articles & authors collection...

```
$ bundle exec jekyll contentful --collections articles,authors --limit 10
```

You can also tell jekyll-contentful to just return recently created content by specifying a range for the `--recent` flag. For example...

```
$ bundle exec jekyll contentful --recent 10.days.ago
```

...will return any content who's createdAt is greater than or equal to 10 days ago. This features relies relative date syntax provided by [ActiveSupport](https://github.com/rails/rails/tree/master/activesupport).

If none of these approaches are scratching your itch, you can also pass through any individual query parameters supported by the Contentful Delivery API. For example...

```
$ bundle exec jekyll contentful  --query='fields.published_at[gte]=2018-08-01'
```

...will return any content who's `published_at` field has a date value greater than or equal to `2018-08-01`. For multiple params, just delimit them with ampersands and they'll be passed directly to the API.

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
