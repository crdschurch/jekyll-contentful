# jekyll-contentful

[![Build Status](https://travis-ci.org/crdschurch/jekyll-contentful.svg?branch=master)](https://travis-ci.org/crdschurch/jekyll-contentful)

`jekyll-contentful` is a plugin that integrates blog content from the [Contentful API](https://www.contentful.com/developers/docs/references/content-delivery-api/) with your Jekyll site.

## Installation

Add the following to your `Gemfile` and bundle...

```ruby
gem "jekyll-contentful", "~> 0.0.1", git: 'https://github.com/crdschurch/jekyll-contentful.git'
```

Note, in order to support Contentful environents, this project requires [v2.6.0](https://github.com/contentful/contentful.rb/releases/tag/v2.6.0) or greater of the [Contentful gem](http://rubygems.org/gems/contentful).

## Configuration

Define collections in `_config.yml` according to [the Jekyll documenation](https://jekyllrb.com/docs/collections/)...

```yml
collections_dir: collections
collections:
  authors:
    output: true
    permalink: /authors/:path
```

For each collection you want persisted from Contentful, define the `id`, `body` attributes and the frontmatter mappings in `_config.yml`, as shown below...

```yml
contentful:
  authors:
    id: author
    body: bio
    filename: '{{ first_name }}-{{ last_name }}'
    frontmatter:
      title: displayName
      images: images/url
```

The `id` attribute specifies the ID for the Contentful content-type you'd like to associate with this collection. The `body` attribute specifies which field from your content-type should populate the content of resulting Markdown file.

The `filename` attribute is a Liquid template that defines the value used when saving each document for this content-type (sans-filename, of course). This is handy if you need to format a string or date value in your filename, derived from your Contentful data. If the `filename` attribute is missing, it will first look for a `slug` field on the document and falls back to parameterizing the title field.

The `frontmatter` section defines what fields we want to map from Contentful into our document frontmatter. Each key/value pair defines the fields/values that map a field from Contentful's API. By default the key is the desired frontmatter key, while the value is the field name in Contentful. In the example above, we want the value for field named `displayName` to be rendered in the frontmatter value named `title`.

When the Contentful field is a reference, you can use a slash (`/`) to chain attributes together. (In the example above, `images` frontmatter will show the value for the `url` field for each associated image.)

An example of what might be rendered based on the above configuration, looks like this...

```yml
---
title: Walter Sobchak
images:
- //some/image.png
- //another/image.jpg
---

Body content here.
```

## Associations

This gem provides some utilities for setting up associations between your content models and a generator that will populate your collection pages with the associated objects. To use this feature, you need to specify the Contentful reference field name and what content models it is associated with under the `has_many` heading in `_config.yml`, like this...

```yml
contentful:
  articles:
    ...
  recipes:
    ...
  authors:
    has_many:
      contributions:
        - articles
        - recipes
```

When your site is built, the page object for every author will be prepopulated with that author's associated objects. You can access all of them in your templates, like so...

```
{{ page.associations.contributions }}
```

## Environment Variables

The following environment variables are required to run the script. Please make sure they are exported to the same scope in which your Jekyll commands are run.

| Name | Description | Default |
| ----- | ------ | ------- |
| `CONTENTFUL_ACCESS_TOKEN` | Access token for Contentful's Develivery or Preview API | |
| `CONTENTFUL_SPACE_ID` | ID specifying Contentful Space | |
| `CONTENTFUL_ENV` | Contentful environment | `master` |


## Usage

Once configured as described above, you can run the following Jekyll subcommand to persist content from the API to your local `collections/` directory.

```text
$ bundle exec jekyll contentful
```

You can limit the content returned from Contentful by specifying one or more collections on the command line, like so...

```
$ bundle exec jekyll contentful --collections articles,authors
```

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
