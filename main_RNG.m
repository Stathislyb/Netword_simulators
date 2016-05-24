function[] = main_RNG()
% Show the menu
   selection= menu('Select Distribution','RNG','Uniform','Exponential','Normal','Poisson');
% Generate random numbers   
   [numbers]=RNG(1024,186,9,5);
   numbers = sort(numbers);
   if selection == 1 % RGN selected
% Make new figure and give the plot of the random sequence       
        figure;
        plot(numbers);
        title('RNG');
        
    elseif selection == 2  % Uniform distribution selected  
% Ask for the limits        
        a = input('Give the a limit of the uniform distribution : ');
        b = input('Give the b limit of the uniform distribution : ');
% Calculate the distribution and show the results on new figure        
        uniform_number=numbers.*( max(a,b)-min(a,b ) )+ min(a,b);
        figure;
        plot(uniform_number);
        title('Uniform distribution');
        
    elseif selection == 3  % Exponential distribution selected
% Ask for the mean        
        l = input('Give the mean l : ');
% Calculate the distribution and show the results on new figure         
        exponential_number=1 - exp( -l .* numbers );
        figure;
        plot(exponential_number);
        title('Exponential distribution');
        
    elseif selection == 4  % Normal distribution selected
% Ask for the mean and variance, make sure the variance is valid
        m = input('Give the mean m : ');
        s = input('Give the variance s : ');
        while s <= 0
            s = input('Give the s more than zero ');
        end
% Calculate the distribution and show the results on new figure 
        % get the numbers again, unsorted
        [numbers]=RNG(1024,286,9,5);
        
        % This is an other way to make it (instead of the for loop). 
        % The plot was a lot smother too but since the loop seems to be
        % prefered I left it that way.
     %[numbers2]=RNG(1024,106,9,5);
     %normal_number= sign(numbers-0.5).*log(numbers2);
        
        for counter=1:length(numbers)
            rn1=numbers(mod(fix(length(numbers)/2)+counter, length(numbers)) +1);
            rn=numbers(mod(fix(length(numbers)/2)+counter+1, length(numbers)) +1);
            normal_number(counter)=(-2*log(rn1))^0.5*cos(2*pi*rn);
        end
        normal_number= m+ s.*normal_number;
        
        figure;
        plot(sort(normal_number));
        title('Normal distribution');
        
    elseif selection == 5  % Poisson distribution selected
% Ask for the mean and normalise the random matrix for poisson distribution   
        l = input('Give the mean l : ');
% Calculate the distribution and show the results on new figure   
        for counter=1:length(numbers)
            el= exp( -l);
            k=1;
            p=1;
            p= p * numbers(counter);
            while p>el
                k=k+1;
            	p= p * numbers(counter)/l;
            end
            poisson_number(counter)=k-1;
        end  

        figure;
        poisson_number=sort(poisson_number);
        plot(poisson_number);
        title('Poisson distribution');
        
    end
