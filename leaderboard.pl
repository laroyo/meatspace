:- module(meatspace, [ score/11 ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).
:- use_module(library(http/html_head)).
:- use_module(library(http/http_parameters)).	 % new
:- use_module(library(uri)).			 % new
:- use_module(library(persistency)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/json)).

:- persistent name(id:atom, name:atom).
:- persistent update(update:atom, latitude:atom, longitude:atom).
:- persistent start_stop(id:atom, onoff:atom, time:integer).
:- persistent cur_score(id:atom, score:integer, time:integer).


:- http_handler(root(.), leaderboard2, []). % /
:- http_handler(root(meatspace), meatspace, []).
:- http_handler(root(update_score), update_score, []).


:- http_handler(css('visualize-light.css'), http_reply_file('css/visualize-light.css', []), []).
:- http_handler(css('visualize.css'), http_reply_file('css/visualize.css', []), []).
:- http_handler(css('basics.css'), http_reply_file('css/basics.css', []), []).

:- http_handler(js('enhance.js'), http_reply_file('js/enhance.js', []), []).
:- http_handler(js('excanvas.js'), http_reply_file('js/excanvas.js', []), []).
:- http_handler(js('jquery.min.js'), http_reply_file('js/jquery.min.js', []), []).
:- http_handler(js('visualize.jQuery.js'), http_reply_file('js/visualize.jQuery.js', []), []).
:- http_handler(js('mint.js'), http_reply_file('js/mint.js', []), []).
:- http_handler(js('example.js'), http_reply_file('js/example.js', []), []).

http:location(css, root(css), []).
http:location(js, root(js), []).

:- persistent score(username:atom, password:atom, score:integer, kills:integer, died:integer, highscore:integer, lat:float, long:float, ping:atom, offline_time:integer, online_time:integer).

:- db_attach(meatspace_leaderboard,flush).


server(Port) :-
	http_server(http_dispatch, [port(Port)]).

/*
:- persistent name(id:atom, name:atom).
:- persistent update(update:atom, latitude:atom, longitude:atom).
:- persistent start_stop(id:atom, onoff:atom, time:integer).
:- persistent cur_score(id:atom, score:integer, time:integer).
*/


leaderboard2(Request) :-
        http_parameters(Request,
                        [ id(ID, [ optional(false) ])
                        ]),
	(   start_stop(ID,start,_)
	->  calculate_stop_time(ID,Score,Time)
	;   calculate_start_time(ID,Score,Time)
	),
	findall(ScoreX-NameX,
	        (   name(IDX,NameX),
	            cur_score(IDX,ScoreX,_TimeX)
		),
                List),
	keysort(List,Ranking),
	reverse(Ranking,Rankingrev),
	pairs_values(Rankingrev,Leaderboard),
	reply_html_page([],
        		[ title('Meatspace leaderboard')
			],
	                [ table([ caption('Meatspace leaderboard'),
                                  \header2
			        | \leaderboard2(Leaderboard)
			        ])]).

header2 -->
	html(thead(
                 tr([th([scope=col],['Name']),
                     th([scope=col],['Score'])
                 ]))).

leaderboard2([]) --> [].
leaderboard2([Name-Score|T]) -->
	html(tbody([tr([th([scope=row],[Name]),td(Score)])])),
	leaderboard2(T).




leaderboard(_Request) :-
	findall(Highscore-score(User,Pass,Score,Kills,Died,Highscore,Lat,Long,Ping,Offline,Online),
	        score(User,Pass,Score,Kills,Died,Highscore,Lat,Long,Ping,Offline,Online),
			List),
	keysort(List,Ranking),
	reverse(Ranking,Rankingrev),
	pairs_values(Rankingrev,Leaderboard),
	reply_html_page([],
                        [ 
%			  \html_requires(css('visualize.css')),
%			  \html_requires(css('basics.css')),
%			  \html_requires(css('visualize-light.css')),
%			  \html_requires(js('enhance.js')),
%			  \html_requires(js('excanvas.js')),
%			  \html_requires(js('jquery.min.js')),
%			  \html_requires(js('visualize.jQuery.js')),
%			  \html_requires(js('mint.js')),
                          title('Meatspace leaderboard')
			],
	                [ table([ caption('Meatspace leaderboard'),
                                  \header
			        | \leaderboard(Leaderboard)
			        ])
%			  script('$(function(){ $(\'table\').visualize({type: \'bar\', width: \'420px\'}); }); ')
			]).

