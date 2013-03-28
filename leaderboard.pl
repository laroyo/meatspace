:- module(meatspace, [ score/8 ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_parameters)).	 % new
:- use_module(library(uri)).			 % new
:- use_module(library(persistency)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/json)).

:- http_handler(root(.),           leaderboard, []). % /
:- http_handler(root(update_score),      update_score, []).


:- persistent score(username:atom, password:atom, score:integer, kills:integer, highscore:integer, lat:float, long:float, ping:atom).
:- db_attach(meatspace_leaderboard,flush).

%:- json_object score(username:atom, password:atom, score:integer, kills:integer, lat:float, long:float, ping:atom).

server(Port) :-
	http_server(http_dispatch, [port(Port)]).

leaderboard(_Request) :-
	findall(Highscore-score(User,Pass,Score,Kills,Highscore,Lat,Long,Ping),
	        score(User,Pass,Score,Kills,Highscore,Lat,Long,Ping),
			List),
	keysort(List,Ranking),
	reverse(Ranking,RankingRev),
	pairs_values(RankingRev,Leaderboard),
	reply_html_page(title('Meatspace leaderboard'),
	                [ h1('Meatspace leaderboard'),
					  table([ \header
					        | \leaderboard(Leaderboard)
							])
					]).

header -->
	html(tr([th('Name'),th('Score'),th('Kills'),th('High score'),th('Last play time')])).

leaderboard([]) --> [].
leaderboard([score(User,_Pass,Score,Kills,Highscore,_Lat,_Long,Ping)|T]) -->
	{ atom_number(ScoreAtom,Score), 
	  atom_number(KillsAtom,Kills)
        },
	html(tr([td(User),td(ScoreAtom),td(KillsAtom),td(Highscore),td(Ping)])),
	leaderboard(T).

update_score(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, Term),
        Term = json(Params),
	memberchk(username=Name,Params),
	memberchk(password=Pass,Params),
	memberchk(score=Score,Params),
	memberchk(kills=Kills,Params),
	memberchk(lat=Lat,Params),
	memberchk(long=Long,Params),
	memberchk(ping=Ping,Params),
        (   score(Name,_,_,_,OldHighscore,_,_,_)
        ->  retractall_score(Name,_,_,_,_,_,_,_),
            (   OldHighscore < Score
	    ->  NewHighscore = Score
	    ;   NewHighscore = OldHighscore
            ),
	    assert_score(Name,Pass,Score,Kills,NewHighscore,Lat,Long,Ping)
	;   NewHighscore = Score,
            assert_score(Name,Pass,Score,Kills,NewHighscore,Lat,Long,Ping)
	)
        -> reply_json(json([ok=true, highscore=NewHighscore]))
	;  reply_json(json([ok=false])).


