function [ Throughput ] = Slotted_ALOHA( Sim_Time, Random_Timeslots, Stations, Timeslot_Length, Lambda)
	% initialize flags, events and counters
    flag=true;
    T=0;
    Event_List=zeros(3,Stations+1);
    Event_List(1,1:Stations)=1;
    Event_List(1,Stations+1)=4;
    Event_List(2,1:Stations)=0;
    Event_List(2,Stations+1)=Sim_Time;
    Event_List(3,[1:Stations])=[1:Stations];

    Throughput=0;
    generated_packets=0;
    Succesful_Transmissions=0;
    carrier=0;
    Station_State=zeros(1,Stations);

    while flag
        event=Event_List(1,1);
        if event==1

            [T,Event_List,generated_packets]=Event1(T,Event_List,Lambda,generated_packets);

        elseif event==2

            [T,Event_List,Station_State,carrier]=Event2(T,Event_List,Station_State,carrier,Stations,Timeslot_Length);

        elseif event==3

            [T,Event_List,Station_State,carrier,Succesful_Transmissions]=Event3(T,Event_List,Random_Timeslots,Timeslot_Length,Station_State,carrier,Stations,Succesful_Transmissions);

        elseif event==4

            [T,flag,Throughput]=Event4(T,flag,Event_List,Sim_Time,Throughput,Succesful_Transmissions,generated_packets);

        end
        Event_List(:,1)=[];
        Event_List=(sortrows(Event_List',[2,1]))';

    end

end

% Generate packet event
function [T,Event_List,generated_packets]=Event1(T,Event_List,Lambda,generated_packets)
    T=Event_List(2,1);
	% call event2 after random exponential time based on Lamba 
    Event_List(1,end+1)=2;
    Event_List(2,end)=T+exprnd(1/Lambda,1);
    Event_List(3,end)=Event_List(3,1);
	
	% messages for packet generation
    %disp(['Packet generated at : ',num2str(T),' sec'])
    %disp(['for node : ',num2str(Event_List(3,1))])
	%disp(' ')
	
	% count generated packets
    generated_packets=generated_packets+1;  
end

% Send packet event
function [T,Event_List,Station_State,carrier]=Event2(T,Event_List,Station_State,carrier,Stations,Timeslot_Length)
	T=Event_List(2,1);
	% messages for packet arrival
    %disp(['Packet arrival at : ',num2str(T),' sec'])
    %disp(['for node : ',num2str(Event_List(3,1))])
	
	% redirect packet to the next timeslot 
	time_till_new_timeslot = Timeslot_Length-mod(T,Timeslot_Length);
	if time_till_new_timeslot==Timeslot_Length
	
		Station_State(Event_List(3,1))=1;
        %disp('Packet send')
		
		if carrier==0
		% packet send
			carrier=1;
        else
		% packet collided
			for counter_stations=1:Stations
				if Station_State(counter_stations)==1
				% update the status of any other station involved in the collision
					Station_State(counter_stations)=2;
				end
			end
		end
		% call the event3 at the end of the timeslot
		Event_List(1,end+1)=3;
		Event_List(2,end)=T+Timeslot_Length;
		Event_List(3,end)=Event_List(3,1);   
		
    else
	
        %disp(['Packet redirected at : ',num2str(T+time_till_new_timeslot),' sec'])
        Event_List(1,end+1)=2;
        Event_List(2,end)=T+time_till_new_timeslot;
        Event_List(3,end)=Event_List(3,1);
		
    end
     %disp(' ')
end

% Transmission ending event
function [T,Event_List,Station_State,carrier,Succesful_Transmissions]=Event3(T,Event_List,Random_Timeslots,Timeslot_Length,Station_State,carrier,Stations,Succesful_Transmissions)
	T=Event_List(2,1);
    % messages for transmission ending
    %disp(['Packet transmission finished at : ',num2str(T),' sec'])  
    %disp(['for node : ',num2str(Event_List(3,1))])
     
	if Station_State(Event_List(3,1))==2   
		% unsuccesful transmission, call event2 again after random timeslots
        %disp('Packet collided')
        Event_List(1,end+1)=2;
        Event_List(2,end)=T+Timeslot_Length*round(rand()*10*Random_Timeslots); % the guidlines weren't too clear on how to use the Random_Timeslots,
        %Event_List(2,end)=T+Timeslot_Length*Random_Timeslots;                 % the way I left uncommented seems to make more sense
        Event_List(3,end)=Event_List(3,1);
		
	elseif Station_State(Event_List(3,1))==1
		% succesful transmission, call event1 to generate a new packet
        %disp('Packet sent successfuly')
		Event_List(1,end+1)=1;
		Event_List(2,end)=T;
		Event_List(3,end)=Event_List(3,1);
		Succesful_Transmissions=Succesful_Transmissions+1;      %count the succeful transmissions
        
	end
    % if no one else is transmitting, free the carrier
	Station_State(Event_List(3,1))=0;
	carrier=0;
	for counter_stations=1:Stations
        if Station_State(counter_stations)==1 || Station_State(counter_stations)==2
			carrier=1;
			break;
        end
	end
    %disp(' ')
end

% Ending event and results caltulation
function [T,flag,Throughput]=Event4(T,flag,Event_List,Sim_Time,Throughput,Succesful_Transmissions,generated_packets)

    T=Event_List(2,1);
	
	% calculate the Throughput
    Throughput=Succesful_Transmissions/generated_packets;
	
	% display results
    %disp(['Generated packets : ',num2str(generated_packets)])
    %disp(['Succesful transmissions : ',num2str(Succesful_Transmissions)])
    %disp(['Packets per sec : ',num2str(Throughput)])

	% end simulation
    flag=false;
    %disp('Simulation End')

end
