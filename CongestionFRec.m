function [ ] = CongestionFRec( Sim_Time, Threshold, Min_Ack_Time, Max_Ack_Time, Time_Out, Drop_Probability)
format longG;
Sim_Flag=true;
Time=0;
successful_ack=0;
Event_List=zeros(3,2);
Event_List(1,1) = 1;
Event_List(2,1) = 0;
Event_List(1,2) = 4;
Event_List(2,2) = Sim_Time;

Congestion_Window = 1;
Segment_Sequence_Number = fix( rand()*(20000-10000)+10000 );
generated=0;


while Sim_Flag
    event=Event_List(1,1);
	
    if event==1
        
        Time = Event_List(2,1);
        Segments = zeros(2,Congestion_Window);
        temp = Segment_Sequence_Number + 1;
        for counter=1:Congestion_Window
            Segments(1,counter) = temp;
            Segments(2,counter) = 1; % state = 1 --> to be ACKed
			Segment_Sequence_Number = temp-1;
	    temp = temp + 1;
		generated=generated+1;
        end
        
        if rand() < Drop_Probability
            Event_List(1, end + 1) = 3;
            Event_List(2, end) = Time + Time_Out; % A Time Out will happen
        else
            L = size(Segments);
            for counter=1:L(2)
                Event_List(1, end + 1) = 2; % Each Segment will be ACKed
                Event_List(2, end) = Time + rand()*(Max_Ack_Time - Min_Ack_Time) + Min_Ack_Time;
                Event_List(3, end) = Segments(1,counter);
				%disp('Segment send');   % minima gia apostoli segment
            end
        end
		%disp(' ');
        
    elseif event==2
        Time = Event_List(2,1);
		%disp(['Segment : ',num2str(Event_List(3,1)),' acknowledged']);       % minima gia to ack. tou segment
		successful_ack=successful_ack+1;
        if Event_List(3,1) == Segment_Sequence_Number+1
            Segments(2,1) = 2; % state = 2 --> ACKed
            L = size(Segments);
            for counter=1:L(2)
                if Segments(2,counter) == 2
                    if Congestion_Window <= Threshold
                        Congestion_Window = Congestion_Window + 1;
						%disp('Congestion Window increased (exponential phase) ');  % minima gia ekthetiki auksisi tou parathirou
                        Segments(1, end + 1) = Segments(1, end) + 1;
                        Segments(2, end) = 1;
                        generated=generated+1;
						
                        if rand() < Drop_Probability
                            Event_List(1, end + 1) = 3;
                            Event_List(2, end) = Time + Time_Out; % A Time Out will happen
                        else
                            Event_List(1, end + 1) = 2; % New Segment will be ACKed
                            Event_List(2, end) = Time + rand()*(Max_Ack_Time - Min_Ack_Time) + Min_Ack_Time;
                            Event_List(3, end) = Segments(1,end);
							%disp('Segment send');   % minima gia apostoli segment
                        end
                        
                        Segment_Sequence_Number = Segment_Sequence_Number + 1;
                        Segments(1, end + 1) = Segments(1, end) + 1;
                        Segments(2, end) = 1;
                        generated=generated+1;
						
                        if rand() < Drop_Probability
                            Event_List(1, end + 1) = 3;
                            Event_List(2, end) = Time + Time_Out; % A Time Out will happen
                        else
                            Event_List(1, end + 1) = 2; % New Segment will be ACKed
                            Event_List(2, end) = Time + rand()*(Max_Ack_Time - Min_Ack_Time) + Min_Ack_Time;
                            Event_List(3, end) = Segments(1,end);
							%disp('Segment send');   % minima gia apostoli segment
                        end
                        
                        Segment_Sequence_Number = Segment_Sequence_Number + 1;
                        Segments(:,1) = [];
                    else
                        L = size(Segments);
                        Congestion_Window = Congestion_Window + 1/L(2);
						%disp('Congestion Window increased (linear phase) ');    % minima gia grammiki auksisi tou parathirou
                        Segments(1, end + 1) = Segments(1, end) + 1;
                        Segments(2, end) = 1;
                        generated=generated+1;
						
                        if rand() < Drop_Probability
                            Event_List(1, end + 1) = 3;
                            Event_List(2, end) = Time + Time_Out; % A Time Out will happen
                        else
                            Event_List(1, end + 1) = 2; % New Segment will be ACKed
                            Event_List(2, end) = Time + rand()*(Max_Ack_Time - Min_Ack_Time) + Min_Ack_Time;
                            Event_List(3, end) = Segments(1,end);
							%disp('Segment send');   % minima gia apostoli segment
                        end
                        
                        Segment_Sequence_Number = Segment_Sequence_Number + 1;
                        L = size(Segments);
                        if fix(Congestion_Window) > L(2)
                            Segments(1, end + 1) = Segments(1, end) + 1;
                            Segments(2, end) = 1;
                            generated=generated+1;
							
                            if rand() < Drop_Probability
                                Event_List(1, end + 1) = 3;
                                Event_List(2, end) = Time + Time_Out; % A Time Out will happen
                            else
                                Event_List(1, end + 1) = 2; % New Segment will be ACKed
                                Event_List(2, end) = Time + rand()*(Max_Ack_Time - Min_Ack_Time) + Min_Ack_Time;
                                Event_List(3, end) = Segments(1,end);
								%disp('Segment send');   % minima gia apostoli segment
                            end
                            
                            Segment_Sequence_Number = Segment_Sequence_Number + 1;
                        end
                        Segments(:,1) = [];
                    end
                else
                    break;
                end
            end
        else
            [row,column] = find( Segments == Event_List(3,1) );
            Segments(2, column) = 2;
        end 
		
		%disp(' ');
		
    elseif event==3
        Time = Event_List(2,1);
		
		%disp(['Time Out at : ',num2str(Time),' sec']);   % minima gia to Time Out
        Threshold = fix(Congestion_Window/2);
		if Threshold == 0
			Threshold=1;
		end
		%disp('Threshold changes to half the congestion window');    % minima gia ananeosi tis timis tou threshold se apotixia ack.
        Congestion_Window = Threshold;
		%disp('Congestion Window has been reduced to Threshold value');    % minima gia epanafora tou parathirou stin timi
        Event_List(1, end + 1) = 1;
        Event_List(2, end) = Time;
		%disp(' ');
 
    elseif event==4
        Sim_Flag = false;
		%disp(['Congestion Window : ',num2str(Congestion_Window)]);                                   % Emfanisi tis telikis timis tou parathirou
		%disp(['Threshold : ',num2str(Threshold)]);                                                   % Emfanisi tis telikis timis tou threshold
		disp(['Successfully acknowledged : ',num2str(successful_ack)]);                              % Emfanisi tou arithmou epitixon epiveveoseon
		disp(['Segments drop ratio : ',num2str( 1-(successful_ack/(generated)) )]);   % Emfanisi tou posostou aporipsis segments
        disp('Simulation End');
        
    end

    Event_List(:,1)=[];
    Event_List=(sortrows(Event_List', 2))';
    
end

end





