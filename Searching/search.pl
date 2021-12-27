% Import Module and Consult the facts from other files.

:- use_module(library(csv)).
:- consult('fact.pl').
:- consult('fact2.pl').

% Welcome message and pre processing

start :- write("Welcome ! to the road route search portal"), nl, importRoadRoute, importRoadRoute1, write("Input command finc_route for a star and bfs_value for BFS search"), nl.

importRoadRoute:- csv_read_file('A.csv', Route, [functor(connectivity), arity = 3]), maplist(assert, Route), write_file("fact.pl",Route).
importRoadRoute1:- csv_read_file('A2.csv', Route1, [functor(coordinates), arity = 3]), maplist(assert, Route1), write_file("fact2.pl",Route1).

% List Data from the list and put in a file

data_list(File, List) :- member(Element, List), write(File, Element), write(File, '.'), fail.
write_file(Filename,List) :- open(Filename, write, File), \+ data_list(File, List), close(File).

% A star Serach techniques

a_star(Routes, Route) :- best_route(Routes, Route), Route = [City|_]/_/_ , target(City).
a_star(Routes, TargetRoute) :- best_route(Routes, BestRoute), select(BestRoute, Routes, OtherRoutes), explore_route(BestRoute, ExpectedRoute), append(OtherRoutes, ExpectedRoute, NewRoutes), a_star(NewRoutes, TargetRoute).

% Finding the best route based on the hueristic and the distance

best_route([Route], Route) :- !.  
best_route([Path1/Cost1/EstimatedCost1,_/Cost2/EstimatedCost2|Routes], BestRoute) :- Cost1 + EstimatedCost1 =< Cost2 + EstimatedCost2, !, best_route([Path1/Cost1/EstimatedCost1|Routes], BestRoute).
best_route([_|Routes], BestRoute) :- best_route(Routes, BestRoute). 

% Find all the route using findall and explore all then connected route

explore_route(Route, ExpectedRoute) :- findall(NewRoute, next_move(Route,NewRoute), ExpectedRoute).
next_move([City|Route]/Cost/_, [NextCity,City|Route]/NewCost/Estimated) :-  move(City, NextCity, StepCost), \+ member(NextCity, Route), NewCost is Cost + StepCost, estimate(NextCity, Estimated).
get_distance_route(City, Route, Cost) :- estimate(City, Estimated), a_star([[City]/0/Estimated], ReverseRoute/Cost/_), reverse(ReverseRoute, Route).
find_route(Source, Destination, Route, Distance) :- write("The Route and Distance Followed by  astar search are given below"), nl, set_destination(Destination), get_distance_route(Source, Route, Distance).
set_destination(City) :- retractall(target_city(_)), assert(target_city(City)).

% Setting Goal
target(Goal) :- atom(Goal), target_city(Goal).
move(City1, City2, Distance) :- connectivity(City1, City2, Distance) ; connectivity(City2, City1, Distance).
estimate(City, HaversineDistance) :- target_city(Goal), coordinates(City, X1,Y1), coordinates(Goal, X2,Y2), haversine_distance(X1,Y1, X2,Y2, HaversineDistance).
haversine_distance(Latitude1, Longitude1, Latitude2, Longitude2, Dis):- P is 0.017453292519943295, A is (0.5 - cos((Latitude2 - Latitude1) * P) / 2 + cos(Latitude1 * P) * cos(Latitude2 * P) * (1 - cos((Longitude2 - Longitude1) * P)) / 2), Dis is (12742 * asin(sqrt(A))).

%  Breadth First search

% predicate to sum the distance of a path.

sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, N), Sum is H + N.

bfs_value(Source,Destination,Path) :- breadth_first_search(Destination,[intm(Source,[])],[],R),reverse(R,Path), sum_list(Path,Sum), write("The Distance in BFS traversal is as follows"), nl, write(Sum).
breadth_first_search(Destination,[intm(Destination,Path)|_],_,Path).
breadth_first_search(Destination,[intm(Source,Path1)|Next],K,Path) :- length(Path1,
Length), findall(intm(Source1,[A|Path1]),(move(Source,Source1,A), \+ (member(intm(Source1,P2),Next),length(P2,Length)),\+ member(Source1,K)),Expected),append(Next,Expected,O),breadth_first_search(Destination,O,[Source|K],Path).