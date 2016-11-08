# Elasticsearch data cleaner

It is simple command line tool for cleaning old data inside Elasticsearch database

## Features

General feature is removing types inside indices. Yes it is rarely case but it can help for removing old data by types

## Configuration

For example you need to leave data for the last month, but you have some data which has big size and it doesn't necessary to store it for the whole month. We can remove it by type. Sure you can said that we can store this data in separated indices, but if we need to search information over all our data in Kibana we can't use separated indices.

here is example for this case
```
---
events-%Y.%m.%d:     # index pattern compatible ruby date format directives
  number: 7          # how many indices script have to keep by pattern above (an index per day)
  future: true       # leave indices with future timestamp. true by default
logstash-%Y.%m.%d:
  number: 31
  future: false
  types:             # types description
    elb:             # type name. there is no patterns
      number: 14
      optimize: true # run _optimize for index after removing this type.
                     # false by default
```

## Installing

from rubygems.org
```
gem install elasticsearch-data-cleaner
```
or
```
gem build elasticsearch-data-cleaner.gemspec
gem install elasticsearch-data-cleaner-<version>.gem
```

