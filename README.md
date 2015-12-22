# hubot-redisred

A script that allows users to make redisred links through hubot.

See [`src/redisred.coffee`][redisred] for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-redisred --save`

Then add **hubot-redisred** to your `external-scripts.json`:

```json
[
  "hubot-redisred"
]
```

Set the following environment variables to interact with redisred:

- `HUBOT_REDISRED_URL` The base URL for redirects, not including the API path.
  - e.g. `https://go.hackmit.org`
- `HUBOT_REDISRED_TOKEN` The redisred API token.
- `HUBOT_REDISRED_PREFIX` The prefix to auto-expand links
  - e.g. `go` here will expand the chat message `go/redisred` into `https://go.hackmit.org/redisred`

## License

Copyright (c) 2015 Jack Serrino. Released under the MIT License. See
[LICENSE.md][license] for details.

[redisred]: src/redisred.coffee
[license]: LICENSE.md
