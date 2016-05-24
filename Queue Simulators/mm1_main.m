function []= mm1_main()
	%init. as matrixes the mean_system_clients and mean_delay_system 
	%so we can use them for multiple simulations and easier ploting later
	mean_system_clients=zeros(1,9);
	mean_delay_system=zeros(1,9);
	
	%run the default simulation, l=2 & m=4
	[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue] = MM1( 2,4 );
	
	%run simulation for m=10 and l=1 to l=9
	for i=1:9
		[mean_system_clients(i), mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue] = MM1( i,10 );
	end
	% and plot the results for mean clients on system
	figure();
	plot(mean_system_clients);
	title('Mean clients on system per Lamda value');
	xlabel('Lamda');
	ylabel('Mean clients on system');
	
	%run simulation for l=1 and m=2 to m=10
	for i=2:10
		[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system(i-1), mean_delay_queue] = MM1( 1,i );
	end
	% and plot the results for mean delay on system
	figure();
	plot([2:10],mean_delay_system);
	title('Mean delay on system per m value');
	xlabel('m');
	ylabel('Mean delay on system');
	
end