header -->
	html(thead(
                 tr([th([scope=col],['Name']),
                 th([scope=col],['Score']),
                 th([scope=col],['Kills']),
                 th([scope=col],['Died']),
                 th([scope=col],['High score']),
                 th([scope=col],['Last play time']),
                 th([scope=col],['Meatspace time']),
                 th([scope=col],['Cyperspace time'])]))).

leaderboard([]) --> [].
leaderboard([score(User,_Pass,Score,Kills,Died,Highscore,_Lat,_Long,Ping,Offline,Online)|T]) -->
	html(tbody([tr([th([scope=row],[User]),td(Score),td(Kills),td(Died),td(Highscore),td(Ping),td(Offline),td(Online)])])),
	leaderboard(T).


meatspace(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, Term),
	process(Term).

process(json([ id=ID, action=name, name=Name ])) :-
	retractall_name(ID,_),
	assert_name(ID,Name).

process(json([ id=ID, action=update, latitude=Latitude, longitude=Longitude ])) :-
	retractall_update(ID,_),
	assert_update(ID,Latitude,Longitude).

/*

:- persistent name(id:atom, name:atom).
:- persistent update(update:atom, latitude:atom, longitude:atom).
:- persistent start_stop(id:atom, startstop:atom).
:- persistent cur_score(id:atom, score:integer, time:integer).
*/
process(json([ id=ID, action=start ])) :-
	calculate_start_time(ID,Score,Time),
	retractall_cur_score(ID,_,_),
	assert_cur_score(ID,Score,Time),
	retractall_start_stop(ID,_,_),
	assert_start_stop(ID,start,Time).

process(json([ id=ID, action=stop])) :-
	calculate_stop_time(ID,Score,Time),
	retractall_cur_score(ID,_,_),
	assert_cur_score(ID,Score,Time),
	retractall_start_stop(ID,_,_),
	assert_start_stop(ID,stop,Time).

calculate_start_time(ID,Score,EpochSeconds) :-
	get_time(T),
	EpochSeconds is integer(T),
	(   cur_score(ID,BufScore,BufTime)
        ->  true
	;   BufScore = 0, 
            BufTime = EpochSeconds
	),
	Score is BufScore + EpochSeconds - BufTime.

alpha(2).

calculate_stop_time(ID,Score,EpochSeconds) :-
	get_time(T),
	EpochSeconds is integer(T),
	(   cur_score(ID,BufScore,BufTime)
        ->  true
	;   BufScore = 0, 
            BufTime = EpochSeconds
	),
	alpha(A),
	Score is BufScore - (A * (EpochSeconds - BufTime)).



update_score(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, Term),
        Term = json(Params),
	memberchk(username=Name,Params),
	memberchk(password=Pass,Params),
	memberchk(score=Score,Params),
	memberchk(kills=Kills,Params),
	memberchk(died=Died,Params),
	memberchk(lat=Lat,Params),
	memberchk(long=Long,Params),
	memberchk(ping=Ping,Params),
	memberchk(online_time=Offline,Params),
	memberchk(offline_time=Online,Params),
        (   score(Name,_,_,_,_,OldHighscore,_,_,_,_,_)
        ->  retractall_score(Name,_,_,_,_,_,_,_,_,_,_),
            (   OldHighscore < Score
	    ->  NewHighscore = Score
	    ;   NewHighscore = OldHighscore
            ),
	    assert_score(Name,Pass,Score,Kills,Died,NewHighscore,Lat,Long,Ping,Offline,Online)
	;   NewHighscore = Score,
            assert_score(Name,Pass,Score,Kills,Died,NewHighscore,Lat,Long,Ping,Offline,Online)
	)
        -> reply_json(json([ok=true, highscore=NewHighscore]))
	;  reply_json(json([ok=false])).


