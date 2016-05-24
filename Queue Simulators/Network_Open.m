function [] = Network_Open()
	
	% Since P was not defined in the exercise, 
	%  we will use it as a NxN matrix with N the number of systems in the network.
	%  Each row represents the routing table for each system with probabilities ranging from 0 to 1.
	%  The clients always enter in the first system and exit the network when they are not routed 
	%  to any other system.
	P = [0, 1, 0; 0, 0, 1; 0, 0, 0];
	
	% simulate for clients generation rate from 1 to 10
	K=[1:10];
	for i=1:10
		[ N1(i), N2(i), N3(i), T1(i), T2(i), T3(i) ] = Network_3_MM1_Open_Routing( i, 4, 1, 4, P, 100 );
	end
	
	% display results for System 1
	figure();
	subplot(2,1,1)
	plot(K,N1);
	title('System 1 Clients');
	xlabel('Client birth rate');
	ylabel('Mean clients on system');
	subplot(2,1,2)
	plot(K,T1);
	title('System 1 Delay');
	xlabel('Client birth rate');
	ylabel('Mean delay on system');
	
	% display results for System 2
	figure();
	subplot(2,1,1)
	plot(K,N2);
	title('System 2 Clients');
	xlabel('Client birth rate');
	ylabel('Mean clients on system');
	subplot(2,1,2)
	plot(K,T2);
	title('System 2 Delay');
	xlabel('Client birth rate');
	ylabel('Mean delay on system');
	
	% display results for System 3
	figure();
	subplot(2,1,1)
	plot(K,N3);
	title('System 3 Clients');
	xlabel('Client birth rate');
	ylabel('Mean clients on system');
	subplot(2,1,2)
	plot(K,T3);
	title('System 3 Delay');
	xlabel('Client birth rate');
	ylabel('Mean delay on system');
	
end