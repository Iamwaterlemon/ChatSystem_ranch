%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(accept_server_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.

start(_Type, _Args) ->
    {ok, _} = ranch:start_listener(accept_server, 10,
		ranch_tcp, [{port, 1234}, {max_connections, 10240}], accept_server_protocol, []),
    accept_server_sup:start_link().

stop(_State) ->
	ok.
