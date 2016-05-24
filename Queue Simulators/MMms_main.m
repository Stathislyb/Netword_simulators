function []= MMms_main()
	% run and display results for M/M/m case
	[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue,blocking_probability] = MMms( 2,4,2,0 );
	disp('M/M/m (l=2 / M=4 / m=2)');
	disp(['Mean clients on system : ',num2str(mean_system_clients)]);
	disp(['  Mean clients on server : ',num2str(mean_server_clients)]);
	disp(['  Mean clients on queue :',num2str(mean_queue_clients)]);
	disp(' ');
	disp(['Mean delay on system : ',num2str(mean_delay_system)]);
	disp(['  Mean delay on queue :',num2str(mean_delay_queue)]);
	disp(' ');
	disp(['Blocking probability : ',num2str(blocking_probability)]);
	
	disp(' ');
	disp('---------------');
	disp(' ');
	% run and display results for M/M/∞ case
	[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue,blocking_probability] = MMms( 2,4,0,0 );
	disp('M/M/inf (l=2 / M=4 / m=inf)');
	disp(['Mean clients on system : ',num2str(mean_system_clients)]);
	disp(['  Mean clients on server : ',num2str(mean_server_clients)]);
	disp(['  Mean clients on queue :',num2str(mean_queue_clients)]);
	disp(' ');
	disp(['Mean delay on system : ',num2str(mean_delay_system)]);
	disp(['  Mean delay on queue :',num2str(mean_delay_queue)]);
	
	disp(' ');
	disp('---------------');
	disp(' ');
	% run and display results for M/M/1/s case
	[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue,blocking_probability] = MMms( 2,4,1,2 );
	disp('M/M/1/s (l=2 / M=4 / m=1 / s=2)');
	disp(['Mean clients on system : ',num2str(mean_system_clients)]);
	disp(['  Mean clients on server : ',num2str(mean_server_clients)]);
	disp(['  Mean clients on queue :',num2str(mean_queue_clients)]);
	disp(' ');
	disp(['Mean delay on system : ',num2str(mean_delay_system)]);
	disp(['  Mean delay on queue :',num2str(mean_delay_queue)]);

	
	disp(' ');
	disp('---------------');
	disp(' ');
	% run and display results for M/M/m/m case
	[mean_system_clients, mean_server_clients, mean_queue_clients, mean_delay_system, mean_delay_queue,blocking_probability] = MMms( 2,4,2,2 );
	disp('M/M/m/m (l=2 / M=4 / m=2)');
	disp(['Mean clients on system : ',num2str(mean_system_clients)]);
	disp(['  Mean clients on server : ',num2str(mean_server_clients)]);
	disp(['  Mean clients on queue :',num2str(mean_queue_clients)]);
	disp(' ');
	disp(['Mean delay on system : ',num2str(mean_delay_system)]);
	disp(['  Mean delay on queue :',num2str(mean_delay_queue)]);
	disp(' ');
	disp(['Blocking probability : ',num2str(blocking_probability)]);
	
end