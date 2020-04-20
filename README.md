# Redmine image with `common_mark` format patch

[![Build Status](https://travis-ci.com/orchitech/docker-redmine-gfm.svg?branch=master)](https://travis-ci.com/orchitech/docker-redmine-gfm)

## Supported tags

- `4.1.1`, `4.1`, `4`, `latest`
- `4.1.1-passenger`, `4.1-passenger`, `4-passenger`, `passenger`
- `4.1.1-alpine`, `4.1-alpine`, `4-alpine`, `alpine`
- `4.0.7`, `4.0`
- `4.0.7-passenger`, `4.0-passenger`
- `4.0.7-alpine`, `4.0-alpine`

This project contains a simple Dockerfile based on
[the official Redmine image](https://hub.docker.com/_/redmine) and `common_mark` format patches.
The `common_mark` patches will be a part of the official Redmine (and its Docker images) since version 4.2.0.

The *CommonMark Markdown (GitHub Flavored)* formatter (identified as `common_mark`) is based on
[CommonMarker](https://github.com/gjtorikian/commonmarker) and [HTML::Pipeline](https://github.com/jch/html-pipeline).

## How to use this image

Exactly the same way as [the official Redmine image](https://hub.docker.com/_/redmine) :-)

## Why `common_mark` formatter?

The current Redmine version uses RedCarpet Markdown implementation which is going to be replaced with
`common_mark` for several reasons [[1]](https://www.redmine.org/issues/32424):

- From time to time users who are using the current Markdown formatter ask for a spec / formal list of all
  supported features. No such thing exists for RedCarpet. There is CommonMark but RedCarpet isn't going
  to support it in the short to medium term (see next point).
- The future development of RedCarpet is uncertain. Few excerpts from a GitHub issue, a year ago:
  > Commonmark won't be supported anytime soon

  and

  > A general message about the project for people skimming this thread: I'm sorry Redcarpet isn't really
  active anymore but my resources are pretty limited since I'm committed to other open source projects and
  still a student. Feel free to use any existing alternative ; this project isn't the great tool it used
  to be when it was maintained by Vicent.
- With CommonMark evolving as a Markdown spec that is supported by many implementations and endorsed by
  organizations like Gitlab and GitHub (which both did the switch from RedCarpet to CommonMarker a while
  ago), it quickly becomes what users expect when they hear 'Markdown'.
- Migrating existing Textile content is a bit easier since Pandoc has a dedicated Github Flavored
  Markdown writer module.
- The HTML pipeline approach encourages splitting up the formatting process into it's different aspects
  (html generation, sanitizing, syntax highlighting etc) which allows for better testability and has
  potential for future re-use of components with other text formatters. Further, HTML pipeline filters
  work on actual DOM nodes, making tasks like adding classes to links etc much more straight forward
  and less prone to bugs than doing so with regular expressions.

Last but not least, this formatter solves a number of currently open issues regarding the RedCarpet
based Markdown Formatter:
- [#19880](https://redmine.org/issues/19880) (Incorrect syntax for links in Markdown)
- [#20497](https://redmine.org/issues/20497) (Markdown formatting supporting HTML)
- [#20841](https://redmine.org/issues/20841) (Bare URLs in Markdown don't have "external" class)
- [#29172](https://redmine.org/issues/29172) (Markdown: External links broken)

## Included patches

- `0001-CommonMark-Markdown-text-formatter.patch` - The original patch by [Jens Krämer](https://github.com/jkraemer) which adds the `common_mark` formatter.
- `0002-attachments_helper-commonmark.patch` - Patch by [Martin Čížek](https://github.com/martincizek) for using `common_mark` formatter for rendering Markdown attachments.
- `0003-CommonMark-external_links_filter.rb.patch` - Incremental patch by [Martin Čížek](https://github.com/martincizek) to fix InvalidURIError exception for some inputs.

## Further notes

- As [Go MAEDA noted](https://www.redmine.org/issues/32424#note-7):
  > I agree that Redcarpet is not active anymore. The number of commits made in this year is only 3. And I
  think many Markdown users expect Redmine to behave as CommonMark/GFM compliant because many apps/services
  that support it.
  >
  > Let's start discussion to deliver this in 4.2.0.
- As [Martin Čížek noted](https://www.redmine.org/issues/32424#note-10):
  > Temporary workaround before the patch is merged
  At the moment, it is possible to use redmine_common_mark plugin. It also allows for configuring
  commonmarker, but it has no HTML sanitizing implemented. Actually I found this patch when I was about to
  offer a pull request with html-pipeline to the plugin's author.
  We’d still appreciate merging this patch ASAP.
- As [Martin Čížek noted](https://www.redmine.org/issues/32424#note-13):
  > Textile to Markdown migration
  Pandoc is actually bad at this job. We tried Jens'es redmine_convert_textile_to_markdown (thanks for that!),
  we ran rendering comparison tests1 covering hundreds of thousands of strings and the results were poor.
  1 Rendering comparison test = grab all rendered issues and wiki pages from the Textile Redmine instance
  and a converted-to-Markdown Redmine instance, normalize HTML, compare the HTMLs.
  >
  > So we forked it, and similarly to Jens, we were adding more and more preprocessors to make Pandoc happy
  and postprocessors to render it correctly. This is the latest version of the fork. Later, we reworked it
  completely to a new project, which we'll publish soon.
  >
  > But if we were doing it again, we would get rid of Pandoc completely. The preprocessing is done by partial
  rendering using code adapted from Redmine / Redcloth3. The amount of the code is comparable to normal
  rendering and invoking Pandoc just makes it slow.
  >
  > Pandoc is a great tool, but this use case is just too specific for a universal format converter.
  >
  > So the message is just: a good converter exists for Redmine. :)
- As [Mischa The Evil noted](https://www.redmine.org/issues/32424#note-16):
  > Hans Riekehof wrote in #note-15:
  [...] I know its always hard to say but is there any roadmap when this patch is available in an official release ?
  > 
  > Given all the parameters (size/scope/state/complexity of the patch, current Redmine release cycle, current issue
  scheduling) I'd say not earlier than before the end of 2020. However, this does not mean that it won't be
  available on the Redmine trunk earlier.

## References

[1]: [Issue "CommonMark Markdown Text Formatting"](https://www.redmine.org/issues/32424) by Jens Krämer
