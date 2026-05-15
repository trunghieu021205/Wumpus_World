:- use_module(library(random)).
:- use_module(library(lists)).

% ====================== DYNAMIC PREDICATES ======================
:- dynamic agent_pos/2, facing/1, has_gold/0, has_arrow/0.
:- dynamic wumpus/2, pit/2, gold/2.
:- dynamic visited/2, sensed_stench/2, sensed_breeze/2.

% ====================== RANDOM WORLD ======================
generate_random_world :-
    retractall(wumpus(_,_)), retractall(gold(_,_)), retractall(pit(_,_)),
    findall((X,Y), (between(1,4,X), between(1,4,Y), \+ (X=1,Y=1)), Positions),
    my_random_select((WX,WY), Positions, Pos1), assert(wumpus(WX,WY)),
    my_random_select((GX,GY), Pos1, Pos2), assert(gold(GX,GY)),
    my_random_select_3(Pos2, PitList),
    forall(member((PX,PY), PitList), assert(pit(PX,PY))).

my_random_select(Elem, List, Rest) :-
    length(List, Len), random(0, Len, Index), nth0(Index, List, Elem),
    delete(List, Elem, Rest).

my_random_select_3(List, [A,B,C]) :-
    my_random_select(A, List, L1),
    my_random_select(B, L1, L2),
    my_random_select(C, L2, _).

% ====================== INIT ======================
init :-
    retractall(agent_pos(_, _)), assert(agent_pos(1,1)),
    retractall(facing(_)), assert(facing(east)),
    retractall(has_gold), retractall(has_arrow), assert(has_arrow),
    retractall(visited(_, _)), assert(visited(1,1)),
    retractall(sensed_stench(_, _)), retractall(sensed_breeze(_, _)),
    generate_random_world.

% ====================== ADJACENT & PERCEPTS ======================
adjacent((X,Y), (X2,Y2)) :-
    ( X2 = X, (Y2 =:= Y+1 ; Y2 =:= Y-1) ;
      Y2 = Y, (X2 =:= X+1 ; X2 =:= X-1) ),
    between(1,4,X2), between(1,4,Y2).

neighbor_wumpus(X,Y) :- wumpus(WX,WY), adjacent((X,Y), (WX,WY)).
neighbor_pit(X,Y) :- pit(PX,PY), adjacent((X,Y), (PX,PY)).

percept([Stench, Breeze, Glitter, no, no]) :-
    agent_pos(X,Y),
    (neighbor_wumpus(X,Y) -> Stench = yes ; Stench = no),
    (neighbor_pit(X,Y)    -> Breeze = yes ; Breeze = no),
    (gold(X,Y)            -> Glitter = yes ; Glitter = no).

tell_kb([Stench, Breeze, _, _, _]) :-  
    agent_pos(X,Y),
    assert(visited(X,Y)),
    (Stench = yes -> assert(sensed_stench(X,Y)) ; true),
    (Breeze = yes -> assert(sensed_breeze(X,Y)) ; true).

% ====================== SAFE ======================
safe(X,Y) :- \+ pit(X,Y), \+ wumpus(X,Y).

% ====================== MOVEMENT ======================
next_position(X, Y, east,  NX, Y) :- NX is X + 1.
next_position(X, Y, west,  NX, Y) :- NX is X - 1.
next_position(X, Y, north, X, NY) :- NY is Y + 1.
next_position(X, Y, south, X, NY) :- NY is Y - 1.

turn_left_dir(east, north).   turn_left_dir(north, west).
turn_left_dir(west, south).   turn_left_dir(south, east).
turn_right_dir(east, south).  turn_right_dir(south, west).
turn_right_dir(west, north).  turn_right_dir(north, east).

in_bounds(X,Y) :- between(1,4,X), between(1,4,Y).

% ====================== EXECUTE ======================
execute(forward) :-
    agent_pos(X,Y), facing(Dir),
    next_position(X, Y, Dir, NX, NY),
    in_bounds(NX, NY),
    retract(agent_pos(X,Y)),
    assert(agent_pos(NX, NY)),
    assert(visited(NX, NY)).

execute(turn_left) :-
    retract(facing(D)), turn_left_dir(D, NewD), assert(facing(NewD)).

execute(turn_right) :-
    retract(facing(D)), turn_right_dir(D, NewD), assert(facing(NewD)).

execute(grab) :-
    agent_pos(X,Y), gold(X,Y),
    retract(gold(X,Y)), assert(has_gold).

execute(climb) :- agent_pos(1,1), has_gold, !.

