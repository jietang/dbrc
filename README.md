DBRC Spec
=

The main concept we're using for DBRC are the idea of __remotes__ and __screens__. A remote is a device that sets up a broadcast, a screen can subscribe to one or more broadcasts to be controller by the remote. The API is very straightforward.

.
`/broadcasts`
=

POST
-
_create a new broadcast channel_

data: nothing

response: `broadcast_id`

.
`/broadcasts/<int:broadcast_id>`
=

POST
-
_post something to a broadcast channel_

data: the information you would like to post as a JSON object

response: just a status code

.
`/broadcasts/<int:id>/screens`
=

GET
-
_get the list of screens subscribed to the broadcast_

data: nothing

response: list of `screen_id`s that are subscribed to this broadcast

POST
-
_subscribed a screen to a broadcast_

data: `{"screen_id": screen_id}`

response: (status code)

DELETE
-
_remove a screen from a broadcast_

data: `{"screen_id": screen_id}`

response: (status code)


.
`/screens`
=

POST
-
_create a new screen, and associate it with a unique device\_id_

data: `{"device_id": device_id}`

response: `broadcast_id`

.
`/screens/<int:screen_id>`
=

GET
-
_long poll: listen for a message_

data: `<optional> {"timeout": seconds}`

response: a JSON ball posted to `/broadcasts/<int:id>` by a remote

.
`/screens/<int:id>/broadcasts`
=

GET
-
_a list of all broadcast streams this screen is subscribed to_

data: nothing

response: list of `broadcast_id`s that this screen listens to

POST
-
_subscribe a screen to a broadcast_

data: `{"broadcast_id": broadcast_id}`

response: (status code)

DELETE
-
_remove a screen from a broadcast_

data: `{"broadcast_id": broadcast_id}`

response: (status code)