function [throughput,average_waiting] = Epon( N, W, Sim_time)
	format long g
    flag=true;
	Lambda=1;					% arrival mean 1 msec
	speed = 125*(10^3); 		% converted to Bytes per msec
	Sim_time = Sim_time*(10^3); % converted to msec
	
	% Event list, 1st row : event, 2nd row: time in msec,
	%  3rd row: ONU id(optional), 4rth row: package size in bytes (optional)
    Event_List=zeros(4,0);
	% First Arrival Event for each ONU
	for i=1:N
		Event_List(1,end+1)=1;
		Event_List(2,end)=exprnd(Lambda);
		Event_List(3,end)=i;
	end
	
	% create N ONUs and calculate their distance in time (msec)
	onu_delay = zeros(N,1);
	for i=1:N
		% give them random distances ranging from 20 to 60 km
		onu_delay(i) = 20+rand()*(60-20);
		% convert to meters and divide by 2/3 of the speed of light (rounded and in m/msec)
		% to find the time it takes for their distance (in msec)
		onu_delay(i) = ( onu_delay(i) * 10^3 ) / 200000;
	end
	
	% keep the queue size for each ONU
	onu_queue = zeros(N,1);
	
	% keep the time after which the channel is available for each channel
	channels = zeros(W,1);
	
	total_waiting = 0;
	num_of_packs = 0;
	average_waiting = 0;
	bytes_send_successfully=0;
	throughput=0;
	
    while flag
        event=Event_List(1,1);
        if event==1		
			% arrival event
            [Event_List,onu_queue]=Event1(Event_List,Lambda,Sim_time,onu_queue);

        elseif event==2
			% routing event
            [Event_List,onu_queue,total_waiting,num_of_packs,channels]=Event2(Event_List,channels,N,onu_queue,onu_delay,speed,total_waiting,num_of_packs);
		
		elseif event==3
			% departure event
			[Event_List,onu_queue,bytes_send_successfully]=Event3(Event_List,onu_queue,bytes_send_successfully);

        elseif event==10
			% terminate simulation event
            [flag]=Event10(flag,Event_List);

        end

        Event_List(:,1)=[];
        Event_List=(sortrows(Event_List',[2,1]))';
        
    end
	
	% calculate the average package time in queue in msec
	average_waiting = total_waiting/num_of_packs ;
	% calculate throughput in bits per sec
	throughput = (bytes_send_successfully*8) / (Sim_time/(10^3));
end

function [Event_List,onu_queue]=Event1(Event_List,Lambda,Sim_time,onu_queue)
	
    T=Event_List(2,1);
	
	if Sim_time <= T
		% if the simulation time has elapsed, call termination event
		Event_List(1,end+1)=10;
		Event_List(2,end)=T;
	else
		
		% generated random pack's size, range 1518 to 64 Bytes
		pack_size= randi([64 1518]);
		
		% if there is room in the queue add the incoming pack, else drop it
		% queue size hard coded at 10MB
		if (onu_queue(Event_List(3,1))+pack_size) < (10^6)
			
			% add the pack's size to the ONU's queue
			onu_queue(Event_List(3,1)) = onu_queue(Event_List(3,1)) + pack_size;
			
			% route this arrival
			Event_List(1,end+1)= 2;
			Event_List(2,end)= T;
			Event_List(3,end)= Event_List(3,1);
			Event_List(4,end)= pack_size;
		else
			% dropped pack
			%disp('droped')
		end
		
		%generate new arrival
		Event_List(1,end+1)=1;
		Event_List(2,end)=T+exprnd(Lambda);
		Event_List(3,end)=Event_List(3,1);
	
	end
    
end

function [Event_List,onu_queue,total_waiting,num_of_packs,channels]=Event2(Event_List,channels,N,onu_queue,onu_delay,speed,total_waiting,num_of_packs)
	T=Event_List(2,1);
	Node = Event_List(3,1);
	Pack_Size = Event_List(4,1);
	
	% chose channel
	chosen_channel=0;
	min_chan_delay=inf;
	for i=1:size(channels,1)
		if channels(i) < min_chan_delay
			min_chan_delay=channels(i);
			chosen_channel=i;
		end
	end
	
	% keep an initial time, it's the time the channel will be available
	%  unless it's already available where we use the current time
	if channels(chosen_channel) > T
		init_time = channels(chosen_channel);
	else
		init_time = T;
	end
	
	% calculate the gate/report delay (64 Bytes / transm. speed)
	gate_report_delay = (64/speed);
	% the OLT recieves the transmission after 2 times the delay's sum plus one transmission delay
	% to be informed about the package.
	%  ( one for gate and one for report+data) 
	transmit_begin_delay=onu_delay(Node) + (onu_delay(Node) + gate_report_delay)*2;
	% the transmission will end and release the channel after the sum of delays + the time
	%  requried to transmit the actual data.
	total_time = init_time + transmit_begin_delay + (Pack_Size/speed);
	% guard time converted to msec
	guard_time = 2*(10^(-3));
	% the channel will be available again after the transmission is finished plus the guard time
	channels(chosen_channel) = total_time + guard_time;
	
	% count the the total waiting time in queue for each package 
	total_waiting = total_waiting + (init_time - T) + transmit_begin_delay + (Pack_Size/speed);
	% count number of packages
	num_of_packs = num_of_packs+1;
	
	% call event 3 to remove the pack's size from the queue
	Event_List(1,end+1)= 3;
	Event_List(2,end)= total_time;
	Event_List(3,end)= Node;
	Event_List(4,end)= Pack_Size;
	
end

function [Event_List,onu_queue,bytes_send_successfully]=Event3(Event_List,onu_queue,bytes_send_successfully)
	T=Event_List(2,1);
    Node = Event_List(3,1);
	Pack_Size = Event_List(4,1);
	
	% calculate the amount of bytes successfully send
	bytes_send_successfully = bytes_send_successfully + Pack_Size;
	
	% remove the pack's size from the queue
	onu_queue(Node) = onu_queue(Node) - Pack_Size;

end

function [flag]=Event10(flag,Event_List)
	% termination event, turn flag to false will end the main loop
    T=Event_List(2,1);
    flag=false;

end
