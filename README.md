# jekyll-contentful

[![Build Status](https://travis-ci.org/crdschurch/jekyll-contentful.svg?branch=master)](https://travis-ci.org/crdschurch/jekyll-contentful)

`jekyll-contentful` is a plugin that integrates blog content from the [Contentful API](https://www.contentful.com/developers/docs/references/content-delivery-api/) with your Jekyll site.

## Installation

Add the following to your `Gemfile` and bundle...

```ruby
gem "jekyll-contentful", "~> 1.0.0", git: 'https://github.com/crdschurch/jekyll-contentful.git'
```

Note, in order to support Contentful environents, this project requires [v2.6.0](https://github.com/contentful/contentful.rb/releases/tag/v2.6.0) or greater of the [Contentful gem](http://rubygems.org/gems/contentful).

## Configuration

As of version 1.0, this library doesn't need a ton of configuration to do its thing. In fact, by default jekyll-contentful will pull all content-models from your Contentful space unless you explicitly exclude them.

### Excluding Content Models

If you do not want to query and generate collection documents for a specific content-model, you can add the following Jekyll's `_config.yml` file where the exclude array contains one or more Contentful ids. This will tell jekyll-contentful to pull in all content-models, except `article` and `podcast`.

```
contentful:
  exclude:
    - article
    - product
```

### Specifying Filenames

By default, the names for any files generated in the collections directory will adhere to the following format... `#{content-type}-#{id}.md`.

In some cases, you may want to manipulate the filenames so that they work better with Jekyll's internal publishing logic. For each collection in your `_config.yml` file, you can specify the template for resulting filenames. Note, this template is parsed like any other Liquid template so you can access any filters and/or frontmatter data for the individual document...

```
collections:
  articles:
    filename: "{{ published_at | date: '%Y-%m-%d' }}-{{ slug }}"
    output: false
```

## Environment Variables

The following environment variables are required to run the script. Please make sure they are exported to the same scope in which your Jekyll commands are run.

| Name | Description | Default |
| ----- | ------ | ------- |
| `CONTENTFUL_ACCESS_TOKEN` | Access token for Contentful's Delivery or Preview API | |
| `CONTENTFUL_MANAGEMENT_TOKEN` | Access token for Contentful's Management API | |
| `CONTENTFUL_SPACE_ID` | ID specifying Contentful Space | |
| `CONTENTFUL_ENV` | Contentful environment | `master` |

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
$ bundle exec jekyll contentful  --recent 10.days.ago
```

...will return any content who's createdAt is greater than or equal to 10 days ago. This features relies relative date syntax provided by [ActiveSupport](https://github.com/rails/rails/tree/master/activesupport).

If none of these approaches are scratching your itch, you can also pass through any individual query parameters supported by the Contentful Delivery API. For example...

```
$ bundle exec jekyll contentful  --query='fields.published_at[gte]=2018-08-01'
```

...will return any content who's `published_at` field has a date value greater than or equal to `2018-08-01`. For multiple params, just delimit them with ampersands and they'll be passed directly to the API.

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
