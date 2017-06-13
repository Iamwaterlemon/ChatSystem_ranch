%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 十二月 2015 15:19
%%%-------------------------------------------------------------------
-module(room_manager_server).
-author("liuzixiang").
-include("../include/common.hrl").
%% API
-export([start_room/0, stop/0]).
%-import(room_server, [start/0, get_in_room/3, eating/1, sleeping/1, moving/1]).
-export([enter_room/2]).

-behavior(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-define(SERVER, ?MODULE).

%% API
start_room() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop() -> gen_server:call(?MODULE, stop).
init([]) ->
	Tid = ets:new(?MODULE, []),
	create_room(?ROOM_NUMBERS, Tid),
	{ok, Tid}.

create_room(Num, Tid) ->
	Str = string:concat("room", integer_to_list(Num)),
	RoomAtom = list_to_atom(Str),
	ets:insert(Tid, {Num, RoomAtom}),
	room_server:start(RoomAtom),
	if
		Num =:= 1 -> {ok, Num};
		true -> create_room(Num - 1, Tid)
	end.

enter_room(Name, Socket) -> gen_server:call(?MODULE, {enter_room, Name, Socket}).

handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
handle_cast(_Msg, State) -> {noreply, State}.

handle_call(stop, _From, Tid) -> {stop, normal, stopped, Tid};

handle_call({enter_room, Name, Socket}, _From, Tid) ->
	%产生1到50的随机数
	random:seed(erlang:now()),
	N = random:uniform(?ROOM_NUMBERS),
	Reply = case ets:lookup(Tid, N) of
				[{_, RoomAtom}] ->
					erlang:send(RoomAtom, {get_in_room, Name, RoomAtom, Socket}),
					RoomAtom;
				[] ->
					io:format("enter_room failed!~n"), error
			end,
	{reply, Reply, Tid}.








