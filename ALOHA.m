function [ Collision_Count, Succesful_Transmissions, Channel_Utilization, Network_Throughput, Dropped_rate ] = ALOHA( Sim_Time, Stations, lambda, Transmission_Time, Random_Period, Frame_Length_Bytes, Collision_Times)
	%function [] = ALOHA( Sim_Time, Stations, lambda, Transmission_Time, Random_Period, Frame_Length_Bytes, Collision_Times)
    %since I have the outputs printed with messages the above could be
    %better since it now returns at the end 'ans=x' where x is the
    %Collision_Count which also happens to be the first attribute the function
    %returns.
    
    flag=true;
	T=0;
	Event_List=zeros(3,Stations+1);
	Event_List(1,1:Stations)=1;
	Event_List(1,Stations+1)=4;
	Event_List(2,1:Stations)=0;
	Event_List(2,Stations+1)=Sim_Time;
	Event_List(3,[1:Stations])=[1:Stations];
    
	collision_per_station=zeros(1,Stations);
	Collision_Count=0;
    Dropped_Count=0;
    Generated_Count=0;
    Dropped_rate=0;
	Succesful_Transmissions=0;
	Channel_Utilization=0;
	Network_Throughput=0;
	carrier=0;
	Station_State=zeros(1,Stations);
    
	while flag
		event=Event_List(1,1);
		if event==1
			[T,Event_List,Generated_Count]=Event1(T,Event_List,lambda,Generated_Count);
			
		elseif event==2
			
			[T,Event_List,Station_State,carrier]=Event2(T,Event_List,Station_State,carrier,Transmission_Time,Stations);
		
		elseif event==3
			
			[T,Event_List,Station_State,carrier,Succesful_Transmissions,Collision_Count,collision_per_station,Dropped_Count]=Event3(Dropped_Count,Collision_Times,collision_per_station,Collision_Count,Succesful_Transmissions,T,Event_List,Random_Period,Station_State,carrier,Stations);
			
		elseif event==4
			
			[T,flag,Channel_Utilization, Network_Throughput, Dropped_rate]=Event4(T,flag,Generated_Count,Dropped_Count,Transmission_Time,Sim_Time,Event_List,Collision_Count, Succesful_Transmissions, Channel_Utilization, Network_Throughput);
			
        end
		Event_List(:,1)=[];
		Event_List=(sortrows(Event_List',[2,1]))';		
	end
	
end


function [T,Event_List,Generated_Count]=Event1(T,Event_List,lambda,Generated_Count)
	T=Event_List(2,1);
	Event_List(1,end+1)=2;
	Event_List(2,end)=T+exprnd(1/lambda,1,1);
	Event_List(3,end)=Event_List(3,1); 
    Generated_Count=Generated_Count+1;
end


function [T,Event_List,Station_State,carrier]=Event2(T,Event_List,Station_State,carrier,Transmission_Time,Stations)
	T=Event_List(2,1);
    str = ['Transmission begins at Time : ',num2str(T)];
	disp(str);
    str = ['Station trying to transmit : ',num2str(Event_List(3,1))];
	disp(str);                                      %display time and station
	Station_State(Event_List(3,1))=1;
	if carrier==0
        disp('Transmission begins successfully')
		carrier=1;
	else
		%disp('Collision')      % it has been removed since we display the
		%collisions latter with the stations involved in it
		for counter_stations=1:Stations
			if Station_State(counter_stations)==1
				if counter_stations ~=Event_List(3,1)
                    str = ['Collided on : ',num2str(counter_stations)];
                    disp(str);                          %display which station is has collided with
				end
				Station_State(counter_stations)=2;
			end
		end
	end
	Event_List(1,end+1)=3;
	Event_List(2,end)=T+Transmission_Time;
	Event_List(3,end)=Event_List(3,1);   
    disp(' ')
end


function [T,Event_List,Station_State,carrier,Succesful_Transmissions,Collision_Count,collision_per_station,Dropped_Count]=Event3(Dropped_Count,Collision_Times,collision_per_station,Collision_Count,Succesful_Transmissions,T,Event_List,Random_Period,Station_State,carrier,Stations)
	T=Event_List(2,1);
	str = ['Transmission ends at Time : ',num2str(T)];
	disp(str);
    str = ['Station : ',num2str(Event_List(3,1))];
    disp(str);                                          %display time and station
	if Station_State(Event_List(3,1))==2
        
        Collision_Count=Collision_Count+1;                    %count the collisions                          
		collision_per_station(Event_List(3,1))=collision_per_station(Event_List(3,1))+1;
        str = ['Unsuccesful transmissions : ',num2str(collision_per_station(Event_List(3,1)))];
        disp(str);                                   %display the unsucceful transmission of this station
        
        if Collision_Times == collision_per_station(Event_List(3,1))
            Event_List(1,end+1)=1;
            Event_List(2,end)=T;
            Event_List(3,end)=Event_List(3,1);
            collision_per_station(Event_List(3,1)) =0;
            disp('Collision times limit reached, Packet dropped')
            Dropped_Count=Dropped_Count+1;
        else
            Event_List(1,end+1)=2;
            Event_List(2,end)=T+rand()*Random_Period;
            Event_List(3,end)=Event_List(3,1);
        end
		
	elseif Station_State(Event_List(3,1))==1
		Event_List(1,end+1)=1;
		Event_List(2,end)=T;
		Event_List(3,end)=Event_List(3,1);
		collision_per_station(Event_List(3,1)) =0;
		Succesful_Transmissions=Succesful_Transmissions+1;      %count the succeful transmissions
		disp('Succesful Transmission')
	end
	Station_State(Event_List(3,1))=0;
	carrier=0;
	for counter_stations=1:Stations
		if Station_State(counter_stations)==1 || Station_State(counter_stations)==2
			carrier=1;
			break;
		end
    end
    str = ['Carrier state : ',num2str(carrier)];
    disp(str);                                      %display the state of the carrier
    disp(' ')
end


function [T,flag,Channel_Utilization, Network_Throughput, Dropped_rate]=Event4(T,flag,Generated_Count,Dropped_Count,Transmission_Time,Sim_Time,Event_List,Collision_Count, Succesful_Transmissions, Channel_Utilization, Network_Throughput)
	T=Event_List(2,1);
	flag=false;
	disp('Simulation End')
    disp(' ');
    
    % display the Succesful Transmissions
    str = ['Succesful Transmissions : ',num2str(Succesful_Transmissions)];
    disp(str);
    disp(' ');
    
    % display the Collisions Count
    str = ['Collisions Count : ',num2str(Collision_Count)];
    disp(str);
    disp(' ');
    
    % display the Dropped packets rate
    Dropped_rate=Generated_Count/Dropped_Count;
    str = ['Packets dropped rate : ',num2str(Dropped_rate)];
    disp(str);
    disp(' ');
    
    % calculate and display Channel Utilization as succefully sent / maximum that could be sent
	Channel_Utilization=Succesful_Transmissions / floor(Sim_Time/Transmission_Time);
    str = ['Channel Utilization : ',num2str(Channel_Utilization)];
    disp(str);
    disp(' ');
    
	% calculate and display Network Throughput in packets per second
	Network_Throughput=Succesful_Transmissions / Sim_Time;
    str = ['Network Throughput (packets per second) : ',num2str(Network_Throughput)];
    disp(str);
    disp(' ');
end
