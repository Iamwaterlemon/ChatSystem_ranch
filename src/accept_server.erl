%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十二月 2015 14:21
%%%-------------------------------------------------------------------
-module(accept_server).
-author("liuzixiang").

-behavior(gen_server).
-export([for_start/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-define(SERVER, ?MODULE).

%% API
for_start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []), do_accepting().
stop() -> gen_server:call(?MODULE, stop).

init([]) ->
	case gen_tcp:listen(1234, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]) of
		{ok, LSocket} ->
			io:format("listen success!"),
			{ok, {ok, LSocket}};
		{error, Reason} ->
			{stop, exit(Reason)}
	end.

handle_call(stop, _From, LSocket) -> {stop, normal, stopped, LSocket}.

%handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.


do_accepting() -> gen_server:cast(?MODULE, {accept}).

handle_cast({accept}, {ok, LSocket}) ->
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	spawn_link(fun() -> spawn_accept(LSocket, 0) end),
	{noreply, {ok, LSocket}}.

spawn_accept(LSocket, ClientNumbers) ->
	{ok, Socket} = gen_tcp:accept(LSocket),
	%%这里可以创建多个进程来accept
	spawn(fun() -> client_server:start(Socket) end),
	io:format("connected client: ~p~n", [ClientNumbers]),
	spawn_accept(LSocket, ClientNumbers + 1).
