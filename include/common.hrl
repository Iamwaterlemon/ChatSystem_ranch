%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十二月 2015 19:34
%%%-------------------------------------------------------------------
-author("liuzixiang").
-ifndef(COMMON_HRL).

-define(ROOM_NUMBERS, 3).
-define(BIG_SLICE_NUMBERS, 10).
-define(LITTLE_SLICE_NUMBERS, 5).
-define(SLICE_MAX_HUMAN, 20).

-define(KEY_PRIVATE_CHAT, 0).
-define(KEY_PUBLIC_CHAT, 1).
-define(KEY_EATING, 2).
-define(KEY_MOVING, 3).
-define(KEY_SLEEPING, 4).
-define(KEY_CHANNEL, 5).
-define(CHANNEL_WORLD, 6).
-define(CHANNEL_CHINA, 7).
-define(CHANNEL_ENGLAND, 8).
-define(CHANNEL_USA, 9).
-define(KEY_USER_INFO, 10).

-define(IS_VALID_POS(X, Y), ((X) < 1 orelse (Y) < 1 orelse (X) > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS) orelse (Y) > (?BIG_SLICE_NUMBERS * ?LITTLE_SLICE_NUMBERS)))

-define(COMMON_HRL, true).

-endif.