# How to start the leaderboard server
This is how to start the leaderboard server.

  ./run.sh

This will start the server on localhost:3020.

# How to submit a new score
Here is an example of a JSON call to update "Willem"'s score.
The new score can be viewed on the leaderboard server. 

  curl -v -H "Accept: application/json" -H "Content-type: application/json" -XPOST http://localhost:3020/update_score -d '{"username":"Willem","password":"abcd","score":15,"kills":24,"lat":52.3,"long":3.9,"ping":"2013-03-28T09:49:00Z"}'