execute(shoot) :-
    has_arrow,
    agent_pos(X,Y), facing(Dir),
    next_position(X,Y,Dir,SX,SY),
    ( wumpus(SX,SY) ->
        retract(wumpus(SX,SY)),
        writeln('*** You killed the Wumpus! ***')
    ; true ),
    retract(has_arrow).

% ====================== BFS PATHFINDING ======================
plan_path(GoalX, GoalY, Actions) :-
    agent_pos(SX,SY), facing(SD),
    bfs_path(SX, SY, SD, GoalX, GoalY, Actions).

bfs_path(StartX, StartY, StartDir, GoalX, GoalY, Actions) :-
    bfs_queue([[StartX,StartY,StartDir,[], [(StartX,StartY,StartDir)]]], GoalX, GoalY, Actions).

bfs_queue([[X,Y,Dir,Hist,Visited]|_], GoalX, GoalY, Actions) :-
    X =:= GoalX, Y =:= GoalY, !, reverse(Hist, Actions).
bfs_queue([State|Queue], GoalX, GoalY, Actions) :-
    findall(Next, neighbor_state(State, Next), NextStates),
    append(Queue, NextStates, NewQueue),
    bfs_queue(NewQueue, GoalX, GoalY, Actions).

neighbor_state([X,Y,Dir,Hist,Visited], [NX,NY,NDir,[Action|Hist],NewVisited]) :-
    ( % tiến tới ô an toàn
      next_position(X,Y,Dir,NX,NY),
      in_bounds(NX,NY), safe(NX,NY),
      Action = forward, NDir = Dir,
      NewVisited = [(NX,NY,NDir)|Visited],
      \+ member((NX,NY,NDir), Visited)
    ; % xoay trái
      turn_left_dir(Dir, NDir),
      Action = turn_left,
      NewVisited = [(X,Y,NDir)|Visited],
      \+ member((X,Y,NDir), Visited),
      NX = X, NY = Y
    ; % xoay phải
      turn_right_dir(Dir, NDir),
      Action = turn_right,
      NewVisited = [(X,Y,NDir)|Visited],
      \+ member((X,Y,NDir), Visited),
      NX = X, NY = Y
    ).

% ====================== ASK ACTION (chiến lược thông minh) ======================
ask_action(climb) :- agent_pos(1,1), has_gold, !.
ask_action(grab)  :- agent_pos(X,Y), gold(X,Y), !.
ask_action(shoot) :-
    has_arrow,
    agent_pos(X,Y), facing(Dir),
    next_position(X,Y,Dir,SX,SY), in_bounds(SX,SY),
    wumpus(SX,SY), !.

% Nếu đang giữ vàng → tìm đường về hang
ask_action(Action) :-
    has_gold, !,
    ( plan_path(1,1, Path) -> Path = [Action|_]
    ; agent_pos(1,1) -> Action = climb
    ; writeln('*** Cannot find way home! ***'), fail
    ).

% Khám phá: tìm ô chưa thăm, an toàn, có thể đến được
ask_action(Action) :-
    findall((NX,NY), (in_bounds(NX,NY), safe(NX,NY), \+ visited(NX,NY)), Unvisited),
    Unvisited \= [],
    findall(Path, (member((GX,GY), Unvisited), plan_path(GX,GY, Path)), ReachablePaths),
    ReachablePaths \= [], !,
    random_member(Path, ReachablePaths),
    Path = [Action|_].

% Bế tắc hoàn toàn
ask_action(_) :-
    ( has_gold -> writeln('*** Stuck with gold, cannot reach home! ***')
    ; writeln('*** No safe unvisited cells and no gold! ***')
    ),
    fail.

% ====================== MAIN LOOP ======================
run :- init, agent_loop(0).

agent_loop(Step) :-
    Step > 100, !, writeln('*** Dừng sau 100 bước ***').

agent_loop(Step) :-
    percept(Percept),
    tell_kb(Percept),
    ask_action(Action),
    agent_pos(CurX, CurY), facing(CurDir),
    write('Step: '), write(Step),
    write(' | Pos: ('), write(CurX), write(','), write(CurY), write(')'),
    write(' | Facing: '), write(CurDir),
    write(' | Action: '), writeln(Action),
    ( catch(execute(Action), _, (writeln('Action failed!'), fail)) -> true
    ; true ),
    ( check_game_over -> true
    ; NextStep is Step + 1, agent_loop(NextStep) ).

check_game_over :-
    agent_pos(X,Y),
    (pit(X,Y) ; wumpus(X,Y)),
    writeln('Game Over!'), !.

check_game_over :-
    agent_pos(1,1), has_gold,
    writeln('*** WIN! +1000 ***'), !.