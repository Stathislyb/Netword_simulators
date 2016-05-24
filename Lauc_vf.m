function [Throughput, Channel_util_rate, Drop_Rate] = Lauc_vf( N, channels, Sim_bursts, Lambda)
    flag=true;
	
    Event_List=zeros(2,1);
    Event_List(1,1)=1; % Arrival Event
    Event_List(2,1)=exprnd(1/Lambda);
	
    bursts_dropped=0;
    total_bursts=0;
	total_bytes=zeros(N,channels);
	channel_use_time=zeros(N,channels,2);
	voids=zeros(N,channels,2);
	voids_head=ones(N,channels);
	
    while flag
        event=Event_List(1,1);
        if event==1

            [Event_List]=Event1(Event_List,Lambda);

        elseif event==2

            [Event_List,total_bursts,voids,bursts_dropped,total_bytes,channel_use_time,voids_head]=Event2(Event_List,channels,Sim_bursts,total_bursts,voids,N,bursts_dropped,total_bytes,channel_use_time,voids_head);

        elseif event==10

            [flag]=Event10(flag,Event_List);

        end

        Event_List(:,1)=[];
        Event_List=(sortrows(Event_List',[2,1]))';
        
    end
	
	% calculate the utilization rate for each channel in each exit
	channel_util_rate_table = divide_matrix_with_zeros(channel_use_time(:,:,1),channel_use_time(:,:,2));
	% calculate the average utilization rate, percentage
    Channel_util_rate = sum(sum(channel_util_rate_table)) / (N*channels);
	
	% calculate the throughput for each channel
	throughput_table = divide_matrix_with_zeros(total_bytes,channel_use_time(:,:,2));
	% calculate the average throughput, Bytes/sec
    Throughput = sum(sum(throughput_table)) / (N*channels);
	
	% calculate the bursts drop rate, percentage
    Drop_Rate = bursts_dropped / total_bursts;

	voids
    
end

function [Event_List]=Event1(Event_List,Lambda)
	
    T=Event_List(2,1);
	
	%process this arrival
    Event_List(1,end+1)=2;
    Event_List(2,end)=T;
	
	%generate new arrival
    Event_List(1,end+1)=1;
    Event_List(2,end)=T+exprnd(1/Lambda);
    
end

function [Event_List,total_bursts,voids,bursts_dropped,total_bytes,channel_use_time,voids_head]=Event2(Event_List,channels,Sim_bursts,total_bursts,voids,N,bursts_dropped,total_bytes,channel_use_time,voids_head)
	T=Event_List(2,1);
	
	% check if the simulation has process enough bursts to finish
	total_bursts=total_bursts+1;
	if total_bursts == Sim_bursts
		% end the simulation
		Event_List(1,end+1)=10;
		Event_List(2,end)=T;
	end
	
	% exit range 1 - N
	exit = randi([1 N]);
	% size range 60 - 10,000 in bytes
	burst_size = randi([60 10000]);
	% interval between burst and control pack. has range 1 - 1000 in μsec
	interval = 1+rand()*(1000-1);
	% calculate the arrival time of the burst
	arrival_time = T + interval;
	% calculate the time to transmit the burst in μsec
	transmission_time = ( burst_size/(125*(10^6)) )*(10^6);

	
	% find the channel to transmit using Horizon algorithm
	[selected_channel,pos_void] = select_channel(voids(exit,:,:),arrival_time,channels);
	%update the channel's horizon if a channel was available, or count dropped bursts otherwise
	if selected_channel==0
		bursts_dropped=bursts_dropped+1;
	else
		pointer = voids_head(exit,selected_channel);
		
		if voids(exit,selected_channel,pos_void+1) == 0
			% if we had no void available, update with the new void created and the new horizon
			voids(exit,selected_channel,pos_void+1) = arrival_time;
			
			if pointer < size(voids,3) % compressing channel's zero elements
				voids(exit,selected_channel,pointer+2)= arrival_time + transmission_time;
				voids(exit,selected_channel,pointer+3)= 0;
			else
				voids(exit,selected_channel,end+1)= arrival_time + transmission_time;
				voids(exit,selected_channel,end+1)= 0;
				
			end
		else
			% if there was a void, seperate the old void into the tow new voids
			if pointer < size(voids,3)  % compressing channel's zero elements
				voids(exit,selected_channel,pointer+2)= arrival_time + transmission_time;
				voids(exit,selected_channel,pointer+3)= voids(exit,selected_channel,pos_void+1);
			else
				voids(exit,selected_channel,end+1)= arrival_time + transmission_time;
				voids(exit,selected_channel,end+1)= voids(exit,selected_channel,pos_void+1);
			end
			voids(exit,selected_channel,pos_void+1) = arrival_time;
		end
		
		voids_head(exit,selected_channel) = voids_head(exit,selected_channel)+2;
		
		% calculate total bytes successfuly send for each channel
		total_bytes(exit,selected_channel) = total_bytes(exit,selected_channel) + burst_size;
		
		% calculate the time used for each channel
		channel_use_time(exit,selected_channel,1) = channel_use_time(exit,selected_channel,1) + transmission_time;
		channel_use_time(exit,selected_channel,2) = max(voids(exit,selected_channel,:));
	end
	
	
end

function [flag]=Event10(flag,Event_List)

    T=Event_List(2,1);
    flag=false;

end

%select channel function
function [selected_channel,pos_void] = select_channel(voids,arrival_time,channels)
	
	%init variables
	selected_channel=0;
	max_hor=-1;
	possible_channels = inf(channels,1);
	horizons = zeros(channels,1);
	pos_void=0;
	pos_void_found=0;
	
	% for each channel in this exit
	for i = 1:channels
		% in case there are no voids, find horizon
		[val, index]=max(voids(1,i,:));
		horizons(i) = val;
		pos_void=index;
		for j= 1:2:size(voids,3)
			if  voids(1,i,j)~=0 || j==1
				% find the best void for each channel, if they have any
				if arrival_time > voids(1,i,j) && arrival_time < voids(1,i,j+1)
					void_space = voids(1,i,j+1) - voids(1,i,j);				
					if void_space < possible_channels(i)
						possible_channels(i) = void_space;
						pos_void_found=j;
					end
				end
			end
		end
		
		% find and select the channel with the further horizon before the arrival time
        if max_hor < horizons(i) && horizons(i) < arrival_time
			selected_channel=i;
			max_hor=horizons(i);
        end
	end
	
	
	% if there are voids in channels, find the best and select it
	%  if not, use the horizon we calculated above
	[val, index] = min(possible_channels);
	if val ~= inf 
		selected_channel=index;
		possible_channels;
		pos_void=pos_void_found;
	end
	
end


% divide 2 matrixes that contain zero values element by element 
function [result] = divide_matrix_with_zeros(matrix_A,matrix_B)
	X=size(matrix_A,1);
	Y=size(matrix_A,2);
	result=zeros(X,Y);
	for i =1:X
		for j=1:Y
			if matrix_B(i,j)~=0
				result(i,j)=matrix_A(i,j)./matrix_B(i,j);
			end
		end
	end
end