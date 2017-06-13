%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 十二月 2015 16:15
%%%-------------------------------------------------------------------
-module(room_map).
-author("liuzixiang").
-include("../include/common.hrl").

-record(role_info, {position, room_id, socket}).
%% API
-export([map_init/1, broadcast/3, slice_in/3, slice_out/2, do_something/2, slice_leave/3]).

map_init(Num) ->
	TB = lists:seq(1, ?BIG_SLICE_NUMBERS),
	BigSlice = fun(BigX) ->
		lists:foreach(fun(BigY) -> erlang:put({big_slice, BigX, BigY}, []) end, TB)
			   end,
	lists:foreach(BigSlice, TB),

	TL = lists:seq(1, Num),
	LittleSlice = fun(X) ->
		lists:foreach(fun(Y) -> loop_big_slice_y(X, Y, 1, 1) end, TL)
				  end,
	lists:foreach(LittleSlice, TL).

loop_big_slice_y(X, Y, TimeX, TimeY) ->
	if
		Y =< (TimeY * ?LITTLE_SLICE_NUMBERS) ->
			loop_big_slice_x(X, Y, TimeX, TimeY);
		true ->
			if
				TimeY =< ?BIG_SLICE_NUMBERS ->
					loop_big_slice_y(X, Y, TimeX, (TimeY + 1));
				true -> ok
			end
	end.

loop_big_slice_x(X, Y, TimeX, TimeY) ->
	if
		X =< (TimeX * ?LITTLE_SLICE_NUMBERS) ->
			erlang:put({slice, X, Y}, {TimeX, TimeY});

		true ->
			if
				TimeX =< ?BIG_SLICE_NUMBERS ->
					loop_big_slice_x(X, Y, (TimeX + 1), TimeY);
				true -> ok
			end
	end.


broadcast(BigX, BigY, Msg) ->
	[begin get_list(X, Y, Msg) end || X <- [BigX - 1, BigX, BigX + 1], Y <- [BigY - 1, BigY, BigY + 1]].


get_list(BigX, BigY, Msg) ->
	List = erlang:get({big_slice, BigX, BigY}),
	%io:format("big_slice:~p~n", [List]),
	if
		List =:= undefined -> [];
		true ->
			SendMsg = fun(Name) ->
				{_, {_, _}, _, Socket} = erlang:get(Name),
				gen_tcp:send(Socket, Msg)
					  end,
			lists:foreach(SendMsg, List)
	end.

slice_in(X, Y, {Name, RoomAtom, Socket}) ->
	{BigX, BigY} = erlang:get({slice, X, Y}),

	put(Name, #role_info{position = {BigX, BigY}, room_id = RoomAtom, socket = Socket}),
	ListUser = erlang:get({big_slice, BigX, BigY}),

	if
		erlang:length(ListUser) < ?SLICE_MAX_HUMAN ->
			erlang:put({big_slice, BigX, BigY}, lists:append(ListUser, [Name]));

		true -> {error, failed}
	end.


slice_out(Name, Msg) ->
	{_, {BigX, BigY}, _, _} = erlang:get(Name),
	broadcast(BigX, BigY, Msg),
	ListUser = erlang:get({big_slice, BigX, BigY}),
	put({big_slice, BigX, BigY}, lists:delete(Name, ListUser)).

slice_leave(X, Y, Name) ->
	{BigX, BigY} = erlang:get({slice, X, Y}),
	{_, {RealBigX, RealBigY}, _, _} = erlang:get(Name),
	if
		(BigX =:= RealBigX) and (BigY =:= RealBigY) -> false;
		true -> true
	end.

do_something(Name, Msg) ->
	{_, {BigX, BigY}, _, _} = erlang:get(Name),
	broadcast(BigX, BigY, Msg).




