function [Throughput, Average_wait_Q, Drop_Rate] = broadcast_select_ios( Sim_Timeslots, Nodes, Channels, Queue_Size, Lambda, B)
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
    
	timeslots = zeros(Channels,Nodes);
	
    while flag
        event=Event_List(1,1);
        if event==1

            [T,Event_List,Q1,Q2,total_packets,drop_packets,timeslots]=Event1(T,Event_List,Lambda,Q1,Q2,total_packets,drop_packets,Queue_Size,Channels,timeslots);

        elseif event==2

            [T,Event_List,flag,Q1,Q2,sum_Q_time,packets_left_Q,timeslots]=Event2(T,flag,Event_List,Channels,Queue_Size,Q1,Q2,Nodes,sum_Q_time,packets_left_Q,timeslots);

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

function [T,Event_List,Q1,Q2,total_packets,drop_packets,timeslots]=Event1(T,Event_List,Lambda,Q1,Q2,total_packets,drop_packets,Queue_Size,Channels,timeslots)

    T=Event_List(2,1);

    total_packets=total_packets+1;

    counter=1;

    drop_flag=true;

    while(counter<=Queue_Size)									%if there is space in the queue
        if Q1(Event_List(3,1),counter)==0						% find the first empty place in the queue and place the packet.
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
	else
		%update table
		[timeslots,Q2] = update_timeslots(timeslots,Q2,Event_List(3,1));
    end
	
	
    Event_List(1,end+1)=1;
    Event_List(2,end)=T+exprnd(1/Lambda);
    Event_List(3,end)=Event_List(3,1);
    
end

function [T,Event_List,flag,Q1,Q2,sum_Q_time,packets_left_Q,timeslots]=Event2(T,flag,Event_List,Channels,Queue_Size,Q1,Q2,Nodes,sum_Q_time,packets_left_Q,timeslots)
	
	T=Event_List(2,1);
	if size(timeslots,2) > 0
		for available_channel = 1:Channels
			transmiting_node = timeslots(available_channel,1);
			if transmiting_node >0
				sum_Q_time=sum_Q_time+ T-Q1(transmiting_node,1);     % T-Q1(this_node,1) is the time the packet we are about to remove had stay in the buffer
				packets_left_Q=packets_left_Q+1;                     % We sum the times up for now and we divide them with the number of packets that left the buffer
				for j=2:Queue_Size                                   % before termination. 
					% Remove the oldest packet from the buffers of each node with a channel
					% we basically just shift left that buffer by 1 and cover the last possition
					% with a zero
					Q1(transmiting_node,j-1)=Q1(transmiting_node,j);
					%Q2(transmiting_node,j-1)=Q2(transmiting_node,j);
				end
				Q1(transmiting_node,end)=0;
				%Q2(transmiting_node,end)=0;   
			end
		end
		
		if length(timeslots) > 0
			timeslots(:,1)=[];
		end
	end
    Event_List(1,end+1)=2;
    Event_List(2,end)=T+1;

end

function [T,flag]=Event10(T,flag,Event_List)

    T=Event_List(2,1);
    flag=false;
    disp('Simulation End')

end


function [timeslots,Q] = update_timeslots(timeslots, Q, node)
	
	for i_queue = 1:size(Q,2)

        desired_channel = Q(node,i_queue);
        if desired_channel > 0
			Q(node,i_queue)=0;
            % assume you wont find any timeslots
            timeslot_found = 0;

            % find an empty timeslot in the channel
            for i=1:size(timeslots,2)
                if timeslot_found == 0
                    if timeslots(desired_channel,i) == 0
                        % if the timeslot is empty, check for other activities of the same transmiter at the same time
                        % assume you wont find any
                        already_transmiting=0;
                        for j=1:size(timeslots,1)
                            if timeslots(j,i) == node
                                already_transmiting=1;
                            end
                        end
                        %  if he isn't transmiting in dif. channel at the same time, point that he found and place, and capture it.
                        if already_transmiting==0
                            timeslot_found=1;
                            timeslots(desired_channel,i) = node;
                        end
                    end
                end
            end

            % if there was not available timeslot, expant the table
            if timeslot_found==0
                timeslots(desired_channel,end+1) = node;
            end
        end
	end
	
end