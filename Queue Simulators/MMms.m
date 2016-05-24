function [mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue,blocking_probability] = MMms( l,m,servers, Q_size )

% starting time = 0
T=0;
% flag for simulation's main loop
flag=true;
% Dalay queue
Q=zeros(2,0);
% total clients counter and id
counter_id=0;

% if the servers are 0, it means we use infinite servers
if(servers==0)
	servers = inf();
end
% count how many servers we use so we check if there is any left
busy_servers=0;

% if the max queue size is 0, it means we use infinite size
if(Q_size==0)
	Q_size = inf();
end

% clients waiting in the delay queue
pending_clients=0;

% counters for results
sum_delay=0;
sum_delay_queue=0;
number_delay=0;
sum_clients_on_queue=0;
sum_clients_on_server=0;
blocking_probability_passed=0;
blocking_probability_generated=0;
blocking_probability=-1;
counter=1;
sum_clients_on_sys=0;
pending_clients_sum=0;

% event list, first row {1,2,3} possible events, second row their simulation time
%  starts with event 1 (birth) at time 0
Event_List=[1;0];


% main loop, terminated by event 3
while flag
    
	% get next event
    event=Event_List(1,1);

    if event==1                                 % Birth event
		% get the time of this event
		T=Event_List(2,1);
		% check if there is place in the queue for an other client
		if size(Q,2) < Q_size
		
			% give the client an id. The id also tells us how 
			%  many clients arrived in total
			counter_id=counter_id+1;
			% add the client to the delay queue Q
			Q(1,end+1)=counter_id;
			Q(2,end)=T;
			
			if busy_servers <= servers
				% if there are available servers, point an other one as busy
				busy_servers=busy_servers+1;
				%  and call the event 2 after time depending on the queue system
				[death_time_interval] = get_death_interval( m, servers, Q_size, Q);
				Event_List(1,end+1)=2;
				Event_List(2,end)=T+death_time_interval;
			else
				% if all the servers are busy, note that there is an other client
				%  waiting in the queue
				pending_clients=pending_clients+1;
				pending_clients_sum=pending_clients_sum+1;
			end
		
		end	
		
		% check if we create clients fast enough to finish simulation
		[birth_time_interval] = get_birth_interval( l, servers, Q_size, Q);
		if birth_time_interval < 0.0001
			% in case we do, call event 3 for termination
			Event_List(1,end+1)=3;
			Event_List(2,end)=T;
		else
			% else, call event 1 for new birth after random exponential time with mean 1/l
			Event_List(1,end+1)=1;
			Event_List(2,end)=T+birth_time_interval;
		end
		% count all the clients that tried to enter the system
		blocking_probability_generated=blocking_probability_generated+1;
		
		
    elseif event==2                             % Death event
		% get the time of this event
        T=Event_List(2,1);
        if ~isempty(Q)			
			% add the waiting time of this client to the total waiting time
            sum_delay=sum_delay+T-Q(2,1);
			% increase the total of clients who waited in the queue
            number_delay=number_delay+1;
			% count the clients that were not blocked
			blocking_probability_passed=blocking_probability_passed+1;
			% remove the client from the queue
            Q(:,1)=[];
        end
        
		
        if busy_servers <= servers && pending_clients>0
			% if we have other clients in the queue and available servers
			%  call event 2 again for their departure 
			%  after time depending on the queue system
            Event_List(1,end+1)=2;
			[death_time_interval] = get_death_interval( m, servers, Q_size, Q);
            Event_List(2,end)=T+death_time_interval;
			
			%  add the delay this client will have in queue in our counter
			sum_delay_queue= sum_delay_queue+ death_time_interval;
			%  and reduce the ammount of clients waiting
            pending_clients=pending_clients-1; 

        else
			% if the queue is empty or there are no servers available
			%  make the server available
            busy_servers=busy_servers-1;
        end
        
    elseif event==3                              % Termination event
		% get the time of this event
        T=Event_List(2,1);
		% turn the flag to false to end the loop
        flag=false;
    end
	% remove the event you just handled
    Event_List(:,1)=[];
	% sort the event queue to get the next event based on their time
    Event_List=sortrows(Event_List',2)';
	
	% The clients waiting in the queue at this instance are counted by pending_clients
	sum_clients_on_queue = sum_clients_on_queue+pending_clients; 
	% The clients in a server at this instance are counted by busy_servers
	sum_clients_on_server= sum_clients_on_server+busy_servers;
	% all the clients in the system at this point are in the Q matrix
	sum_clients_on_sys=sum_clients_on_sys+size(Q,2);
	% increase counter
	counter=counter+1;
	
end


% mean clients on the server will be the summary of clients that passed through the server
% divided by the total number of clients created
mean_server_clients = sum_clients_on_server / counter;

% mean clients on the system will be the summary of clients in our queue
% divided by the total number of clients created
mean_queue_clients = sum_clients_on_queue / counter;

% mean clients on the system will be the summary of the above calculations
mean_system_clients = sum_clients_on_sys / counter;

% mean delay will be the summary of delay times divided by the number of clients that waited
mean_delay_system=sum_delay/number_delay;

% mean delay in the queue will be the summary of delay times in the queue divided by the number of clients that waited
mean_delay_queue=sum_delay_queue/number_delay;

% Blocking probability for M/M/m/m
if (servers < inf && servers>1) && (Q_size < inf && Q_size>1)
	% blocking probability will be 1 minus (for the opposite percentage) 
	%  the clients that were not blocked 
	%  divided by the sum of clients arriving the system (rejected or not)
	blocking_probability = 1 - ( blocking_probability_passed / blocking_probability_generated);
end

% Blocking probability for M/M/m ( probability for client to be pending)
if (servers < inf && servers>1) && Q_size == inf
	% blocking probability will be 1 minus (for the opposite percentage) 
	%  the clients that were not blocked 
	%  divided by the sum of clients arriving the system (rejected or not)
	blocking_probability = pending_clients_sum / counter_id;
end

end


function [birth_time_interval] = get_birth_interval( l, servers, Q_size, Q)
	birth_time_interval_rate=0;
	
	% for M/M/1 birth interval rate equal to l
	if Q_size == inf && servers == 1
		birth_time_interval_rate = l;
	end
	
	% for M/M/m and M/M/inf we have all interval rates equal to l
	if Q_size == inf && servers > 1 
		birth_time_interval_rate = l;
	end
	
	% for M/M/1/m the birth interval rates equal to l while there is still room in the queue
	%  and equal to 0 when there isn't
	if Q_size < inf && servers == 1
		if size(Q,2) < Q_size
			birth_time_interval_rate = l;
		else
			% we keep calling event 1 for those clients so we don't run out of
			% events but in the birth event, we deal with the case of full Queue
			birth_time_interval_rate = 0;
		end
	end
	
	% for M/M/m/m the birth interval rate is equal to the Queue size
	if Q_size < inf && (servers > 1 && servers < inf)
		birth_time_interval_rate = l;
	end
	
	if birth_time_interval_rate == 0
		birth_time_interval = 0;
	else
		birth_time_interval = exprnd(1/birth_time_interval_rate,1,1);
	end
	
end

function [death_time_interval] = get_death_interval( m, servers, Q_size, Q)
	death_time_interval_rate=0;
	
	% for M/M/1 death interval rate equal to m
	if Q_size == inf && servers == 1
		death_time_interval_rate = m;
	end
	
	% for M/M/m the death interval rates are linear equation of the Queue size
	% while that size is less than the availiable servers.
	if Q_size == inf && (servers > 1 && servers < inf) 
		if size(Q,2) < servers
			death_time_interval_rate = size(Q,2)*m;
		else
			death_time_interval_rate = servers*m;
		end
	end
	
	% for M/M/inf the death interval rates are linear equation of the Queue size
	if Q_size == inf && servers ==inf 
		death_time_interval_rate = size(Q,2)*m;
	end
	
	% for M/M/1/m the death interval rates are equal to m while there is still room in the queue
	%  and equal to 0 when there isn't
	if Q_size < inf && servers == 1
		if size(Q,2) <= Q_size
			death_time_interval_rate = m;
		else
			death_time_interval_rate = 0;
		end
	end
	
	% for M/M/m/m the death interval rate is linear equation to the Queue size
	if Q_size < inf && (servers > 1 && servers < inf)
		death_time_interval_rate = m*size(Q,2);
	end
	
	if death_time_interval_rate == 0
		death_time_interval = 0;
	else
		death_time_interval=exprnd(1/death_time_interval_rate,1,1);
	end
end