function [ Path, Connectivity_Ratio ] = Nomadic( Grid_Height, Grid_Width, Pace, Moving_Pattern, Networks, Users, Sim_Time )
Sim_Flag=true;
Time=0;

Connectivity_Ratio = 0;

Path=zeros(0,2);

Event_List=zeros(2,2);
Event_List(1,1)=1;
Event_List(2,1)=0;
Event_List(1,2)=10;
Event_List(2,2)=sim_time;

Grid=zeros(Grid_Height, Grid_Width);
Grid_Connectivity=zeros(Grid_Height, Grid_Width);

Grid(ceil(Grid_Width/2),ceil(Grid_Height/2))=1;
Path(end+1,1)=ceil(Grid_Width/2);
Path(end,2)=ceil(Grid_Height/2);

while Sim_Flag
    Event=Event_List(1,1);
    if Event==1
        [Time,Event_List]=Event1(Time,Event_List);
        
    % other events
        
    elseif event==10
        
        [Time,Sim_Flag]=Event10(Time,Sim_Flag,Event_List);
        
    end
    
    Event_List(:,1)=[];
    Event_List=(sortrows(Event_List',2))';
    
end

end

function [Time,Event_List]=Event1(Time,Event_List)

Time=Event_List(2,1);

%Place your code here

Event_List(1,end+1)=1;
Event_List(2,end)=Time+1;
    
end

function [Time,Sim_Flag]=Event10(Time,Sim_Flag,Event_List)

Time=Event_List(2,1);
Sim_Flag=false;
disp('Simulation End')

end
