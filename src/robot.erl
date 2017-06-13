%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十二月 2015 10:53
%%%-------------------------------------------------------------------
-module(robot).
-author("liuzixiang").

%% API
-export([start_robot/2, start/2]).
-export([moving/2, speaking/1, sleeping/2, eating/2, do_something/2]).
-include("../include/common.hrl").
start_robot(FirstRobot, LastRobot) ->
	[spawn(fun() ->
		start(erlang:list_to_atom("robot" ++ erlang:integer_to_list(I)), 123) end) || I <- lists:seq(FirstRobot, LastRobot)],
	ok.

start(Name, Password) ->
	case gen_tcp:connect("localhost", 1234, [binary, {packet, 2}, {active, once}, {reuseaddr, true}]) of
		{ok, Socket} ->
			Data = erlang:list_to_binary([?KEY_USER_INFO, erlang:atom_to_list(Name), ":", erlang:integer_to_list(Password)]),
			case gen_tcp:send(Socket, Data) of
				ok ->
					Msg = <<?KEY_CHANNEL, ?CHANNEL_WORLD>>,
					gen_tcp:send(Socket, Msg),
					spawn_link(fun() -> robot:do_something(Socket, Name) end),
					recv_msg(Socket, Name);
				{error, Reason} ->
					erlang:exit(Reason)
			end;
		{error, Reason} ->
			io:format("closed reason by ~p~n", [Reason]),
			erlang:exit(Reason)
	end.

recv_msg(Socket, Name) ->
	receive
		{tcp, Socket, Data} ->
			case Name of
				robot1 ->
					io:format("server: ~p~n", [erlang:binary_to_list(Data)]);
				_Any ->
					ok
			end,
			Data,
			inet:setopts(Socket, [{active, once}]),
			recv_msg(Socket, Name);

		{tcp_closed, Socket} ->
			io:format("ERROR:~w", [Socket]),
			erlang:exit(cloded);

		_Any ->
			recv_msg(Socket, Name)
	end.


do_something(Socket, Name) ->
	random:seed(erlang:now()),
	WaitTime = random:uniform(2000),
	timer:sleep(WaitTime),
	Num  = random:uniform(2),
	Num1 = random:uniform(10),
	Num2 = random:uniform(60),
	if
		Num =:= 1 ->
			robot:moving(Socket, Name);
		true ->
			ok
	end,

	if
		Num1 =:= 5 ->
			robot:sleeping(Socket, Name);
		Num1 =:= 8 ->
			robot:eating(Socket, Name);
		true ->
			ok
	end,

	if
		Num2 =:= 10 ->
			robot:speaking(Socket);
		true ->
			ok
	end,
	do_something(Socket, Name).


moving(Socket, Name) ->
	WaitMoveTime = random:uniform(20),
	timer:sleep(WaitMoveTime * 100),
	case erlang:get(xy) of
		{X, Y} when erlang:is_integer(X) ->
			next;
		_ ->
			random:seed(erlang:now()),
			X = random:uniform(?BIG_SLICE_NUMBERS),
			Y = random:uniform(?BIG_SLICE_NUMBERS)
	end,
	{X2, Y2} = random_pos(X, Y),
	if
		X2 < 1 orelse Y2 < 1 orelse X2 > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS) orelse Y2 > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS) ->
			moving(Socket, Name);
		true ->
			Msg = <<?KEY_MOVING, X2, Y2>>,
			gen_tcp:send(Socket, Msg),
			erlang:put(xy, {X2, Y2})
	end.


random_pos(X, Y) ->
	N = random:uniform(8),
	{OffX, OffY} = erlang:element(N, {{-1, 0}, {0, 1}, {1, 0}, {0, -1}, {1, 1}, {-1, -1}, {-1, 1}, {1, -1}}),
	{X + OffX, Y + OffY}.

eating(Socket, Name) ->
	WaitEatTime = random:uniform(10),
	timer:sleep(WaitEatTime * 1000),
	Msg = erlang:list_to_binary([?KEY_EATING, erlang:atom_to_list(Name), <<" have eating food...">>]),
	gen_tcp:send(Socket, Msg).


sleeping(Socket, Name) ->
	WaitSleepTime = random:uniform(10),
	timer:sleep(WaitSleepTime * 1000),
	Msg = erlang:list_to_binary([?KEY_SLEEPING, erlang:atom_to_list(Name), <<" have sleeping....">>]),
	gen_tcp:send(Socket, Msg).


speaking(Socket) ->
	WaitSpeakTime = random:uniform(1000),
	timer:sleep(WaitSpeakTime),
	Msg = <<?KEY_PUBLIC_CHAT, "hello, I am a robot kimi!">>,
	gen_tcp:send(Socket, Msg).
