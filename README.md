jekyll-flickr
=============

A Jekyll plug-in for embedding Flickr photos in your Liquid templates.

### Usage:

    {% flickr_photo 1234567890 %}
    {% flickr_photo 1234567890 "Large Square" %}

  ... where 1234567890 is the Flickr photo ID, and "Large Square" is the size label [as defined here by Flickr](http://www.flickr.com/services/api/flickr.photos.getSizes.html).

  Medium (~500px width) is the default.

#### Requires an API Key

  The plug-in requires a Flickr API key in _config.yml (where "flickr:" is defined on the root level):

    flickr:
      api_key: kjh3g4kj1h2gkjh1gvbnvd7o1khmqjh2g3

  [Get your API key here](You can obtain a Flickr API key here: http://www.flickr.com/services/apps/create/).
  