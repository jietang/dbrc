DBRC Spec
=

I'm showing someone git!

The main concept we're using for DBRC are the idea of __remotes__ and __screens__. A remote is a device that sets up a broadcast, a screen can subscribe to one or more broadcasts to be controller by the remote. The API is very straightforward.

connection info refers to: `{'bssid': <bssid>, 'ssid': <ssid>, 'strength': <signal strength>}`

For pairing using remote.py you'll need to create a "~/.dbrc_config" file with the following sections:

[secrets]

APP_KEY="gafchy215r87od1"

APP_SECRET="0bhl35g2fcybyvh"

ACCESS_TOKEN=""

ACCESS_TOKEN_SECRET=""


.
`/broadcasts/`
=

POST
-
_create a new broadcast channel_

data: `{'remote_id': remote id, <optional>'connected': connection info}`

headers: `{'content-type': 'application/json'}`

response: `broadcast_id`

.
`/broadcasts/<int:broadcast_id>`
=

POST
-
_post something to a broadcast channel. returns list of screen_ids successfully published to (mostly for debug purposes).._

uses a message type. valid types: "pairing", "url"

pairing is for sending app token information to the TV, url is for putting an image url on a screen.

data: `json.dumps({"type": "url", "url": some_url})`

data: `json.dumps({"type": "pairing", "app_key": app_key, "app_secret": app_secret, "access_token": access_token, "access_token_secret": access_token_secret})`

headers: `{'content-type': 'application/json'}

response: `{'screen_ids': [screen_id1,...]}`

.
`/broadcasts/<int:id>/screens/`
=

GET
-
_get the list of screens subscribed to the broadcast_

data: nothing

response: `{"<screen_id>": <subscription_timestamp>, "<screen_id>", <subscription_timestamp>, ...}`


POST
-
_subscribe a screen to a broadcast_

data: `{"screen_id": screen_id}`

response: `<status code>`

.
`/broadcasts/<int:broadcast_id>/screens/<int:screen_id>`
=

DELETE
-
_remove a screen from a broadcast_

data: nothing

response: `{"broadcast_id": broadcast_id, "screen_id": screen_id}`


.
`/broadcasts/<int:id>/known_screens/`
=

GET
-
_get a list of screens have previously paired with the remote that created this broadcast. known is True/False, depending on whether we have explicitly paired with this device in the past._

data: nothing

response: `[{"screen_id": screen_id, "device_name": device_name, "known": True/False}, ...]`


POST
-
_subscribe a screen to a broadcast_

data: `{"screen_id": screen_id}`

response: `<status code>`

.
`/screens`
=

POST
-
_create a new screen, and associate it with a unique device\_id_

data: `{"device_id": device_id, "device_name": device_name,

<optional> "pairing_info": {"connected": connection info, "nearby": [... connection info]}}`

headers: `{"content-type": "application/json"}`

response: `{"broadcast_id": broadcast_id}`

.
`/screens/<int:screen_id>`
=

GET
-
_long poll: listen for a message_

data: `<optional> {"timeout": seconds}`

response: a (stringified) JSON ball posted to `/broadcasts/<int:id>` by a remote. right now, the json dict is guarenteed to have a "method_type" field set to "link" or "action"

.
`/screens/<int:id>/broadcasts`
=

GET
-
_gets all broadcast streams this screen is subscribed to_

data: nothing

response: `{"<broadcast_id>": <subscription_timestamp>, "<broadcast_id>", <subscription_timestamp>, ...}`

POST
-
_subscribe a screen to a broadcast_

data: `{"broadcast_id": broadcast_id}`

response: (status code)

.
`/screens/<int:screen_id>/broadcasts/<int:broadcast_id>`
=

DELETE
-
_remove a screen from a broadcast_

data: nothing

response: `{"broadcast_id": broadcast_id, "screen_id": screen_id}`
