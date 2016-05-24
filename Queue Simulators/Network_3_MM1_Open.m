function [ N1, N2, N3, T1, T2, T3 ] = Network_3_MM1_Open( l, m1, m2, m3, Sim_Time )

% initialize the loop flag and the time var
Sim_Flag = true;
Time = 0;

% initialize the event list
% this time the event list will keep the client id in the 3rd row
% if there is no client it will have the value 0
	% call event 0 at 0 time
Event_List(1,:) = 0;
Event_List(2,:) = 0;
Event_List(3,:) = 0;
	% start the event 4 (for result counters update) at time 0 which will repeat it's self with interval 0.1
Event_List(1, end + 1) = 4;
Event_List(2, end) = 0;
Event_List(3, end) = 0;
	% input the termination event 10 at Sim_Time
Event_List(1, end + 1) = 10;
Event_List(2, end) = Sim_Time;
Event_List(3, end) = 0;

% initialize the Queues for each system.
	% each Queue has the first row for the client's id 
	% and the 2nd row for the client's delay in the system
Q1 = zeros(2,0);
Q2 = zeros(2,0);
Q3 = zeros(2,0);


% initialize the counters for the results
Sum_Clients1 = 0;
Counter_Clients1 = 0;

Sum_Clients2 = 0;
Counter_Clients2 = 0;

Sum_Clients3 = 0;
Counter_Clients3 = 0;

Sum_Delay1 = 0;
Counter_Delay1 = 0;

Sum_Delay2 = 0;
Counter_Delay2 = 0;

Sum_Delay3 = 0;
Counter_Delay3 = 0;

last_client_id=0;

N1 = 0;
N2 = 0;
N3 = 0;
T1 = 0;
T2 = 0;
T3 = 0;

