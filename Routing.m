function [ final_cost,total_updates ] = Routing( cost_matrix,delay_matrix,inter_control_time,display_time,sim_time,random_connection_failure,random_connection_recovery,maximum_failures )
    %[ final_cost,total_updates ] = Routing( cost_matrix,delay_matrix,7,4,70,15,5,4)
    flag=true;
    T=0;
    S=size(cost_matrix);
    routers=S(1);
    Event_List=zeros(4,routers+1);
    Event_List(1,1:routers)=1;
    Event_List(2,1:routers)=0;
    Event_List(3,1:routers)=[1:routers];
    Event_List(1,routers+1)=10;
    Event_List(2,routers+1)=sim_time;
    Event_List(1,routers+2)=9;
    Event_List(2,routers+2)=display_time;
    Event_List(1,routers+3)=4;
    Event_List(3,routers+3)=randi(routers);
    Event_List(2,routers+3)=random_connection_failure;

    final_cost=cost_matrix;
    total_updates=0;
    routers_down=0;
    counter_routers=0;
    routing_complete=zeros(size(cost_matrix));
    
    % Call Init function
    [next_hop, neighbors]= Init(cost_matrix);
    
    while flag
        event=Event_List(1,1);
        
        
        if event==1
            T=Event_List(2,1);
            if final_cost(Event_List(3,1),Event_List(3,1))~=999
                for counter_routers=1:routers
                    if neighbors(Event_List(3,1),counter_routers)==1
                        Event_List(1,end+1)=2;
                        Event_List(2,end)=T+delay_matrix(Event_List(3,1),counter_routers);
                        Event_List(3,end)=Event_List(3,1);
                        Event_List(4,end)=counter_routers;
                    end
                end
                %send again after inter_control_time 
                Event_List(1,end+1)=1;
                Event_List(2,end)=T+inter_control_time;
                Event_List(3,end)=Event_List(3,1);
            end

            
        elseif event==2
            %get any better routes
            T=Event_List(2,1);
            routing_complete(Event_List(3,1),Event_List(4,1))=1;
            for counter_routers=1:routers
                
                cost_for_next=final_cost(Event_List(4,1),counter_routers)+final_cost(Event_List(3,1),Event_List(4,1));
           
                if final_cost(Event_List(4,1),counter_routers)~=0 && final_cost(Event_List(3,1),counter_routers)>cost_for_next
                   final_cost(Event_List(3,1),counter_routers)=cost_for_next; 
                   next_hop(Event_List(3,1),counter_routers)=Event_List(4,1); 
                   total_updates=total_updates+1;
                end
            end
             if neighbors==routing_complete
                 routing_complete=ones(size(cost_matrix));
                 disp('Routing Initialization has been finalized…');
             end

        %other events 
        
        
        elseif event==4    %router dropped connection
            if routers_down<=maximum_failures
                for i=1:routers
                   final_cost(i,Event_List(3,1))=999;
                   if i~=Event_List(3,1)
                        next_hop(i,Event_List(3,1))=999;
                        neighbors(i,Event_List(3,1))=0;
                   end
                end
                Event_List(1,end+1)=5;
                Event_List(2,end)=T+random_connection_recovery;
                Event_List(3,end)=Event_List(3,1);
                routers_down=routers_down+1;
            end
            Event_List(1,end+1)=4;
            Event_List(3,end)=randi(routers);
            Event_List(2,end)=T+random_connection_failure;
            
            
         elseif event==5    %router recovers connection
            final_cost(Event_List(3,1),Event_List(3,1))=0;
            for i=1:routers
               if i~=Event_List(3,1)
                    final_cost(i,Event_List(3,1))=final_cost(Event_List(3,1),i);
                    next_hop(i,Event_List(3,1))=next_hop(Event_List(3,1),i);
                    neighbors(i,Event_List(3,1))=neighbors(Event_List(3,1),i);
               end
            end
            Event_List(1,end+1)=1;
            Event_List(2,end)=T;
            Event_List(3,end)=Event_List(3,1);
            routers_down=routers_down-1;
            
             
        elseif event==9      % display routing tables per display_time time units
            T=Event_List(2,1);
            Event_List(1,end+1)=9;
            Event_List(2,end)=T+display_time;
            disp(['At time : ',num2str(T),' sec the routing table is :'])
            disp(final_cost)
            disp(' ')
           
            
        elseif event==10
            T=Event_List(2,1);            
            flag=false;
            disp('Simulation End')

        end

        Event_List(:,1)=[];
        Event_List=(sortrows(Event_List',[2,1]))';

    end

end


function [next_hop, neighbors]= Init(cost_matrix)
    
    next_hop=zeros(size(cost_matrix));
    neighbors=zeros(size(cost_matrix));
    s=size(cost_matrix);
    
    for i=1:s(1)
        for j=1:s(2)
            if cost_matrix(i,j)>0 && cost_matrix(i,j)<999
                next_hop(i,j)=j;
                neighbors(i,j)=1;
            else
                next_hop(i,j)=cost_matrix(i,j);
                neighbors(i,j)=0;
            end
        end
    end
    
    
end



