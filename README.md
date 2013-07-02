# css_sprite

[![Build Status](https://secure.travis-ci.org/flyerhzm/css_sprite.png)](http://travis-ci.org/flyerhzm/css_sprite)
[![Coverage Status](https://coveralls.io/repos/flyerhzm/css_sprite/badge.png?branch=master)](https://coveralls.io/r/flyerhzm/css_sprite)
[![Dependency Status](https://gemnasium.com/flyerhzm/css_sprite.png)](https://gemnasium.com/flyerhzm/css_sprite)
[![Coderwall Endorse](http://api.coderwall.com/flyerhzm/endorsecount.png)](http://coderwall.com/flyerhzm)

automatically css sprite.

## Best Practices

I have written posts “css sprite best practices” to introduce the idea that the css_sprite gem follows.
[english version](http://huangzhimin.com/2010/04/03/css-sprite-best-practices-english-version)
[chinese version](http://huangzhimin.com/2010/04/02/css-sprite-best-practices-chinese-version)

otaviofcs wrote a brazilian version to introduce the css_sprite gem,
check it [here](http://blog.riopro.com.br/2010/04/22/acabaram-as-desculpas-para-nao-usar-css-sprite-na-sua-aplicacao/)
and he also build a demo(http://github.com/riopro/css_sprite_demo)

## What css_sprite does?

css sprite generates css\_sprite image and css files automatically for you follow the conventions as follows.

  ------------------------------------ -------------------------------
  images under css\_sprite directory   class name in css\_sprite css
  twitter\_icon.png                    .twitter\_icon
  facebook\_icon.png                   .facebook\_icon
  hotmail-logo.png                     .hotmail-logo
  gmail-logo.png                       .gmail-logo
  icons/twitter\_icon.png              .icons .twitter\_icon
  widget/icons/twitter\_icon.png       .widget .icons .twitter\_icon
  twitter\_icon\_hover.png             .twitter\_icon:hover
  twitter-icon-hover.png               .twitter-icon:hover
  logos\_hover/gmail\_logo.png         .logos:hover .gmail\_logo
  logos-hover/gmail-logo.png           .logos:hover .gmail-logo
  gmail\_logo\_active.png              .gmail\_logo.active
  gmail-logo-active.png                .gmail-logo.active
  logos\_active/gmail\_logo.png        .logos.active .gmail\_logo
  logos-active/gmail-logo.png          .logos.active .gmail-logo
  ------------------------------------ -------------------------------

css_sprite directory is the directory whose name is "css_sprite" or "css_sprite" suffixed under public/images directory.
css_sprite image is the image file automatically generated under public/images directory.
css_sprite css is the css file automatically generated under public/stylesheets directory.


## Install

css_sprite depends on the `mini_magick` gem

css_sprite also depends on the `optipng` tool as default image optimization, but you can use any other image optimization tool, check the Configuration section. If you use the default optipng tool, please make sure it is successfully installed on your system.

install css_sprite as a gem:

    gem install css_sprite

## Usage

1\. create a directory whose name is css_sprite or ends with css_sprite (e.g. widget_css_sprite) under `app/assets/images` directory

2\. if you css_sprite in rails2 projects, you should add css_sprite task in Rakefile

    require 'css_sprite'

If you use rails3, you can skip this step too

3\. define `config/css_sprite.yml`, it is not necessary by default.

4\. start css_sprite server

    rake css_sprite:start

5\. put any images which you need to do the css sprite under the css_sprite directory, then you will see the automatically generated css sprite image and css files.

6\. include the stylesheet in your view page

    <%= stylesheet_link_tag 'css_sprite' %>

You can stop the css_sprite server by `rake css_sprite:stop`

You can restart the css_sprite server by `rake css_sprite:start`

Or you can just do the css sprite manually by `rake css_sprite:build`

## Configuration

There is no need to do any configurations by default for Rails 3.1 or higher projects. If you want some customizations as follows, you need to define `config/css_sprite.yml` file.

### Example for rails 2.x or 3.0

    engine: css
    image_path: public/images
    stylesheet_path: public/stylesheets
    css_images_path: images

### Destination Image Format

css_sprite saves the css sprite image as a png file by default. You can change it to gif or any other format like

    format: GIF

### Use asset-url

css_sprite generate `background: url('css_sprite.png') no-repeat` by default, if you prefer `background: asset-url('css_sprite.png') no-repeat`, you can change it as follows

    use_asset_url: true

### Sass

css_sprite generates css.scss file by default. You can change it to pure css or sass as you like.

    engine: css

    engine: css.sass

### Image Optimization

css_sprite allows to do optimization to generated css_sprite.png, you can use default **optipng** with optimization level 2.

    optimization: true

Or you can change it to any image optimization command.

    optimization: optipng -o 7

### Customization styles

* For css or scss

    suffix:
      button: |
        text-indent: -9999px;
        display: block;
        cursor: pointer;
        font-size: 0;
        line-height: 15px;
        border: 0;
        outline: 0;
      icon: |
        text-indent: -9999px;
        cursor: pointer;

* For sass

    engine: sass
    suffix:
      button: |
        text-indent: -9999px
        display: block
        cursor: pointer
        font-size: 0
        line-height: 15px
        border: 0
        outline: 0
      icon: |
        text-indent: -9999px
        cursor: pointer

`engine` defines css.scss (default), pure css or sass file to generate.
`suffix` defines the customization styles for specified images.
The customization above means if your image filename is button suffixed (e.g. post_button.png), the corresponding class .post_button has the additional style with (outline: 0; border: 0; and so on),
if your image filename is icon suffixed (e.g. twitter_icon.png), the correspondiing class .twitter_icon has the additional style with (text-indent: -9999px; cursor: pointer)

### Customization directories

css_sprite follows the conventions that images are under
<code>app/assets/images</code> directory and css files are under
`app/assets/stylesheets`, but you can change them.

    image_path: public/images
    stylesheet_path: public/stylesheets

By default, image_path is `app/assets/images` and stylesheet_path is
`app/assets/stylesheets`.

## Example

I built an example

images are under `app/assets/images/css_sprite/`
generated css sprite image is at `>app/assets/images/css_sprite.png`
genereated css file is at `app/assets/stylesheets/css_sprite.css`

    $ cd example
    $ rake css_sprite:build
    $ open index.html


Copyright (c) 2009 - 2013 [Richard Huang] (flyerhzm@gmail.com), released under the MIT license
