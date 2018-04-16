# jekyll-contentful

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
  content_types:
    authors:
      id: author
      body: bio
      filename: '{{ first_name }}-{{ last_name }}'
      frontmatter:
        entry_mappings:
          title: displayName
          image: avatar
        other:
          layout: author
          draft: false
```

The `id` attribute specifies the ID for the Contentful content-type you'd like to associate with this collection. The `body` attribute specifies which field from your content-type should populate the content of resulting Markdown file.

The `filename` attribute is a Liquid template that defines the value used when saving each document for this content-type (sans-filename, of course). This is handy if you need to format a string or date value in your filename, derived from your Contentful data.

The `frontmatter` section defines what fields we want to map from Contentful into our document frontmatter: `entry_mappings` is literally a list of target/src values that map a field from Contentful's API.  In the example above, we want the value for field named `displayName` to be rendered in the frontmatter value named `title`. The `other` section refers to additional attributes that you want hardcoded for each document.

An example of what might be rendered based on the above configuration, looks like this...

```yml
---
title: Walter Sobchak
image: https://some/image.png
layout: author
draft: false
---

Body content here.
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

```bash
$ bundle exec jekyll contentful
```

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).