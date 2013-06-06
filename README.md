speakup-ios
===========

A Seance client for iOS

When in the lobby (first screen):
- Even with no location, the connection to the server should be established
- When a new location is received (to be defined if it must be different from a previous locaiton), get rooms can be queried. 
Another solution could be to look for rooms every 5 sec.
- Location is use to show nearby rooms (rooms within 200m)
- Add a badge to indicate the number of new messages (or just messages) for each room
- Add a place where a room ID can be entered (or a room name?). Maybe a search field at the top.
- Let's create a World Room, where messages from around the world can be used
- The room creator should be able to delete a room, and rooms disappear after a certain time of inactivity 

Once in a room: 
- Location changes should not kick the user out of the room (due to false positive)
- Messages should disappear after a certain time
- Message creators should be able to delete messages
- Messages sorting should be persisted

When creating a message
- we could have an optional nickname field



