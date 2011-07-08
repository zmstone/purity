-module(names).
-compile(export_all).

%< global [{test,with_nested}]

%%% Verify that the naming mechanism for nested functions works
%%% correctly. The actual pureness results are not important.

%% Verify that nested functions are named correctly without clashes
%% to the environment or previously named functions.
%% This should produce a_1-1/1 and a_2-1/1.
%< a/1 d
%< 'a_1-1'/1 d
a(L) ->
    [get(E) || E <- L].

%< a/2 d
%< 'a_2-1'/1 d
a(L, T) ->
    [get({E, T}) || E <- L].

%% This one would normally generate b_1-1/1 but since this function
%% is already defined, it will now create b_1-2/1.
%< b/1 p
%< 'b_1-2'/1 p
b(L) ->
    fun(E) -> [E|L] end.

%< 'b_1-1'/1 s
'b_1-1'(L) ->
    put(L,42).

