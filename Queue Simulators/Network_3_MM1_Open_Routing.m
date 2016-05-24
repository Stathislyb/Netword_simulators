function [ N1, N2, N3, T1, T2, T3 ] = Network_3_MM1_Open_Routing( l, m1, m2, m3, P, Sim_Time )

% initialize the loop flag and the time var
Sim_Flag = true;
Time = 0;

% initialize the event list
% this time the event list will keep the client id in the 3rd row
% and the system triggering the event in row 4
% if there is no client or system associated with the event, they will have the value 0
	% call event 0 at 0 time
Event_List(1,:) = 0;
Event_List(2,:) = 0;
Event_List(3,:) = 0;
	% start the event 4 (for result counters update) at time 0 which will repeat it's self with interval 0.1
Event_List(1, end + 1) = 4;
Event_List(2, end) = 0;
Event_List(3, end) = 0;
Event_List(4, end) = 0;
	% input the termination event 10 at Sim_Time
Event_List(1, end + 1) = 10;
Event_List(2, end) = Sim_Time;
Event_List(3, end) = 0;
Event_List(4, end) = 0;

% initialize the Queues for each system.
	% Depth : Queue system, Columns : each client, Rows :
	% each Queue has the first row for the client's id 
	% and the 2nd row for the client's delay in the system
Q = zeros(2,0,3);


% initialize the counters for the results
Sum_Clients = zeros(3,1);
Counter_Clients = zeros(3,1);

Sum_Delay = zeros(3,1);
Counter_Delay = zeros(3,1);

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
        
        [ Event_List, Q, last_client_id ] = Event0( Time, Event_List, Q, m1, l, last_client_id, P);
        
    elseif Event == 1				% Event 1, Forwarding the client 
		
        [ Event_List, Q, Sum_Delay, Counter_Delay ] = Event1( Time, Event_List, Q, m1, m2, m3, Sum_Delay, Counter_Delay, P);
		
    elseif Event == 4				% Event 4, Result counters update and 
										% it will call it's self again after 0.1 Time
        [ Event_List, Sum_Clients, Counter_Clients ] = Event4(Time, Event_List, Sum_Clients, Counter_Clients, Q);
        
    elseif Event == 10				% Event 10, Termination event
        
        [ Event_List, Sim_Flag, N1, N2, N3, T1, T2, T3 ] = Event10(Time, Event_List, Sum_Clients, Counter_Clients, Sum_Delay, Counter_Delay );
        
    end
    
	% sort events by their time for the next loop
    Event_List(:,1)=[];
    Event_List=sortrows(Event_List',2)';
    
end

end


function [ Event_List, Q, last_client_id ] = Event0( Time, Event_List, Q, m1, l, last_client_id, P)
	
	% increase the counter id 
	last_client_id = last_client_id+1;
	
	% calculate how long will it take for the client to be forwarded
	exp_time=exprnd(1/m1,1,1);
	
	% put the client to system 1's Queue
	Q(1,end+1,1)= last_client_id;
	% keep the delay it will have till next forwarding
	Q(2,end,1)=exp_time;
	
	% call event 1 at the appropriate time
	Event_List(1, end + 1) = 1;
	Event_List(2, end) = Time + exp_time;
	Event_List(3, end) = last_client_id;
	Event_List(4, end) = 1;
	
	% call event 0 again at the appropriate time 
	%  to generate a new client in the network
	Event_List(1, end + 1) = 0;
	Event_List(2, end) = Time + exprnd(1/l,1,1);
	Event_List(3, end) = 0;
	
end



function [ Event_List, Q, Sum_Delay, Counter_Delay ] = Event1( Time, Event_List, Q, m1, m2, m3, Sum_Delay, Counter_Delay, P)
	
	% keep a flag to tell us if the client was successfully forwarded
	client_forwarded = 0;
	
	% get the system which forwards the client
	system = Event_List(4,1);
	% get the id of the forwarded client
	Client_id = Event_List(3,1);
	% get the index in Q1 of the forwarded client
	idx = ( Q(1,:,system) == Client_id);

	
	% get a random number between 0 and 1 to check where will the client be forwarded
	p_rand= rand();
	for i=1 : length(P)
		if p_rand < sum( P(system,1:i) ) && client_forwarded == 0
			
			% the client is forwarded, turn the flag on
			client_forwarded = 1;
			
			% calculate how long will it take for the client to be forwarded
			if i == 1
				exp_time=exprnd(1/m1,1,1);
			elseif i==2
				exp_time=exprnd(1/m2,1,1);
			elseif i==3
				exp_time=exprnd(1/m3,1,1);
			end
			
			% count the delay for the system 
			Sum_Delay(system) = Sum_Delay(system) + Q(2,idx,system);
			Counter_Delay(system) = Counter_Delay(system)+1;
			
			% pass the client to appropriate system's Queue
			Q(1,end+1,i)=Q(1,idx,system);
			% keep the delay it will have till next forwarding
			Q(2,end,i)=exp_time;
			
			% remove the client from the system's Queue
			Q(:,idx,system)=0;
			
			% call event 1 for the next forwarding of the client at the appropriate time
			Event_List(1, end + 1) = 1;
			Event_List(2, end) = Time + exp_time;
			Event_List(3, end) = Client_id;
			Event_List(4, end) = i;
			
			
		end
	end
	
	% if the client was not forwarded, remove them from the network
	if client_forwarded == 0
		% count the delay for the system
		Sum_Delay(system) = Sum_Delay(system) + Q(2,idx,system);
		Counter_Delay(system) = Counter_Delay(system)+1;
		
		% remove the client from the system's Queue and the network
		Q(:,idx,system)=0;
		
	end
	
end


function [ Event_List, Sum_Clients, Counter_Clients ] = Event4(Time, Event_List, Sum_Clients, Counter_Clients, Q)

	% Recall event 4 for update every 0.1 time
	Period=0.1;
	
	% update the sums and increase the counters
	for i=1:3
		Sum_Clients(i) = Sum_Clients(i) + length( nonzeros( Q(1,:,i) ) );
		Counter_Clients(i) = Counter_Clients(i) + 1;
	end
	% call event 4 again after period time
	Event_List(1, end + 1) = 4;
	Event_List(2, end) = Time + Period;
	Event_List(3, end) = 0;
	Event_List(4, end) = 0;

end

function [ Event_List, Sim_Flag, N1, N2, N3, T1, T2, T3 ] = Event10(Time, Event_List, Sum_Clients, Counter_Clients, Sum_Delay, Counter_Delay )
	
	% calculate the means to return
	N1 = Sum_Clients(1) / Counter_Clients(1);
	N2 = Sum_Clients(2) / Counter_Clients(2);
	N3 = Sum_Clients(3) / Counter_Clients(3);
	T1 = Sum_Delay(1) / Counter_Delay(1);
	T2 = Sum_Delay(2) / Counter_Delay(2);
	T3 = Sum_Delay(3) / Counter_Delay(3);
	
	% end simulation
	Sim_Flag = false;
	%sprintf('Simulation end at time %f', Time)
		
end
