# Flickr Photo Tag
#
# A Jekyll plug-in for embedding Flickr photos in your Liquid templates.
#
# Usage:
#
#   {% flickr_photo 1234567890 %}
#   {% flickr_photo 1234567890 "Large Square" %}
#
#   ... where 1234567890 is the Flickr photo ID, and "Large Square" is the size label, as defined here by Flickr:
#
#   http://www.flickr.com/services/api/flickr.photos.getSizes.html

#   Medium (~500px width) is the default.
#
# Requires a Flickr API key in _config.yml (where "flickr:" is defined on the root level):
#
#   flickr:
#     api_key: 21u3gj12kg34jh12gk3j4hg1k2j3h4g
#
# You can obtain a Flickr API key here: http://www.flickr.com/services/apps/create/
#
# Author: Chris Nunciato
# Source: http://github.com/cnunciato/jekyll-flickr

require 'nokogiri'
require 'typhoeus'
require 'shellwords'

module Jekyll

  class FlickrPhotoTag < Liquid::Tag

    @@cached = {} # Prevents multiple requests for the same photo

    @@err_text = "This photo or video is not available."
    @@err_uri_placeholder = "https://s.yimg.com/pw/images/photo_unavailable.gif"
    @@err_uri_link = "http://flickr.com"
    @@err_width = "400"
    @@err_height = "300"

    def initialize(tag_name, markup, tokens)
      super
      params = Shellwords.shellwords markup
      @photo = { :id => params[0], :size => params[1] || "Medium", :sizes => {}, :title => "", :caption => "", :url => "", :exif => {} }
    end

    def render(context)
        @api_key = context.registers[:site].config["flickr"]["api_key"]
        @photo.merge!(@@cached[photo_key] || get_photo)

        selected_size = @photo[:sizes][@photo[:size]]
        "<div class=\"photo-holder\" style=\"max-width:62.5em;\"><a href=\"#{@photo[:url]}\"><img class=\"photo pure-img\" src=\"#{selected_size[:source]}\" title=\"#{@photo[:title]}\"></a></div>"
    end

    def get_photo
        hydra = Typhoeus::Hydra.new

        urls_req = Typhoeus::Request.new("https://api.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=#{@api_key}&photo_id=#{@photo[:id]}")
        urls_req.on_complete do |resp|
            parsed = Nokogiri::XML(resp.body)
            parsed.css("rsp").each do |status|
            if status["stat"] == "ok" then # Check to make sure an OK status is returned
            parsed.css("size").each do |el|
                @photo[:sizes][el["label"]] = {
                    :width => el["width"],
                    :height => el["height"],
                    :source => el["source"],
                    :url => el["url"]
                }
            end
          else
            # Where a photo id is either not found or is marked as private
            @photo[:sizes][@photo[:size]] = {
                :width => @@err_width,
                :height => @@err_height,
                :source => @@err_uri_placeholder,
                :url => @@err_uri_placeholder
              }
          end
        end
      end

      info_req = Typhoeus::Request.new("https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=#{@api_key}&photo_id=#{@photo[:id]}")
      info_req.on_complete do |resp|
          parsed = Nokogiri::XML(resp.body)
          parsed.css("rsp").each do |status|
            if status["stat"] == "ok" then # Only parse if stat = 'ok'
              @photo[:title] = parsed.css("title").inner_text
              @photo[:caption] = parsed.css("description").inner_text
              @photo[:url] = parsed.css("urls url").inner_text
            else
              @photo[:title] = @@err_text
              @photo[:caption] = @err_text
              @photo[:url] = @@err_uri_link
            end
        end
      end

        exif_req = Typhoeus::Request.new("https://api.flickr.com/services/rest/?method=flickr.photos.getExif&api_key=#{@api_key}&photo_id=#{@photo[:id]}")
        exif_req.on_complete do |resp|
            parsed = Nokogiri::XML(resp.body)
            parsed.css("exif").each do |el|
                @photo[:exif][el["label"]] = el.first_element_child.inner_text
            end
        end

        hydra.queue(urls_req)
        hydra.queue(info_req)
        hydra.queue(exif_req)
        hydra.run

        @@cached[photo_key] = @photo
    end

    def photo_key
        "#{@photo[:id]}"
    end

  end

end

Liquid::Template.register_tag('flickr_photo', Jekyll::FlickrPhotoTag)