while Sim_Flag
	
	Event = Event_List(1,1);
	Time = Event_List(2,1);
	
	if Event == 0					% Event 0, System 1 receives client from outside the network 
        
        [ Event_List, Q1, Sum_Delay1, last_client_id ] = Event0( Time, Event_List, Q1, m1, l, Sum_Delay1, last_client_id);
        
    elseif Event == 1				% Event 1, System 1 sends client to system 2 
        
        [ Event_List, Q1, Q2, Sum_Delay1, Counter_Delay1 ] = Event1( Time, Event_List, Q1, Q2, m2, Sum_Delay1, Counter_Delay1 );
        
    elseif Event == 2				% Event 2, System 2 sends client to system 3
        
        [ Event_List, Q2, Q3, Sum_Delay2, Counter_Delay2 ] = Event2( Time, Event_List, Q2, Q3, m3, Sum_Delay2, Counter_Delay2 );
        
	elseif Event == 3				% Event 3, System 3 sends client out of the network
        
        [ Event_List, Q3, Sum_Delay3, Counter_Delay3 ] = Event3( Time, Event_List, Q3, Sum_Delay3, Counter_Delay3 );
		
    elseif Event == 4				% Event 4, Result counters update and 
										% it will call it's self again after 0.1 Time
        [ Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3 ] = Event4(Time, Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3, Q1, Q2, Q3);
        
    elseif Event == 10				% Event 10, Termination event
        
        [ Event_List, Sim_Flag, N1, N2, N3, T1, T2, T3 ] = Event10(Time, Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3, Sum_Delay1, Sum_Delay2, Sum_Delay3, Counter_Delay1, Counter_Delay2, Counter_Delay3 );
        
    end
    
	% sort events by their time for the next loop
    Event_List(:,1)=[];
    Event_List=sortrows(Event_List',2)';
    
end

end


function [ Event_List, Q1, Sum_Delay1, last_client_id ] = Event0( Time, Event_List, Q1, m1, l, Sum_Delay1, last_client_id)
	
	% increase the counter id 
	last_client_id = last_client_id+1;
	
	% calculate how long will it take for the client to be forwarded
	exp_time=exprnd(1/m1,1,1);
	
	% put the client to system 1's Queue
	Q1(1,end+1)= last_client_id;
	% keep the delay it will have till next forwarding
	Q1(2,end)=exp_time;
	
	% call event 1 at the appropriate time
	Event_List(1, end + 1) = 1;
	Event_List(2, end) = Time + exp_time;
	Event_List(3, end) = last_client_id;
	
	% call event 0 again at the appropriate time 
	%  to generate a new client in the network
	Event_List(1, end + 1) = 0;
	Event_List(2, end) = Time + exprnd(1/l,1,1);
	Event_List(3, end) = 0;
	
end



function [ Event_List, Q1, Q2, Sum_Delay1, Counter_Delay1 ] = Event1( Time, Event_List, Q1, Q2, m2, Sum_Delay1, Counter_Delay1 )
	
	% get the id of the forwarded client
	Client_id = Event_List(3,1);
	% get the index in Q1 of the forwarded client
	idx = ( Q1(1,:) == Client_id);
	
	% calculate how long will it take for the client to be forwarded
	exp_time=exprnd(1/m2,1,1);
	
	% pass the client to system 2's Queue
	Q2(1,end+1)=Q1(1,idx);
	% keep the delay it will have till next forwarding
	Q2(2,end)=exp_time;
	
	
	% count the delay for system 1 
	Sum_Delay1 = Sum_Delay1 + Q1(2,idx);
	Counter_Delay1 = Counter_Delay1+1;
	
	% remove the client from system 1's Queue
	Q1(:,idx)=[];
	
	% call the appropriate next event at the appropriate time
	Event_List(1, end + 1) = 2;
	Event_List(2, end) = Time + exp_time;
	Event_List(3, end) = Client_id;

end

function [ Event_List, Q2, Q3, Sum_Delay2, Counter_Delay2 ] = Event2( Time, Event_List, Q2, Q3, m3, Sum_Delay2, Counter_Delay2 )
	
	% get the id of the forwarded client
	Client_id = Event_List(3,1);
	% get the index in Q2 of the forwarded client
	idx = ( Q2(1,:) == Client_id);
	
	% calculate how long will it take for the client to be forwarded
	exp_time=exprnd(1/m3,1,1);
	
	% count the delay for system 2
	Sum_Delay2 = Sum_Delay2 + Q2(2,idx);
	Counter_Delay2 = Counter_Delay2+1;
	
	% pass the client to system 3's Queue
	Q3(1,end+1)=Q2(1,idx);
	% keep the delay it will have till next forwarding
	Q3(2,end)=exp_time;
	
	% remove the client from system 2's Queue
	Q2(:,idx)=[];
	
	% call event 3 at the appropriate time
	Event_List(1, end + 1) = 3;
	Event_List(2, end) = Time + exp_time;
	Event_List(3, end) = Client_id;

end

function [ Event_List, Q3, Sum_Delay3, Counter_Delay3 ] = Event3( Time, Event_List, Q3, Sum_Delay3, Counter_Delay3 )

	% get the id of the forwarded client
	Client_id = Event_List(3,1);
	% get the index in Q3 of the forwarded client
	idx = ( Q3(1,:) == Client_id);
	
	% count the delay for system 3
	Sum_Delay3 = Sum_Delay3 + Q3(2,idx);
	Counter_Delay3 = Counter_Delay3+1;
	
	% remove the client from system 3's Queue and the network
	Q3(:,idx)=[];
	
	
end

function [ Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3 ] = Event4(Time, Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3, Q1, Q2, Q3)

	% Recall event 4 for update every 0.1 time
	Period=0.1;
	
	% update the sums and increase the counters
	Sum_Clients1 = Sum_Clients1 + length( Q1(1,:) );
	Sum_Clients2 = Sum_Clients2 + length( Q2(1,:) );
	Sum_Clients3 = Sum_Clients3 + length( Q3(1,:) );
	Counter_Clients1 = Counter_Clients1 + 1;
	Counter_Clients2 = Counter_Clients2 + 1;
	Counter_Clients3 = Counter_Clients3 + 1;
	
	% call event 4 again after period time
	Event_List(1, end + 1) = 4;
	Event_List(2, end) = Time + Period;
	Event_List(3, end) = 0;

end

function [ Event_List, Sim_Flag, N1, N2, N3, T1, T2, T3 ] = Event10(Time, Event_List, Sum_Clients1, Sum_Clients2, Sum_Clients3, Counter_Clients1, Counter_Clients2, Counter_Clients3, Sum_Delay1, Sum_Delay2, Sum_Delay3, Counter_Delay1, Counter_Delay2, Counter_Delay3 )
	
	% calculate the means to return
	N1 = Sum_Clients1 / Counter_Clients1;
	N2 = Sum_Clients2 / Counter_Clients2;
	N3 = Sum_Clients3 / Counter_Clients3;
	T1 = Sum_Delay1 / Counter_Delay1;
	T2 = Sum_Delay2 / Counter_Delay2;
	T3 = Sum_Delay3 / Counter_Delay3;
	
	% end simulation
	Sim_Flag = false;
	%sprintf('Simulation end at time %f', Time)
		
end
