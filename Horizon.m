function [Throughput, Channel_util_rate, Drop_Rate] = Horizon( N, channels, Sim_bursts, Lambda)
    flag=true;
	
    Event_List=zeros(2,1);
    Event_List(1,1)=1; % Arrival Event
    Event_List(2,1)=exprnd(1/Lambda);
	
    bursts_dropped=0;
    total_bursts=0;
	total_bytes=zeros(N,channels);
	channel_use_time=zeros(N,channels,2);
	horizons=zeros(N,channels);
	
    while flag
        event=Event_List(1,1);
        if event==1

            [Event_List]=Event1(Event_List,Lambda);

        elseif event==2

            [Event_List,total_bursts,horizons,bursts_dropped,total_bytes,channel_use_time]=Event2(Event_List,channels,Sim_bursts,total_bursts,horizons,N,bursts_dropped,total_bytes,channel_use_time);

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

function [Event_List,total_bursts,horizons,bursts_dropped,total_bytes,channel_use_time]=Event2(Event_List,channels,Sim_bursts,total_bursts,horizons,N,bursts_dropped,total_bytes,channel_use_time)
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
	size = randi([60 10000]);
	% interval between burst and control pack. has range 1 - 1000 in μsec
	interval = 1+rand()*(1000-1);
	% calculate the arrival time of the burst
	arrival_time = T + interval;
	% calculate the time to transmit the burst in μsec
	transmission_time = ( size/(125*(10^6)) )*(10^6);

	
	% find the channel to transmit using Horizon algorithm
	[selected_channel] = select_channel(horizons(exit,:),arrival_time);
	%update the channel's horizon if a channel was available, or count dropped bursts otherwise
	if selected_channel==0
		bursts_dropped=bursts_dropped+1;
	else
		% the new horizon becomes the arrival time of the control pack.(T) 
		%  plus time required to transmit the burst	
		horizons(exit,selected_channel)= arrival_time + transmission_time;
		
		% calculate total bytes successfuly send for each channel
		total_bytes(exit,selected_channel) = total_bytes(exit,selected_channel) + size;
		
		% calculate the time used for each channel
		channel_use_time(exit,selected_channel,1) = channel_use_time(exit,selected_channel,1) + transmission_time;
		channel_use_time(exit,selected_channel,2) = horizons(exit,selected_channel);
	end
	
end

function [flag]=Event10(flag,Event_List)

    T=Event_List(2,1);
    flag=false;

end

%select channel function
function [selected_channel] = select_channel(horizons,arrival_time)
	
	%init variables
	selected_channel=0;
	max_hor=-1;
	
	% for each channel in this exit
	for i = 1:length(horizons)
		% find and select the channel with the further horizon before the arrival time
        if max_hor < horizons(i) && horizons(i) < arrival_time
			selected_channel=i;
			max_hor=horizons(i);
        end
	end
	
end


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