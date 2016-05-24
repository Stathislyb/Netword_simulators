function [mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue, mean_delay_server] = MG1( l, b, Sim_Time )

% starting time = 0
T=0;
% flag for simulation's main loop
flag=true;
% Dalay queue
Q=zeros(2,0);
% total clients counter and id
counter_id=0;

% flag for server availability (0 available, 1 unavailable)
server_busy=0;
% clients waiting in the delay queue
pending_clients=0;

% counters for results
sum_delay=0;
sum_delay_queue=0;
number_delay=0;
sum_clients_on_queue=0;
sum_clients_on_server=0;



% event list, first row {1,2,3} possible events, second row their simulation time
%  starts with event 1 (birth) at time 0
Event_List=[1;0];


% input the termination event 3 at Sim_Time
Event_List(1, end + 1) = 3;
Event_List(2, end) = Sim_Time;
Event_List(3, end) = 0;

% main loop, terminated by event 3
while flag
    
	% get next event
    event=Event_List(1,1);
	
    if event==1                                 % Birth event
		% get the time of this event
        T=Event_List(2,1);
		% give the client an id. The id also tells us how 
		%  many clients arrived in total
        counter_id=counter_id+1;
		% display the arrival time and the client id
        % disp('Arrival at time')
        % disp(T)
        % disp('Client ID')
        % disp(counter_id)
        % disp('---------')
		% add the client to the delay queue Q
        Q(1,end+1)=counter_id;
        Q(2,end)=T;
		
        if server_busy==0
			% if the server is not busy, point it as busy and
            server_busy=1;
			%  call the event 2 after random  time with mean b
            Event_List(1,end+1)=2;
            Event_List(2,end)=T+2*b*rand; 		% rand with range from 0 to 2b and having mean b
        else
			% if the server is busy, note that there is an other client
			%  waiting in the queue
			pending_clients=pending_clients+1;
			% count the number of clients left on queue
			sum_clients_on_queue = sum_clients_on_queue+pending_clients;
        end
		
		% check if we create clients fast enough to finish simulation
		temp_birth_time = exprnd(1/l,1,1);
		% else, call event 1 for new birth after random exponential time with mean 1/l
		Event_List(1,end+1)=1;
		Event_List(2,end)=T+temp_birth_time;
		
    elseif event==2                             % Death event
		% get the time of this event
        T=Event_List(2,1);
        if ~isempty(Q)
			% display the departure time and the client id
            % disp('Departure at time')
            % disp(T)
            % disp('Client ID')
            % disp(Q(1,1))
            % disp('---------')
			
			% add the waiting time of this client to the total waiting time
            sum_delay=sum_delay+T-Q(2,1);
			% increase the total of clients who waited in the queue
            number_delay=number_delay+1;

			% remove the client from the queue
            Q(:,1)=[];
        end
        
		
        if pending_clients>0
			% if we have other clients in the queue
			%  call event 2 again for their departure 
			%  after random time with mean b
            Event_List(1,end+1)=2;
			temp_death_time = 2*b*rand;   			% rand with range from 0 to 2b and having mean b
            Event_List(2,end)=T+temp_death_time;
			
			%  add the delay this client will have in queue in our counter
			sum_delay_queue= sum_delay_queue+ temp_death_time;
			%  and reduce the ammount of clients waiting
            pending_clients=pending_clients-1; 
			% count the number of clients left on queue
			sum_clients_on_queue = sum_clients_on_queue+pending_clients;

        else
			% if the queue is empty, the server is available
            server_busy=0;
        end
		
		% count the number of clients passing through the server
		sum_clients_on_server=sum_clients_on_server+1;
        
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

end


% mean clients on the server will be the summary of clients that passed through the server
% divided by the total number of clients created
mean_server_clients = sum_clients_on_server / counter_id;

% mean clients on the system will be the summary of clients in our queue
% divided by the total number of clients created
mean_queue_clients = sum_clients_on_queue / counter_id;

% mean clients on the system will be the summary of the above calculations
mean_system_clients = (sum_clients_on_server+sum_clients_on_queue) / counter_id;

% mean delay will be the summary of delay times divided by the number of clients that waited
mean_delay_system=sum_delay/number_delay;

% mean delay in the queue will be the summary of delay times in the queue divided by the number of clients that waited
mean_delay_queue=sum_delay_queue/number_delay;

% mean delay in the server will be the mean delay in the whole system minus the mean delay in queue
mean_delay_server= mean_delay_system - mean_delay_queue;


end

