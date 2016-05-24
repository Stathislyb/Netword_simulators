function [Throughput, Average_wait_Q, Drop_Rate] = broadcast_select_TD( Sim_Timeslots, Nodes, Channels, Queue_Size, Lambda, B)
    flag=true;
    T=0;
    Event_List=zeros(3,Nodes+1);
    Event_List(1,1:Nodes)=1; % Arrival Event
    Event_List(2,1:Nodes)=0;
    Event_List(3,1:Nodes)=1:Nodes;
    Event_List(1,end+1)=10; % Simulation End Event
    Event_List(2,end)=Sim_Timeslots;
    Event_List(1,end+1)=2; % Appoint channels Event
    Event_List(2,end)=0;

    Q1=zeros(Nodes,Queue_Size); % keeps the time
    Q2=zeros(Nodes,Queue_Size); % keeps the channel
    drop_packets=0;
    total_packets=0;
    sum_Q_time=0;
    
    packets_left_Q=0;
    
	[timeslots]= Make_table(Channels,Nodes);
	current_timeslot=1;

    while flag
        event=Event_List(1,1);
        if event==1

            [T,Event_List,Q1,Q2,total_packets,drop_packets]=Event1(T,Event_List,Lambda,Q1,Q2,total_packets,drop_packets,Queue_Size,Channels);

        elseif event==2

            [T,Event_List,flag,Q1,Q2,sum_Q_time,packets_left_Q,current_timeslot]=Event2(T,flag,Event_List,Channels,Queue_Size,Q1,Q2,Nodes,sum_Q_time,packets_left_Q,timeslots,current_timeslot);

        elseif event==3

            % Add Event3 here if needed.

        elseif event==10

            [T,flag]=Event10(T,flag,Event_List);

        end

        Event_List(:,1)=[];
        Event_List=(sortrows(Event_List',[2,1]))';
        
    end
    
    Average_wait_Q= sum_Q_time/packets_left_Q;
    Throughput= packets_left_Q*B / Sim_Timeslots;
    Drop_Rate= drop_packets / total_packets;
    
end

function [T,Event_List,Q1,Q2,total_packets,drop_packets]=Event1(T,Event_List,Lambda,Q1,Q2,total_packets,drop_packets,Queue_Size,Channels)

    T=Event_List(2,1);

    total_packets=total_packets+1;

    counter=1;

    drop_flag=true;

    while(counter<=Queue_Size)
        if Q1(Event_List(3,1),counter)==0
            Q1(Event_List(3,1),counter)=T;

            recievers_channel=randi(Channels);
            Q2(Event_List(3,1),counter)=recievers_channel;

            drop_flag=false;
            break;
        end
        counter=counter+1;
    end

    if drop_flag==true
        drop_packets=drop_packets+1;
    end

    Event_List(1,end+1)=1;
    Event_List(2,end)=T+exprnd(1/Lambda);
    Event_List(3,end)=Event_List(3,1);
    
end

function [T,Event_List,flag,Q1,Q2,sum_Q_time,packets_left_Q,current_timeslot]=Event2(T,flag,Event_List,Channels,Queue_Size,Q1,Q2,Nodes,sum_Q_time,packets_left_Q,timeslots,current_timeslot)
	
	T=Event_List(2,1);
	
	for available_channel = 1:Channels
		transmiting_node = timeslots(available_channel,current_timeslot);
		
		if available_channel == Q2(transmiting_node,1)
			sum_Q_time=sum_Q_time+ T-Q1(transmiting_node,1);     % T-Q1(this_node,1) is the time the packet we are about to remove had stay in the buffer
			packets_left_Q=packets_left_Q+1;                     % We sum the times up for now and we divide them with the number of packets that left the buffer
			for j=2:Queue_Size                                   % before termination. 
				% Remove the oldest packet from the buffers of each node with a channel
				% we basically just shift left that buffer by 1 and cover the last possition
				% with a zero
				Q1(transmiting_node,j-1)=Q1(transmiting_node,j);
				Q2(transmiting_node,j-1)=Q2(transmiting_node,j);
			end
			Q1(transmiting_node,end)=0;
			Q2(transmiting_node,end)=0;   
		end
	end
	
    Event_List(1,end+1)=2;
    Event_List(2,end)=T+1;
	
	if current_timeslot < Nodes
		current_timeslot = current_timeslot+1;
	else
		current_timeslot = 1;
	end

end

function [T,flag]=Event10(T,flag,Event_List)

    T=Event_List(2,1);
    flag=false;
    disp('Simulation End')

end


function [timeslots]= Make_table(Channels,Nodes)
	timeslots = zeros(Channels,Nodes);
	temp_table = [1:Nodes];
	temp_first_slot=0;
	
	for i=1:Nodes
		timeslots(:,i)= temp_table(1:Channels);
		
		temp_first_slot = temp_table(1);
		for j=1:Nodes-1
			temp_table(j) = temp_table(j+1);
		end
		temp_table(end) = temp_first_slot;
	end
	
end