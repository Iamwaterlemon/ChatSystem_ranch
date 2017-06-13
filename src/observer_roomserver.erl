%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 一月 2016 9:38
%%%-------------------------------------------------------------------
-module(observer_roomserver).
-author("liuzixiang").

%% API
-export([process_info/0]).
-include("../include/common.hrl").

room_list(Num, List) ->
	Str = string:concat("room", integer_to_list(Num)),
	RoomAtom = list_to_atom(Str),
	case Num of
		1 ->
			List ++ [RoomAtom];
		_ ->
			room_list(Num - 1, List ++ [RoomAtom])
	end.

process_info() ->
	Fun = fun(Info, RoomAtom) ->
			timer:sleep(2000),
			error_logger:error_msg("The information for ~p  is  ~p~n", [RoomAtom, Info])
		  end,
	[Fun(erlang:process_info(erlang:whereis(RoomAtom)),  RoomAtom) || RoomAtom <- room_list(?ROOM_NUMBERS, [])].