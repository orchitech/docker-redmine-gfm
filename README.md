<!--

********************************************************************************

WARNING:

    DO NOT EDIT "README.md"

    IT IS AUTO-GENERATED from files in "docs" directory

-->

# Supported tags

- `latest`, `4`, `4.2`, `4.2.9`, `4.2.8`, `4.2.7`, `4.2.6`, `4.2.5`, `4.2.4`, `4.2.3`, `4.2.2`, `4.2.1`, `4.2.0`
- `alpine`, `4-alpine`, `4.2-alpine`, `4.2.9-alpine`, `4.2.8-alpine`, `4.2.7-alpine`, `4.2.6-alpine`, `4.2.5-alpine`, `4.2.4-alpine`, `4.2.3-alpine`, `4.2.2-alpine`, `4.2.1-alpine`, `4.2.0-alpine`
- `passenger`, `4-passenger`, `4.2-passenger`, `4.2.9-passenger`, `4.2.8-passenger`, `4.2.7-passenger`, `4.2.6-passenger`, `4.2.5-passenger`, `4.2.4-passenger`, `4.2.3-passenger`, `4.2.2-passenger`, `4.2.1-passenger`, `4.2.0-passenger`

# Redmine image with CommonMark formating

[![Build Status](https://travis-ci.com/orchitech/docker-redmine-gfm.svg?branch=master)](https://travis-ci.com/orchitech/docker-redmine-gfm)

This project provides dockerized Redmine with the new CommonMark Markdown formatting variant, as thouroughly discusessed at the [corresponding patch](https://www.redmine.org/issues/32424).

The current Redmine Markdown formatter is based on a poorly maintained Markdown implementation with several functional and security issues. While the new implementation is ready, the merge & release process apparently takes a couple of years. That's why we offer this as an alternative until the new formatting is officialy implemented.

The provided Docker images build on [the official Redmine image](https://hub.docker.com/_/redmine) and provide:
- the CommonMark formatting patch
  - uses [CommonMarker](https://github.com/gjtorikian/commonmarker)
  - introduces [HTML::Pipeline](https://github.com/jch/html-pipeline), which should be later used for other formatters too ([#35035](https://www.redmine.org/issues/35035))
- a few fixes and improvements in the text formatting area:
  - [#35104](https://www.redmine.org/issues/35104) - consistent rendering of code blocks
  - [#32766](https://www.redmine.org/issues/32766) - remove unnecessary link target limitation

## How to use this image

Exactly the same way as [the official Redmine image](https://hub.docker.com/_/redmine).

## How to use the new formatter

Redmine installed from this image adds the *CommonMark Markdown (GitHub Flavored)* formatter, identified as `common_mark`. You can switch to it in Administration - Settings.

## Other addressed issues

Last but not least, this formatter solves a number of currently open issues regarding the RedCarpet based Markdown Formatter:
- [#19880](https://redmine.org/issues/19880) (Incorrect syntax for links in Markdown)
- [#20497](https://redmine.org/issues/20497) (Markdown formatting supporting HTML)
- [#20841](https://redmine.org/issues/20841) (Bare URLs in Markdown don't have "external" class)
- [#29172](https://redmine.org/issues/29172) (Markdown: External links broken)

## Related tools

The [redmine_reformat](https://github.com/orchitech/redmine_reformat) plugin
can help you with migrating your data both from Textile and the old
Redmine/Redcarpet Markdown format.
