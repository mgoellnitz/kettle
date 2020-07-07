# Kettle Script

[![License](https://img.shields.io/github/license/mgoellnitz/kettle.svg)](https://github.com/mgoellnitz/kettle/blob/master/LICENSE)
[![Build](https://img.shields.io/gitlab/pipeline/backendzeit/kettle.svg)](https://gitlab.com/backendzeit/kettle/pipelines)

Shell Script to remotely control a Wifi based water boiling kettle which I
eventually bought just because it might be fun.

## Feedback

This repository is available at [github][github] and [gitlab][gitlab]. Please 
prefer the [issues][issues] section of this repository at [gitlab][gitlab]
for feedback.

## Usage

```
W-LAN Kettle Command Line Tool - 'kettle.sh'

./kettle.sh [-k kettle] [-t temperature] [-w] [-s]

  -k ip-address or hostname of the kettle device

  -t target temperature in degree C (65, 80, 95, or 100)

  -w set keep warm flag

  -s switch kettle on or off
```

## Related Resources

This is a deliberate collection of repositories and documents which helped me:

* https://github.com/iamamoose/moosekettle
* https://awe.com/mark/blog/20140223.html
* https://github.com/nanab/smartercoffee

[issues]: https://gitlab.com/backendzeit/kettle/-/issues
[gitlab]: https://gitlab.com/backendzeit/kettle
[github]: https://github.com/mgoellnitz/kettle
