%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 十二月 2015 11:13
%%%-------------------------------------------------------------------
-module(room_server).
-author("liuzixiang").

%% API
-behavior(gen_server).
-export([start/1, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-define(SERVER, ?MODULE).
-include("../include/common.hrl").

%% API
start(RoomAtom) -> gen_server:start_link({local, RoomAtom}, ?MODULE, [], []).
stop() -> gen_server:call(?MODULE, stop).

init([]) -> {ok, room_map:map_init((?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS))}.

%handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
handle_call(stop, _From, Pid) -> {stop, normal, stopped, Pid}.

handle_cast(_Msg, State) -> {noreply, State}.

loop_slice_in(Name, RoomAtom, Socket) ->
	random:seed(erlang:now()),
	X = random:uniform(?BIG_SLICE_NUMBERS),
	Y = random:uniform(?BIG_SLICE_NUMBERS),
	case room_map:slice_in(X, Y, {Name, RoomAtom, Socket}) of
		{error, failed} ->
			loop_slice_in(Name, RoomAtom, Socket);

		Any -> Any
	end.

handle_info({get_in_room, Name, RoomAtom, Socket}, Pid) ->
	loop_slice_in(Name, RoomAtom, Socket),
	{noreply, Pid};


handle_info({get_out_room, Name}, Pid) ->
	Msg = erlang:list_to_binary(["get out the room"]),
	room_map:slice_out(Name, Msg),
	erlang:erase(Name),
	{noreply, Pid};

handle_info({eating, Name, Msg}, Pid) ->
	room_map:do_something(Name, Msg),
	% io:format("测试机器人~p正在吃饭", [Name]),
	{noreply, Pid};

handle_info({sleeping, Name, Msg}, Pid) ->
	room_map:do_something(Name, Msg),
	%io:format("测试机器人~p正在睡觉", [Name]),
	{noreply, Pid};

handle_info({moving, Name, {X, Y, RoomAtom, Socket}}, Pid) ->
	if
		X < 1 orelse Y < 1 orelse X > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS) orelse Y > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS) ->
			error;
		true ->
			case room_map:slice_leave(X, Y, Name) of
				true ->
					OutMsg = erlang:list_to_binary([Name, <<" will get out of here...">>]),
					room_map:slice_out(Name, OutMsg),
					case room_map:slice_in(X, Y, {Name, RoomAtom, Socket}) of
						{error, failed} -> room_map:slice_in(X + 1, Y, {Name, RoomAtom, Socket});
						Any -> Any
					end,
					InMsg = erlang:list_to_binary([Name, <<" go to ">>, erlang:integer_to_list(X), <<", ">>, erlang:integer_to_list(Y)]),
					room_map:do_something(Name, InMsg);

				false ->
					Msg = erlang:list_to_binary([Name, <<" didn't leave big_slice, go to ">>, erlang:integer_to_list(X), <<", ">>, erlang:integer_to_list(Y)]),
					room_map:do_something(Name, Msg)
			end
	%   io:format("测试机器人~p正在走路", [Name])
	end,
	{noreply, Pid}.




